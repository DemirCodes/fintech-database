# Fintech Database Fonksiyonları ve Trigger Listesi (Rev. 2)

Bu doküman, `fintech-db-proje.md` mimarisine uygun olarak geliştirilmesi gereken tüm SQL fonksiyonlarını (PL/pgSQL) ve tetikleyicileri (Triggers) kapsar. Teknik düzeltmeler ve mimari kararlar dikkate alınarak revize edilmiştir.

---

## Modül 1-2: Tenant & Müşteri Yönetimi

| Fonksiyon | İlgili Tablo(lar) | Amaç & Teknik Detay |
|---|---|---|
| `fn_create_tenant(p_name, p_subdomain)` | `tenants`, `tenant_balances` | Yeni firma oluşturur. Her desteklenen para birimi (TRY, USD, EUR vb.) için `tenant_balances` tablosuna başlangıç bakiyesi (0.00) ile satır açar. Atomik işlem gerektirir. |
| `fn_generate_api_key()` | `tenants` | Benzersiz API anahtarı üretir. `UNIQUE` constraint ihlali durumunda (nadir de olsa) retry mekanizması içeren bir wrapper olarak tasarlanmalıdır. `pgcrypto` veya `gen_random_uuid()` kullanılır. |
| `fn_create_customer_wallet(p_tenant_id, p_customer_id, p_currency)` | `customer_wallets` | Müşteri için belirli bir para biriminde cüzdan oluşturur. `UNIQUE (tenant_id, customer_id, currency)` kısıtına dikkat edilir. |
| `fn_validate_session(p_session_id, p_user_id, p_ip, p_ua)` | `user_sessions`, `users` | Oturum doğrulama. `expires_at` kontrolü yapar. IP/User-Agent değişimi için **risk skorlama** mantığı içerir (Katı logout yerine loglama/ek doğrulama). |

---

## Modül 3: İşlem Motoru (Kritik Modül)

| Fonksiyon/Trigger | İlgili Tablo(lar) | Amaç & Teknik Detay |
|---|---|---|
| `fn_check_idempotency(p_tenant_id, p_key)` | `transactions` | Aynı `idempotency_key` ile daha önce işlenmiş bir işlem var mı diye kontrol eder. Varsa mevcut sonucu döndürür. **Bu bir optimizasyondur, gerçek garanti değil — bkz. Not 9.** |
| `fn_create_transaction(p_data)` | `transactions`, `transaction_details` | Yeni işlem kaydını `PENDING` statüsünde oluşturur. Detay bilgilerini `transaction_details` tablosuna yazar. `unique_violation` exception'ını yakalayıp mevcut kaydı döndürmelidir (bkz. Not 9). |
| **`trg_validate_status`** (Trigger) | `transactions` | **ÖNEMLİ:** Status geçiş kurallarını zorlar. `CHECK` constraint ile yapılamaz çünkü `OLD` değerine erişim gerekir. `BEFORE UPDATE` trigger'ı ile `OLD.status` ve `NEW.status` karşılaştırması yapılır (Örn: COMPLETED -> PENDING yasak). |
| `fn_lock_wallet_for_update(p_wallet_id)` | `customer_wallets` | `SELECT ... FOR UPDATE` ile satır kilidi alır. Transfer öncesi veri tutarlılığı için kritiktir. |
| `fn_insert_ledger_entry(p_wallet_id, p_type, p_amount, p_desc)` | `wallet_ledger` | Append-only ledger'a hareket kaydı ekler. Bu, bakiye değişiminin **TEK** yoludur. |
| **`trg_sync_wallet_balance`** (Trigger) | `wallet_ledger` -> `customer_wallets` | **ÖNEMLİ:** `wallet_ledger`'a INSERT sonrası tetiklenir. `customer_wallets.balance` değerini otomatik olarak günceller. Fonksiyon olarak değil, trigger olarak çalışmalıdır. |
| `fn_process_transfer(p_sender_wallet, p_receiver_wallet, p_amount)` | `transfers`, `customer_wallets`, `wallet_ledger` | İki cüzdan arası transferi orkestralar. 1. Lock al. 2. Gönderen Ledger yaz. 3. Alıcı Ledger yaz. 4. `trg_sync_wallet_balance` tetikleyicileri bakiyeleri günceller. 5. Transfer kaydı oluştur. |
| `fn_process_refund(p_transaction_id, p_amount, p_reason)` | `refunds`, `transactions`, `wallet_ledger` | İade işlemini başlatır. Orijinal transaction ID'sine bağlar. Bakiye hareketini ledger'a kaydeder. |
| `fn_recalculate_wallet_balance(p_wallet_id)` | `wallet_ledger`, `customer_wallets` | `SELECT SUM(amount)` ile ledger'dan bakiyeyi sıfırdan hesaplar. **Performans açısından ağır.** Sadece `reconciliation` veya hata durumunda manuel/cron ile çalıştırılmalıdır. |
| `fn_block_wallet_amount(p_wallet_id, p_amount)` | `customer_wallets` | `blocked_amount`'u artırır. `blocked_amount + new_blocked <= balance` kontrolü yapar. |
| `fn_unblock_wallet_amount(p_wallet_id, p_amount)` | `customer_wallets` | `blocked_amount`'u azaltır. |

