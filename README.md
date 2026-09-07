# 🏦 Fintech & Ödeme Sistemi Veritabanı Projesi

## 📌 Proje Tanımı

Bu proje, multi-tenant bir fintech/ödeme sistemi veritabanı tasarımıdır. Amaç, gerçek dünyada bir ödeme kuruluşunun (Stripe, iyzico, PayTR) kullanacağı seviyede, production-grade bir database mimarisi kurmaktır.

**Kapsam:**
- Multi-tenant SaaS yapısı
- Müşteri ve cüzdan yönetimi
- Para transferleri, ödemeler, iadeler
- Komisyon motoru
- Chargeback (itiraz) süreci
- Taksitlendirme
- Çoklu para birimi desteği
- Mutabakat (reconciliation)
- Audit trail ve CDC (Change Data Capture)

---

## 🎯 Hedeflenen Database Engineer & Fintek Mimari Seviyesi

Bu proje, aşağıdaki konuları **pratikte uygulayarak** öğrenmek için tasarlanmıştır:

| Konu | Durum |
|------|-------|
| Schema Design & Normalization | ✅ Uygulanacak |
| Concurrency Control (Optimistic/Pessimistic Locking) | ✅ Uygulanacak |
| **Sorgu Planlama ve Optimizasyon (EXPLAIN ANALYZE)** | ✅ Uygulanacak |
| **İleri Düzey Index Stratejileri (B-Tree, Hash, GIN, GiST, BRIN)** | ✅ Uygulanacak |
| **Partitioning ve Sharding Stratejileri** | ✅ Uygulanacak |
| **JOIN Stratejileri (Nested Loop, Hash Join, Merge Join)** | ✅ Uygulanacak |
| **Caching ve Önbellek Stratejileri (Query cache, Redis, Materialized Views)** | ✅ Uygulanacak |
| **Veritabanı İzleme ve Bakım (Vacuum, pg_stat_statements, Log Analizi)** | ✅ Uygulanacak |
| Stored Procedures & Triggers | ✅ Uygulanacak |
| Audit Trail & CDC | ✅ Uygulanacak |
| Outbox Pattern | ✅ Uygulanacak |
| Ledger Pattern (Append-Only) | ✅ Uygulanacak |
| Multi-Tenancy (Row-Based) | ✅ Uygulanacak |
| Migration Stratejisi (Flyway) | ✅ Uygulanacak |

---

## 🏗️ Mimari Kararlar

### 1. Multi-Tenancy Yaklaşımı
**Seçim:** Row-Based Tenancy

Her tabloda `tenant_id` kolonu bulunur. Tüm tenant'lar aynı tabloları paylaşır, veriler `tenant_id` ile izole edilir.

**Neden?**
- Gerçek dünyada en yaygın kullanım (%80+)
- Yönetimi kolay, tek migration herkese uygulanır
- Partitioning ve index optimizasyonu tek yerde yapılır

### 2. Ledger Pattern (Source of Truth)
**Kural:** `wallet_ledger` tablosu gerçek kaynaktır. `customer_wallets.balance` sadece türetilmiş bir cache değerdir.

**Uygulama:**
- Bakiye değişimleri sadece `wallet_ledger`'a INSERT ile olur
- Trigger, ledger insert'inden sonra cache bakiyeyi otomatik günceller
- Uygulama katmanı asla `balance`'ı direkt güncelleyemez

### 3. Concurrency Control
**Seçim:** Optimistic Locking (version kolonu) + Pessimistic Locking (SELECT FOR UPDATE)

- `customer_wallets` ve `tenant_balances` tablolarında `version` kolonu var
- Transfer işlemlerinde `SELECT ... FOR UPDATE` ile satır kilidi alınır
- Idempotency key ile tekrar eden istekler engellenir

### 4. Partitioning Stratejisi
Büyüyen tablolar için **aylık RANGE partitioning** uygulanacak:

| Tablo | Partition Aralığı | Arşiv Politikası |
|-------|-------------------|------------------|
| `transactions` | Aylık | 24 ay sonra arşivle |
| `wallet_ledger` | Aylık | 24 ay sonra arşivle |
| `audit_logs` | Aylık | 12 ay sonra arşivle |
| `outbox` | Haftalık | 30 gün sonra temizle |

### 5. Foreign Key Politikası
**Kural:** Finansal veri asla hard delete edilmez.

- Para hareketi içeren tablolar: `ON DELETE RESTRICT`
- Yardımcı tablolar (adres, session): `ON DELETE CASCADE`
- Kullanıcı silinirse audit log'da: `ON DELETE SET NULL`

### 6. Idempotency
**Kural:** `transactions` tablosunda `UNIQUE (tenant_id, idempotency_key)` constraint'i var.

Aynı istek iki kez gelirse ikinci deneme hata alır, double-charge engellenir.

