# Fintech ve Bankacılık Uygulamaları — Temel Kurallar Rehberi

Bu doküman, finans teknolojileri ve bankacılık uygulamaları geliştirilirken uyulması gereken temel kuralları ve prensipleri kategorilere ayırarak listeler.

---

## 1. İşlem Durumu (Status) Kuralları

- Tamamlanmış (**COMPLETED**) bir işlem asla geriye dönüp değiştirilmez, silinmez.
- Geri alma işlemi = **yeni kayıt** oluşturmak demektir (REFUND / REVERSAL / CHARGEBACK). Eski kayıt olduğu gibi sabit kalır.
- Durum geçişleri belirli bir sıraya bağlıdır (**state machine** mantığı): `PENDING → COMPLETED/FAILED → REFUNDED` gibi. Rastgele durumdan duruma atlanamaz.
- Her ters işlem, orijinal işleme referans ile bağlanır (`original_transaction_id`).
- Kısmi iade (partial refund) varsa, toplam iade tutarı orijinal işlem tutarını geçemez.
- FAILED bir işlem tekrar denenirse **yeni bir kayıt** açılır; eski kayıt FAILED olarak kalır.

## 2. Silme ve Değiştirme Yasağı

- Finansal kayıtlarda **hard delete (fiziksel silme) yoktur**. İptal = yeni durum ya da ters kayıt oluşturmak.
- Geçmiş kayıtlar (audit/log) hiçbir koşulda `UPDATE` edilemez; sadece yeni satır eklenir (**append-only** yapı).
- Yasal saklama süresi (genelde 5-10 yıl, ülkeye/regülasyona göre değişir) dolmadan hiçbir finansal veri silinemez.

## 3. Bakiye ve Limit Kontrolü

- Bakiye asla negatife düşemez (overdraft yetkisi tanımlı değilse).
- İşlem başlamadan **önce** bakiye/limit kontrolü yapılır, işlem sırasında değil.
- PENDING (bekleyen) işlemler bakiyeyi bloke eder (**hold/reserve**) ama gerçek bakiyeden düşmez; işlem onaylanınca kesinleşir, reddedilince blok açılır.
- Günlük/aylık/tekil işlem limitleri her işlemde ayrıca kontrol edilir.
- Aynı hesaba aynı anda gelen iki işlem birbirini ezemez — sıraya alınır, **race condition** engellenir.

## 4. Yetkilendirme / Onay Kuralları

- **Maker-checker (four-eyes) prensibi**: Kritik bir işlemi oluşturan kişi, aynı zamanda onaylayan kişi olamaz.
- Belirli bir tutarın üzerindeki işlemler otomatik olarak ikinci bir onaya düşer.
- Şüpheli/riskli işlemler otomatik tamamlanmaz, **manuel inceleme kuyruğuna** girer.
- Yetkisiz erişim/işlem denemeleri de loglanır — sadece başarılı işlemler değil, başarısız/reddedilen denemeler de kayıt altına alınır.
- Rol bazlı erişim (RBAC) ile her kullanıcı sadece yetkisi dahilindeki işlemleri yapabilir (en az yetki prensibi).

## 5. Mükerrer İşlem Koruması

- Aynı istek (network hatası, çift tıklama, tekrar gönderim vb.) birden fazla kez gelse bile işlem yalnızca **bir kez** gerçekleşir (**idempotency**).
- Bunun için her isteğe tekil bir referans numarası (idempotency key) atanır ve sistem bu anahtara göre tekrarları filtreler.

## 6. Loglama ve Denetim (Audit)

- Bir işlemin geçtiği **her adım ayrı ayrı loglanır** (başlatıldı, onaylandı, reddedildi, tamamlandı) — sadece son durum değil.
- Log kaydında şu bilgiler bulunur: kim yaptı, ne zaman yaptı, hangi kanaldan (web/mobil/API), hangi cihaz/IP'den yaptı.
- Hassas veriler (kart numarası, şifre, kimlik numarası) loglara **asla açık yazılmaz**, maskelenir (örn. `**** **** **** 1234`).
- Audit logları değiştirilemez ve silinemez; genel uygulama loglarından ayrı tutulur.
- Bir işlem birden fazla sistemden/servisten geçiyorsa, uçtan uca izlenebilmesi için tek bir referans/iz numarası ile takip edilir.

## 7. İşlem Sırası ve Önceliklendirme

- Aynı hesaba ait işlemler **FIFO** (ilk giren ilk çıkar) mantığıyla sıraya alınır.
- Öncelik tanımlıysa (örn. maaş ödemesi, otomatik ödeme talimatından önce işlenir) bu önceden belirlenmiş kurallara göre olur; keyfi sıra değişikliği yapılamaz.
- Kuyrukta bekleyen işlemler zaman damgasına (timestamp) göre sıraya girer.

## 8. Uyumluluk (Compliance / Regülasyon)

- Belirli bir tutarın üzerindeki işlemler **AML (kara para aklama önleme)** kontrolünden geçmeden tamamlanamaz.
- **Sanction/kara liste (blacklist)** kontrolü zorunludur; kontrolden geçmeyen işlem otomatik olarak bloklanır.
- **KYC (müşteri tanıma - Know Your Customer)** süreci tamamlanmadan bazı işlem tipleri açılamaz veya sınırlı tutulur.
- Bölgesel regülasyonlara göre veri saklama süresi ve veri lokasyonu (data residency) kuralları uygulanır (KVKK, GDPR, PCI-DSS, BDDK/PSD2 gibi).

## 9. Bildirim ve Şeffaflık

- Önemli işlemler (özellikle para çıkışı, limit değişikliği, şifre/güvenlik ayarı değişikliği) kullanıcıya bildirilir (SMS/push/e-posta).
- Reddedilen işlemlerde kullanıcıya, güvenlik açığı yaratmayacak ölçüde, ret nedeni bilgisi verilir.

---

### Özet Mantık

Bu kuralların ortak paydası üç temel prensiptir:

1. **Geçmiş asla değişmez** — sadece yeni kayıtlarla ilerlenir (append-only, ters işlem mantığı).
2. **Her şey izlenebilir olmalı** — kim, ne zaman, ne yaptı her zaman kayıt altında.
3. **Kritik işlemler tek kişinin insiyatifine bırakılmaz** — kontrol, onay ve doğrulama katmanlarından geçer.