---

## Modül 4: Komisyon Yönetimi

| Fonksiyon | İlgili Tablo(lar) | Amaç & Teknik Detay |
|---|---|---|
| `fn_get_commission_rate(p_tenant_id, p_txn_type, p_txn_date)` | `commission_rates` | **Tarihsel Oran Sorgusu:** `effective_from <= p_txn_date` VE (`effective_to IS NULL OR effective_to > p_txn_date`) koşuluna uyan oranı döndürür. Sınır anındaki çakışma için bkz. Not 10. Sadece "en güncel" oranı değil, işlemin gerçekleştiği tarihteki oranı verir. |
| `fn_calculate_commission(p_amount, p_rate_data)` | `commissions` | Hesaplanan komisyon tutarını (`percentage` ve `fixed_fee`'ye göre) hesaplar ve `commissions` tablosuna kaydetmeye hazır veri yapısı döndürür. |
| `fn_apply_commission_to_ledger(p_commission_id, p_tenant_id)` | `commissions`, `wallet_ledger`, `tenant_balances` | Hesaplanan komisyonu ilgili tenant'ın bakiyesinden düşer (veya komisyon alınacaksa ekler). Ledger kaydı oluşturur. |

---

## Modül 5: Chargeback (İtiraz) Yönetimi

| Fonksiyon/Trigger | İlgili Tablo(lar) | Amaç & Teknik Detay |
|---|---|---|
| `fn_create_chargeback(p_txn_id, p_amount, p_reason)` | `chargebacks`, `transactions` | Yeni itiraz kaydı oluşturur. İlgili transaction'ı "dispute" durumunda işaretleyebilir. |
| **`trg_chargeback_status_history`** (Trigger) | `chargebacks` -> `chargeback_status_history` | Chargeback durumu değiştiğinde (`UPDATE`), eski ve yeni durumu `chargeback_status_history` tablosuna loglar. |
| `fn_resolve_chargeback(p_chargeback_id, p_result)` | `chargebacks`, `wallet_ledger`, `customer_wallets` | İtiraz sonucuna göre işlem yapar (Kazandı: Bakiye iade, Kaybetti: Bakiye kesinti). Ledger kayıtları oluşturur. |

---

## Modül 6: Taksit Yönetimi

| Fonksiyon | İlgili Tablo(lar) | Amaç & Teknik Detay |
|---|---|---|
| `fn_create_installment_plan(p_txn_id, p_count, p_freq)` | `installment_plans`, `installment_payments` | Taksit planı oluşturur ve `installment_payments` tablosuna N adet taksit satırını (hesaplanmış tarih ve tutarlarla) otomatik yazar. |
| `fn_process_installment_payment(p_plan_id, p_amount)` | `installment_payments`, `wallet_ledger` | Tek bir taksit ödemesini işler. Ödeme durumu `PAID` yapar, ilgili ledger kaydını oluşturur. |
| `fn_get_overdue_installments(p_date)` | `installment_payments` | `due_date < p_date` ve `status = 'PENDING'` olan taksitleri bulur. (Index kullanır). |

---

## Modül 7: Kur Yönetimi

| Fonksiyon | İlgili Tablo(lar) | Amaç & Teknik Detay |
|---|---|---|
| **`trg_update_currency_rate_history`** (Trigger) | `currency_rates` -> `currency_rate_history` | `currency_rates` tablosunda güncelleme olduğunda, eski değeri `currency_rate_history` tablosuna taşır. |
| `fn_convert_currency(p_amount, p_from, p_to)` | `currency_rates` | Güncel kuru kullanarak dönüşüm yapar. |
| `fn_get_rate_at_date(p_from, p_to, p_date)` | `currency_rate_history` | Geçmiş bir tarihteki kuru bulur: `base_currency=p_from`, `target_currency=p_to`, `recorded_at <= p_date` koşuluyla en son kaydı döndürür. |

---

## Modül 8: Mutabakat (Reconciliation)

| Fonksiyon | İlgili Tablo(lar) | Amaç & Teknik Detay |
|---|---|---|
| `fn_create_reconciliation_batch(p_tenant_id, p_date)` | `reconciliation_batches` | Günlük kapanış batch'i oluşturur. |
| `fn_generate_reconciliation_items(p_batch_id)` | `reconciliation_items`, `transactions`, `wallet_ledger` | Banka dış referanslarını içeren veriyi (dışarıdan gelen) sistemle karşılaştırır. Beklenen vs. gerçekleşen kalemleri `reconciliation_items` tablosuna yazar. |
| `fn_flag_mismatches(p_batch_id)` | `reconciliation_items` | `expected_amount != actual_amount` olan kalemleri `MISMATCHED` olarak işaretler. |
| `fn_close_reconciliation_batch(p_batch_id)` | `reconciliation_batches` | Batch'i `CLOSED` yapar, özet istatistikleri günceller. |

---

## Modül 9: Audit & CDC (Outbox Pattern)

| Fonksiyon/Trigger | İlgili Tablo(lar) | Amaç & Teknik Detay |
|---|---|---|
| **`trg_generic_audit`** (Trigger) | Tüm Ana Tablolar -> `audit_logs` | Her INSERT/UPDATE/DELETE için `old_data` ve `new_data` JSONB olarak `audit_logs` tablosuna yazar. Generic bir trigger fonksiyonu tüm tablolara atanır. |
| `fn_write_outbox_event(p_aggregate_type, p_aggregate_id, p_event_type, p_payload)` | `outbox` | İş mantığı tamamlandığında (örn: işlem başarılı), event'i `outbox` tablosuna yazar. **ÖNEMLİ:** Bu yazım, ana işlemin transaction'ı ile aynı transaction içinde olmalıdır (Atomiklik). |
| `fn_get_pending_outbox_events(p_limit)` | `outbox` | `status = 'PENDING'` olan event'leri çeker. Partial index (`idx_outbox_pending`) kullanır. |
| `fn_mark_outbox_processed(p_event_id, p_consumer_name, p_status)` | `outbox`, `event_logs` | Event işlendiğinde `outbox` statusunu `PUBLISHED` yapar ve `event_logs` tablosuna işleme sonucunu yazar. |
| `fn_cleanup_old_outbox(p_days)` | `outbox` | `published_at < (now() - interval 'X days')` olan event'leri siler (veya arşivler). |

---

## Genel Yardımcı Fonksiyonlar & Altyapı

| Fonksiyon | İlgili Tablo(lar) | Amaç & Teknik Detay |
|---|---|---|
| `fn_soft_delete(p_table_name, p_id)` | Tüm Ana Tablolar (Generic) | Hard delete yerine `status = 'DELETED'` veya `is_active = false` güncellemesi yapar. |
| `fn_create_monthly_partition(p_table_name, p_date)` | `transactions`, `wallet_ledger` vs. | Aylık partition oluşturma. **Üretim ortamı için `pg_partman` kütüphanesi önerilir.** Bu fonksiyon öğrenme/özel ihtiyaç için yazılır. |
| `fn_archive_old_partitions(p_table_name, p_months)` | `transactions`, `wallet_ledger` vs. | Eski partition'ları arşivleme (dump/restore veya detach/attach). |

---

## Notlar ve Uyarılar

1.  **Status Geçişleri:** `transactions` tablosunda status geçişleri için `CHECK` constraint yetersizdir. Mutlaka `BEFORE UPDATE` trigger'ı (`trg_validate_status`) kullanılmalıdır.
2.  **Bakiye Senkronizasyonu:** `customer_wallets.balance` alanı cache amaçlıdır. Tek kaynak (`source of truth`) `wallet_ledger` tablosudur. Bakiye güncellemesi `trg_sync_wallet_balance` trigger'ı ile otomatik yapılır. Fonksiyon olarak manuel çağrılması önerilmez.
3.  **Komisyon Tarihçesi:** `fn_get_commission_rate` fonksiyonu, işlem tarihine göre (`effective_from/to`) komisyon oranını bulmalıdır. Sadece "en güncel" oranı almak geçmiş raporlamalarda hatalı sonuç verir.
4.  **API Key Güvenliği:** `fn_generate_api_key` fonksiyonu `UNIQUE` constraint ihlali durumunda hata verebilir. Uygulama katmanında retry mekanizması bulunmalıdır veya fonksiyon içinde `EXCEPTION` bloğu ile retry yapılmalıdır.
5.  **Session Güvenliği:** `fn_validate_session` fonksiyonunda IP/User-Agent kontrolü "katı eşleşme" değil, "risk skoru" mantığıyla yapılmalıdır. Mobil/NAT kullanıcıları için false-positive (yanlış pozitif) önlenmelidir.
6.  **Blokeli Bakiye:** `fn_block_wallet_amount` fonksiyonu sadece `customer_wallets.blocked_amount`'u günceller. `tenant_balances.available_balance`'u sadece chargeback/fraud gibi özel durumlarda güncellenmelidir. Müşteri kendi bakiyesini blokladığında tenant bakiyesi değişmez.
7.  **Rekalkülasyon:** `fn_recalculate_wallet_balance` fonksiyonu `SUM` işlemi yaptığı için ağır bir iştir. Normal akışta kullanılmaz, sadece veri tutarlılığı kontrolü (audit) için manuel veya cron ile çalıştırılmalıdır.
8.  **Partitioning:** `pg_partman` kullanımı production ortamları için standarttır. Elle partition yönetimi hataya açıktır.
9.  **Idempotency Race Condition:** `fn_check_idempotency`, aynı `idempotency_key` ile gelen iki eş zamanlı isteği tek başına engelleyemez — ikisi de kontrolü "kayıt yok" olarak geçebilir ve ikisi de INSERT denemesi yapabilir. Gerçek garanti `UNIQUE (tenant_id, idempotency_key)` constraint'inden gelir. Bu yüzden `fn_create_transaction()` içinde INSERT bir `EXCEPTION WHEN unique_violation` bloğuyla sarılmalı; çakışma durumunda mevcut kayıt çekilip onun sonucu döndürülmelidir. `fn_check_idempotency` yalnızca gereksiz işi erken durdurmak için bir optimizasyondur, tek başına yeterli değildir.
10. **Effective Date Sınır Çakışması:** `fn_get_commission_rate` içinde `effective_to >= p_txn_date` (inclusive) kullanılırsa, bir oranın bittiği an ile bir sonrakinin başladığı an aynıysa (yaygın pratik budur), o sınır anında iki satır da eşleşebilir. Doğrusu `effective_to > p_txn_date` (strict) kullanmak, ya da tasarım aşamasında `effective_from`/`effective_to` aralıklarının hiçbir noktada çakışmadığından emin olmaktır (ör. bir `EXCLUDE` constraint ile).

---

## Henüz Kapsanmayan (Ayrı Doküman Gerektirir)

- **RLS Policy'leri ve sahiplik kontrolü:** Multi-tenant izolasyonu ve IDOR koruması için `ENABLE ROW LEVEL SECURITY` + `CREATE POLICY` tanımları, ve `fn_process_transfer` / `fn_process_refund` / `fn_resolve_chargeback` gibi fonksiyonların içinde cross-entity sahiplik doğrulaması. Bu liste tamamlanmadan Faz 2 güvenlik açısından eksik sayılmalıdır.