---

## 📊 Tablo Yapısı

### Modül 1: Tenant & Kullanıcı
| Tablo | Açıklama |
|-------|----------|
| `tenants` | Platformu kullanan firmalar |
| `tenant_balances` | Tenant bazlı multi-currency bakiyeler |
| `users` | Tenant'a bağlı çalışanlar |
| `user_sessions` | Kullanıcı oturumları |

### Modül 2: Müşteri
| Tablo | Açıklama |
|-------|----------|
| `customers` | Son kullanıcılar |
| `customer_addresses` | Müşteri adresleri |
| `customer_wallets` | Multi-currency cüzdanlar |
| `payment_methods` | Kayıtlı kartlar/banka hesapları |

### Modül 3: İşlem Motoru
| Tablo | Açıklama |
|-------|----------|
| `transactions` | Ana işlem tablosu |
| `transaction_details` | İşlem detayları |
| `wallet_ledger` | Append-only defter kayıtları |
| `transfers` | Müşteriler arası transfer |
| `refunds` | İade işlemleri |

### Modül 4: Komisyon
| Tablo | Açıklama |
|-------|----------|
| `commission_rates` | Tenant bazlı komisyon oranları |
| `commissions` | Kesilen komisyonlar |

### Modül 5: Chargeback
| Tablo | Açıklama |
|-------|----------|
| `chargebacks` | İtiraz kayıtları |
| `chargeback_status_history` | Durum geçmişi |

### Modül 6: Taksit
| Tablo | Açıklama |
|-------|----------|
| `installment_plans` | Taksit planları |
| `installment_payments` | Taksit ödemeleri |

### Modül 7: Kur Yönetimi
| Tablo | Açıklama |
|-------|----------|
| `currencies` | Para birimleri |
| `currency_rates` | Güncel kurlar |
| `currency_rate_history` | Geçmiş kur değerleri |

### Modül 8: Mutabakat
| Tablo | Açıklama |
|-------|----------|
| `reconciliation_batches` | Günlük kapanış grupları |
| `reconciliation_items` | Mutabakat kalemleri |

### Modül 9: Audit & CDC
| Tablo | Açıklama |
|-------|----------|
| `audit_logs` | Tüm değişikliklerin kaydı |
| `outbox` | CDC için event outbox |
| `event_logs` | İşlenen event'ler |

---

## 🔐 Constraint'ler ve Veri Bütünlüğü

### CHECK Constraint'leri
- `customer_wallets.balance >= 0`
- `customer_wallets.blocked_amount >= 0`
- `customer_wallets.blocked_amount <= balance`
- `tenant_balances.available_balance >= 0`
- `tenant_balances.pending_balance >= 0`
- `transactions.amount > 0`
- `installment_plans.installment_count > 0`

### Unique Constraint'leri
- `transactions (tenant_id, idempotency_key)`
- `tenants (subdomain)`
- `tenants (api_key)`
- `customers (tenant_id, email)`

### Status Geçiş Kuralları
Trigger ile kontrol edilecek geçişler:
- `PENDING → COMPLETED` ✅
- `PENDING → FAILED` ✅
- `PENDING → CANCELLED` ✅
- `COMPLETED → PENDING` ❌ (engellenecek)
- `FAILED → COMPLETED` ❌ (engellenecek)

---

## 📈 Gelişmiş Performans ve Optimizasyon Başlıkları

### 1. Sorgu Planlama ve Optimizasyon (`EXPLAIN ANALYZE`)
- Yavaş sorguların tespit edilmesi ve yürütme planlarının (Execution Plans) okunması.
- Maliyet (Cost) hesaplamalarının incelenmesi ve darboğazların (bottleneck) hangi adımda oluştuğunun saptanması.

### 2. İleri Düzey Index Stratejileri
- **B-Tree:** Standart eşitlik ve aralık aramaları için.
- **Hash:** Eşitlik karşılaştırmaları (`=`) için özel indexler.
- **GIN:** Full-text search ve JSONB veri yapıları için.
- **GiST:** Coğrafi ve geometrik veri tipleri için.
- **BRIN (Block Range Index):** Tarih/zaman gibi fiziksel olarak sıralı çok büyük tablolar için düşük maliyetli indexler.

### 3. Partitioning ve Sharding
- **Partitioning:** Çok büyük tabloların (ör. `transactions`, `audit_logs`) mantıksal olarak alt tablolara bölünmesi (Partition Pruning optimizasyonu).
- **Sharding:** Veritabanının yatayda farklı sunuculara dağıtılması stratejileri (Çok büyük hacimli veriler ve tarihsel arşiv senaryoları).

### 4. JOIN Stratejileri
- **Nested Loop:** Küçük veri setlerinde ve index kullanımına uygun durumlarda.
- **Hash Join:** Büyük veri setlerindeki eşitlik join'leri için bellek tabanlı eşleştirme.
- **Merge Join:** Sıralı veri setlerinin birleştirilmesinde yüksek verimlilik.

### 5. Caching ve Önbellek Stratejileri
- Query cache yaklaşımları.
- Application-level caching (Redis) entegrasyonu.
- Ağır raporlama ve analitik yükler için `Materialized Views` kullanımı.

### 6. Veritabanı İzleme ve Bakım
- **Vacuum & Autovacuum:** Ölü tuple'ların (dead tuples) temizlenmesi ve tablo şişmesinin (bloat) önlenmesi.
- **`pg_stat_statements`:** En maliyetli ve yavaş çalışan sorguların sürekli izlenmesi.
- Log analizi ve veritabanı sağlık denetimleri.

---

## 🧪 Test Planı

### 1. Idempotency Testi
- Aynı `idempotency_key` ile iki kez istek at
- İkincisi hata almalı
- Tek transaction oluşmalı

### 2. Race Condition Testi
- Aynı cüzdandan iki eşzamanlı transfer dene
- Optimistic lock olmadan: lost update gözle
- Version kolonu ile: ikinci işlem hata almalı

### 3. Partitioning & Sorgu Optimizasyonu Testi
- Partition'lı ve partition'sız `transactions` tablosunda aynı sorguyu çalıştır
- `EXPLAIN ANALYZE` ile cost farkını ölç
- Partition pruning çalışıyor mu kontrol et

### 4. Ledger Reconciliation Testi
- Ledger'dan hesaplanan bakiye ile cache bakiye karşılaştır
- Tutarsızlık varsa tespit et
- Reconciliation script çalıştır

### 5. Index ve Performans Testi
- Doğru index seçimi (B-Tree, GIN, BRIN vb.) ile sorgu sürelerini kıyasla
- `pg_stat_statements` üzerinden sorgu maliyetlerini raporla

---

## 🗺️ Yol Haritası

### Faz 1: Setup
- [x] Proje planlama ve mimari kararlar
- [ ] Docker'da PostgreSQL 16 kurulumu
- [ ] Flyway kurulumu
- [ ] Migration dosyalarının yazılması

### Faz 2: Schema
- [ ] Tabloların oluşturulması
- [ ] Constraint'lerin eklenmesi
- [ ] Index'lerin oluşturulması (B-Tree, GIN, BRIN vb.)
- [ ] Trigger'ların yazılması

### Faz 3: Test Verisi
- [ ] Seed data (kur, komisyon oranları)
- [ ] Mock data üretim scripti
- [ ] 10 tenant, 100K müşteri, 1M transaction

### Faz 4: Test
- [ ] Idempotency testi
- [ ] Race condition testi
- [ ] Partitioning testi
- [ ] Reconciliation testi

### Faz 5: Optimizasyon
- [ ] `EXPLAIN ANALYZE` ile sorgu analizi ve tuning
- [ ] `pg_stat_statements` ile yavaş sorgu optimizasyonu
- [ ] Partition arşivleme stratejisi
- [ ] Performance baseline çıkarma

### Faz 6: İleri Seviye
- [ ] CDC (Change Data Capture) implementasyonu
- [ ] Outbox pattern worker simülasyonu
- [ ] Master-slave replication testi
- [ ] Capacity planning dokümanı

---

## 🛠️ Teknoloji Stack

| Araç | Versiyon | Amaç |
|------|----------|------|
| PostgreSQL | 16 | Ana veritabanı |
| Docker | Latest | Ortam izolasyonu |
| Flyway | 9+ | Migration yönetimi |
| pgAdmin | 4 | Görsel arayüz |
| psql | 16 | CLI erişimi |

---

## 📝 Notlar

- Tüm zaman damgaları UTC olarak tutulacak
- Para birimleri `NUMERIC(20,2)` ile tutulacak (float asla kullanılmayacak)
- `TIMESTAMPTZ` her yerde standart
- Hard delete yok, soft delete (status kolonu) kullanılacak
- `payment_methods` tablosu PCI-DSS gereksinimleri nedeniyle ayrı vault servisine taşınmalı

---

## 🔍 Kapasite Planlaması

| Tablo | 1 Yıl Sonra Tahmini | Partition Gerekli mi? |
|-------|---------------------|----------------------|
| `transactions` | ~10M satır | ✅ Evet |
| `wallet_ledger` | ~50M satır | ✅ Evet |
| `audit_logs` | ~100M satır | ✅ Evet |
| `outbox` | ~10M satır | ✅ Evet |
| `customers` | ~1M satır | ❌ Hayır |
| `customer_wallets` | ~1M satır | ❌ Hayır |
| `installment_payments` | ~5M satır | ⚠️ Belki |
| `reconciliation_items` | ~1M satır | ❌ Hayır |