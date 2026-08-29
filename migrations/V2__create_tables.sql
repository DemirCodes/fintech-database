-- V2: Tablo Oluşturma
-- Amaç: Tüm tabloları modüler şemalar altında oluştur

-- ==================== CORE ŞEMASI ====================
-- core: Sistemin ana modülü. Firmalar, kullanıcılar ve para birimleri burada.

-- Platformu kullanan firmaların kayıtlarını tutar (multi-tenant ana tablo)
CREATE TABLE core.tenants (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Benzersiz firma kimliği (otomatik üretilir)
    name            VARCHAR(255) NOT NULL,                      -- Firma adı
    subdomain       VARCHAR(100) UNIQUE NOT NULL,               -- Firmaya özel benzersiz alt alan adı
    api_key         TEXT UNIQUE NOT NULL,                       -- API erişimi için benzersiz anahtar
    webhook_url     TEXT,                                       -- Firma bildirimlerinin gideceği URL
    status          VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',      -- Firma durumu: ACTIVE/SUSPENDED/CLOSED
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),         -- Kayıt oluşturulma zamanı (UTC)
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()          -- Son güncellenme zamanı
);

-- Her firmanın platformdaki para bakiyesini tutar (multi-currency)
CREATE TABLE core.tenant_balances (
    tenant_id        UUID NOT NULL REFERENCES core.tenants(id),  -- Hangi firmaya ait olduğu
    currency         CHAR(3) NOT NULL,                           -- Para birimi kodu (TRY/USD/EUR)
    available_balance NUMERIC(20,2) NOT NULL DEFAULT 0,          -- Kullanılabilir bakiye
    pending_balance   NUMERIC(20,2) NOT NULL DEFAULT 0,          -- Bekleyen (henüz netleşmemiş) bakiye
    version          INT NOT NULL DEFAULT 0,                     -- Optimistic locking için sürüm numarası
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),         -- Son güncellenme zamanı
    PRIMARY KEY (tenant_id, currency)                            -- Aynı firmada aynı para biriminden 2 kayıt olamaz
);

-- Firmalara bağlı çalışanlar (admin, muhasebeci vb.)
CREATE TABLE core.users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Benzersiz kullanıcı kimliği
    tenant_id       UUID NOT NULL REFERENCES core.tenants(id),   -- Kullanıcının ait olduğu firma
    email           VARCHAR(255) NOT NULL,                       -- E-posta adresi
    password_hash   TEXT NOT NULL,                               -- Şifrenin hash'lenmiş hali (asla düz metin değil)
    full_name       VARCHAR(255),                                -- Kullanıcının adı soyadı
    role            VARCHAR(30) NOT NULL DEFAULT 'ADMIN',        -- Rolü: ADMIN/ACCOUNTANT/VIEWER
    status          VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',       -- Hesap durumu: ACTIVE/INACTIVE
    last_login_at   TIMESTAMPTZ,                                 -- Son giriş zamanı
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),          -- Kayıt oluşturulma zamanı
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),          -- Son güncellenme zamanı
    UNIQUE (tenant_id, email)                                    -- Aynı firmada aynı e-posta iki kez kullanılamaz
);

-- Kullanıcıların oturum bilgilerini tutar
CREATE TABLE core.user_sessions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Benzersiz oturum kimliği
    user_id         UUID NOT NULL REFERENCES core.users(id),     -- Oturumun ait olduğu kullanıcı
    token           TEXT NOT NULL,                               -- Oturum token'ı
    ip_address      INET,                                        -- Kullanıcının IP adresi
    user_agent      TEXT,                                        -- Tarayıcı/istemci bilgisi
    expires_at      TIMESTAMPTZ,                                 -- Oturumun sona ereceği zaman
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()           -- Oturumun başladığı zaman
);

-- Para birimlerinin tanımlandığı tablo
CREATE TABLE core.currencies (
    code            CHAR(3) PRIMARY KEY,                         -- Para birimi kodu: TRY/USD/EUR
    name            VARCHAR(100) NOT NULL,                       -- Para biriminin açık adı
    symbol          VARCHAR(10) NOT NULL,                        -- Sembolü: ₺/$/€
    decimal_places  INT NOT NULL DEFAULT 2                       -- Ondalık basamak sayısı
);

-- Döviz kurlarının güncel değerlerini tutar
CREATE TABLE core.currency_rates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Benzersiz kur kaydı
    base_currency   CHAR(3) NOT NULL REFERENCES core.currencies(code),  -- Kaynak para birimi
    target_currency CHAR(3) NOT NULL REFERENCES core.currencies(code),  -- Hedef para birimi
    rate            NUMERIC(20,6) NOT NULL,                      -- Kur değeri (örn: 1 USD = 35.20 TRY)
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),          -- Son güncellenme zamanı
    UNIQUE (base_currency, target_currency)                      -- Aynı kur çifti iki kez kaydedilemez
);

-- Döviz kurlarının geçmiş değerlerini tutar
CREATE TABLE core.currency_rate_history (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Benzersiz geçmiş kaydı
    rate_id         UUID NOT NULL REFERENCES core.currency_rates(id), -- Hangi kur çiftine ait olduğu
    rate            NUMERIC(20,6) NOT NULL,                      -- O andaki kur değeri
    recorded_at     TIMESTAMPTZ NOT NULL DEFAULT now()           -- Kayıt zamanı
);

-- ==================== CUSTOMER ŞEMASI ====================
-- customer: Son kullanıcıların (müşterilerin) bilgileri burada tutulur.

-- Firmaların son kullanıcılarını (müşterilerini) tutar
CREATE TABLE customer.customers (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Benzersiz müşteri kimliği
    tenant_id       UUID NOT NULL REFERENCES core.tenants(id),   -- Hangi firmaya ait olduğu
    email           VARCHAR(255),                                -- Müşterinin e-postası
    phone           VARCHAR(30),                                 -- Müşterinin telefonu
    full_name       VARCHAR(255) NOT NULL,                       -- Müşterinin adı soyadı
    tckn            VARCHAR(11),                                 -- TC Kimlik No (opsiyonel)
    metadata        JSONB DEFAULT '{}',                          -- Esnek ek veri alanı
    status          VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',       -- Müşteri durumu: ACTIVE/BLOCKED/CLOSED
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),          -- Kayıt oluşturulma zamanı
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),          -- Son güncellenme zamanı
    UNIQUE (tenant_id, email)                                    -- Aynı firmada aynı e-posta iki kez kullanılamaz
);

-- Müşterilerin adreslerini tutar
CREATE TABLE customer.customer_addresses (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Benzersiz adres kimliği
    customer_id     UUID NOT NULL REFERENCES customer.customers(id), -- Adresin sahibi olan müşteri
    address_type    VARCHAR(20) NOT NULL DEFAULT 'SHIPPING',     -- Adres tipi: SHIPPING/BILLING
    address_line    TEXT NOT NULL,                               -- Açık adres satırı
    city            VARCHAR(100),                                -- Şehir
    country         VARCHAR(100),                                -- Ülke
    postal_code     VARCHAR(20),                                 -- Posta kodu
    is_default      BOOLEAN NOT NULL DEFAULT false,              -- Varsayılan adres mi
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()           -- Kayıt oluşturulma zamanı
);

-- Müşterilerin kayıtlı ödeme yöntemlerini tutar (kart, banka vb.)
CREATE TABLE customer.payment_methods (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Benzersiz ödeme yöntemi kimliği
    tenant_id       UUID NOT NULL REFERENCES core.tenants(id),   -- Hangi firmaya ait olduğu
    customer_id     UUID NOT NULL REFERENCES customer.customers(id), -- Ödeme yönteminin sahibi
    method_type     VARCHAR(20) NOT NULL,                        -- Tipi: CARD/BANK_TRANSFER
    provider        VARCHAR(50),                                 -- Sağlayıcı: visa/mastercard
    token           TEXT NOT NULL,                               -- Tokenize edilmiş kart bilgisi (asla düz kart no değil)
    last4           VARCHAR(4),                                  -- Kartın son 4 hanesi
    card_brand      VARCHAR(20),                                 -- Kart markası: VISA/MASTERCARD
    card_holder_name VARCHAR(255),                               -- Kart sahibinin adı
    expire_month    INT,                                         -- Son kullanma ayı
    expire_year     INT,                                         -- Son kullanma yılı
    is_default      BOOLEAN NOT NULL DEFAULT false,              -- Varsayılan ödeme yöntemi mi
    status          VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',       -- Durumu: ACTIVE/EXPIRED/CANCELLED
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),          -- Kayıt oluşturulma zamanı
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()           -- Son güncellenme zamanı
);

-- ==================== WALLET ŞEMASI ====================
-- wallet: Müşteri cüzdanları ve defter kayıtları burada tutulur.

-- Müşterilerin para cüzdanlarını tutar (multi-currency)
CREATE TABLE wallet.customer_wallets (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Benzersiz cüzdan kimliği
    tenant_id       UUID NOT NULL REFERENCES core.tenants(id),   -- Hangi firmaya ait olduğu
    customer_id     UUID NOT NULL REFERENCES customer.customers(id), -- Cüzdanın sahibi
    currency        CHAR(3) NOT NULL,                            -- Para birimi
    balance         NUMERIC(20,2) NOT NULL DEFAULT 0,            -- Güncel bakiye (cache değer, ledger'dan türetilir)
    blocked_amount  NUMERIC(20,2) NOT NULL DEFAULT 0,            -- Blokeli tutar (işlemde olan para)
    version         INT NOT NULL DEFAULT 0,                      -- Optimistic locking için sürüm
    status          VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',       -- Cüzdan durumu: ACTIVE/BLOCKED
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),          -- Kayıt oluşturulma zamanı
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),          -- Son güncellenme zamanı
    UNIQUE (tenant_id, customer_id, currency)                    -- Aynı müşteri aynı para biriminde 2 cüzdan sahibi olamaz
);

-- Cüzdan hareketlerinin defter kaydı (source of truth)
CREATE TABLE wallet.wallet_ledger (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Benzersiz defter kaydı
    wallet_id       UUID NOT NULL REFERENCES wallet.customer_wallets(id), -- Hangi cüzdana ait
    tenant_id       UUID NOT NULL REFERENCES core.tenants(id),   -- Hangi firmaya ait
    transaction_id  UUID,                                        -- İlişkili işlem (opsiyonel)
    entry_type      VARCHAR(20) NOT NULL,                        -- Hareket tipi: DEBIT/CREDIT
    amount          NUMERIC(20,2) NOT NULL,                      -- Hareket tutarı
    running_balance NUMERIC(20,2) NOT NULL,                      -- İşlem sonrası bakiye
    description     TEXT,                                        -- Hareket açıklaması
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()           -- Kayıt oluşturulma zamanı
);

-- ==================== PAYMENT ŞEMASI ====================
-- payment: Tüm para işlemleri (ödeme, transfer, iade) burada tutulur.

-- Ana işlem tablosu: tüm para hareketlerinin kaydı
CREATE TABLE payment.transactions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Benzersiz işlem kimliği
    tenant_id       UUID NOT NULL REFERENCES core.tenants(id),   -- Hangi firmaya ait
    customer_id     UUID NOT NULL REFERENCES customer.customers(id), -- İşlemi yapan müşteri
    wallet_id       UUID NOT NULL REFERENCES wallet.customer_wallets(id), -- Hangi cüzdandan yapıldığı
    transaction_type VARCHAR(30) NOT NULL,                       -- Tipi: PAYMENT/DEPOSIT/WITHDRAWAL/TRANSFER/REFUND
    source_type     VARCHAR(20),                                 -- Para kaynağı: CARD/BANK_TRANSFER/WALLET
    destination_type VARCHAR(20),                                -- Para hedefi: CARD/BANK_TRANSFER/MERCHANT
    amount          NUMERIC(20,2) NOT NULL,                      -- İşlem tutarı
    currency        CHAR(3) NOT NULL,                            -- Para birimi
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',      -- Durum: PENDING/COMPLETED/FAILED/CANCELLED
    idempotency_key VARCHAR(255) NOT NULL,                       -- Tekrar eden istekleri engelleyen anahtar
    description     TEXT,                                        -- İşlem açıklaması
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),          -- İşlemin oluşturulma zamanı
    completed_at    TIMESTAMPTZ,                                 -- İşlemin tamamlanma zamanı
    UNIQUE (tenant_id, idempotency_key)                          -- Aynı firma için aynı idempotency key 2 kez kullanılamaz
);

-- İşlemlerin detay bilgilerini tutar
CREATE TABLE payment.transaction_details (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Benzersiz detay kimliği
    transaction_id  UUID NOT NULL REFERENCES payment.transactions(id), -- Hangi işlemin detayı
    source_account  VARCHAR(50),                                 -- Kaynak hesap bilgisi
    destination_account VARCHAR(50),                             -- Hedef hesap bilgisi
    fee_amount      NUMERIC(20,2) DEFAULT 0,                     -- İşlem ücreti
    net_amount      NUMERIC(20,2),                               -- Net tutar (fee düşülmüş)
    metadata        JSONB DEFAULT '{}'                           -- Esnek ek veri
);

-- Müşteriler arası para transferlerini tutar
CREATE TABLE payment.transfers (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Benzersiz transfer kimliği
    tenant_id       UUID NOT NULL REFERENCES core.tenants(id),   -- Hangi firmaya ait
    sender_wallet_id UUID NOT NULL REFERENCES wallet.customer_wallets(id), -- Gönderen cüzdan
    receiver_wallet_id UUID NOT NULL REFERENCES wallet.customer_wallets(id), -- Alıcı cüzdan
    amount          NUMERIC(20,2) NOT NULL,                      -- Transfer tutarı
    currency        CHAR(3) NOT NULL,                            -- Para birimi
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',      -- Durum: PENDING/COMPLETED/FAILED
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),          -- Oluşturulma zamanı
    completed_at    TIMESTAMPTZ                                  -- Tamamlanma zamanı
);

-- İade işlemlerini tutar
CREATE TABLE payment.refunds (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Benzersiz iade kimliği
    transaction_id  UUID NOT NULL REFERENCES payment.transactions(id), -- Hangi işlemin iadesi
    tenant_id       UUID NOT NULL REFERENCES core.tenants(id),   -- Hangi firmaya ait
    amount          NUMERIC(20,2) NOT NULL,                      -- İade tutarı
    reason          TEXT,                                        -- İade nedeni
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',      -- Durum: PENDING/APPROVED/REJECTED
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),          -- Oluşturulma zamanı
    processed_at    TIMESTAMPTZ                                  -- İşleme alınma zamanı
);

-- ==================== BILLING ŞEMASI ====================
-- billing: Faturalama, komisyon, taksit ve chargeback işlemleri burada.

-- Tenant bazlı komisyon oranlarını tutar
CREATE TABLE billing.commission_rates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Benzersiz oran kimliği
    tenant_id       UUID NOT NULL REFERENCES core.tenants(id),   -- Hangi firmaya ait
    transaction_type VARCHAR(30) NOT NULL,                       -- Hangi işlem tipi için geçerli
    percentage      NUMERIC(5,2) DEFAULT 0,                      -- Yüzdelik komisyon (örn: 2.50)
    fixed_fee       NUMERIC(10,2) DEFAULT 0,                     -- Sabit komisyon ücreti
    currency        CHAR(3) NOT NULL,                            -- Para birimi
    effective_from  TIMESTAMPTZ NOT NULL DEFAULT now(),          -- Geçerlilik başlangıcı
    effective_to    TIMESTAMPTZ                                  -- Geçerlilik sonu (null ise hala geçerli)
);

-- Kesilen komisyonların kaydını tutar
CREATE TABLE billing.commissions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Benzersiz komisyon kaydı
    tenant_id       UUID NOT NULL REFERENCES core.tenants(id),   -- Hangi firmadan kesildiği
    transaction_id  UUID NOT NULL REFERENCES payment.transactions(id), -- Hangi işlemden kesildiği
    amount          NUMERIC(20,2) NOT NULL,                      -- Kesilen komisyon tutarı
    currency        CHAR(3) NOT NULL,                            -- Para birimi
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()           -- Kesilme zamanı
);

-- Taksit planlarını tutar
CREATE TABLE billing.installment_plans (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Benzersiz plan kimliği
    tenant_id       UUID NOT NULL REFERENCES core.tenants(id),   -- Hangi firmaya ait
    transaction_id  UUID NOT NULL REFERENCES payment.transactions(id), -- Hangi işlem taksitlendirildi
    total_amount    NUMERIC(20,2) NOT NULL,                      -- Toplam tutar
    installment_count INT NOT NULL,                              -- Taksit sayısı
    frequency       VARCHAR(20) NOT NULL DEFAULT 'MONTHLY',      -- Taksit aralığı: MONTHLY/WEEKLY
    status          VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',       -- Plan durumu: ACTIVE/COMPLETED/DEFAULTED
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()           -- Oluşturulma zamanı
);

-- Taksit ödemelerini tutar
CREATE TABLE billing.installment_payments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Benzersiz ödeme kimliği
    plan_id         UUID NOT NULL REFERENCES billing.installment_plans(id), -- Hangi plana ait
    amount          NUMERIC(20,2) NOT NULL,                      -- Taksit tutarı
    due_date        DATE NOT NULL,                               -- Son ödeme tarihi
    paid_date       TIMESTAMPTZ,                                 -- Ödendiği tarih
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',      -- Durum: PENDING/PAID/OVERDUE
    transaction_id  UUID REFERENCES payment.transactions(id)     -- İlişkili işlem
);

-- Chargeback (itiraz) kayıtlarını tutar
CREATE TABLE billing.chargebacks (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Benzersiz itiraz kimliği
    tenant_id       UUID NOT NULL REFERENCES core.tenants(id),   -- Hangi firmaya ait
    transaction_id  UUID NOT NULL REFERENCES payment.transactions(id), -- Hangi işleme itiraz edildi
    customer_id     UUID NOT NULL REFERENCES customer.customers(id), -- İtiraz eden müşteri
    amount          NUMERIC(20,2) NOT NULL,                      -- İtiraz edilen tutar
    reason          TEXT,                                        -- İtiraz nedeni
    status          VARCHAR(20) NOT NULL DEFAULT 'OPEN',         -- Durum: OPEN/WON/LOST/CLOSED
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),          -- Oluşturulma zamanı
    resolved_at     TIMESTAMPTZ                                  -- Çözümlenme zamanı
);

-- Chargeback durum geçmişini tutar
CREATE TABLE billing.chargeback_status_history (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Benzersiz geçmiş kaydı
    chargeback_id   UUID NOT NULL REFERENCES billing.chargebacks(id), -- Hangi itiraza ait
    old_status      VARCHAR(20),                                 -- Eski durum
    new_status      VARCHAR(20) NOT NULL,                        -- Yeni durum
    changed_by      UUID REFERENCES core.users(id),              -- Değişikliği yapan kullanıcı
    changed_at      TIMESTAMPTZ NOT NULL DEFAULT now()           -- Değişiklik zamanı
);

-- ==================== RECONCILIATION ŞEMASI ====================
-- reconciliation: Günlük mutabakat (hesap eşleştirme) işlemleri burada.

-- Günlük mutabakat gruplarını tutar
CREATE TABLE reconciliation.reconciliation_batches (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Benzersiz batch kimliği
    tenant_id       UUID NOT NULL REFERENCES core.tenants(id),   -- Hangi firmaya ait
    batch_date      DATE NOT NULL,                               -- Mutabakat tarihi
    total_transactions INT DEFAULT 0,                            -- Toplam işlem sayısı
    total_amount    NUMERIC(20,2) DEFAULT 0,                     -- Toplam tutar
    status          VARCHAR(20) NOT NULL DEFAULT 'OPEN',         -- Durum: OPEN/IN_PROGRESS/MATCHED/MISMATCHED/CLOSED
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),          -- Oluşturulma zamanı
    closed_at       TIMESTAMPTZ                                  -- Kapanış zamanı
);

-- Mutabakat kalemlerini tutar (her işlem için bir kayıt)
CREATE TABLE reconciliation.reconciliation_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Benzersiz kalem kimliği
    batch_id        UUID NOT NULL REFERENCES reconciliation.reconciliation_batches(id), -- Hangi batch'e ait
    transaction_id  UUID NOT NULL REFERENCES payment.transactions(id), -- Hangi işlem
    external_reference VARCHAR(255),                             -- Dış sistem referans no (banka referansı)
    expected_amount NUMERIC(20,2),                               -- Beklenen tutar
    actual_amount   NUMERIC(20,2),                               -- Gerçekleşen tutar
    diff_amount     NUMERIC(20,2),                               -- Fark tutarı
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',      -- Durum: PENDING/MATCHED/MISMATCHED
    matched_at      TIMESTAMPTZ,                                 -- Eşleşme zamanı
    notes           TEXT                                         -- Açıklama notu
);

-- ==================== AUDIT ŞEMASI ====================
-- audit: Tüm değişikliklerin loglandığı ve CDC event'lerinin tutulduğu şema.

-- Sistemdeki tüm değişikliklerin denetim kaydı
CREATE TABLE audit.audit_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Benzersiz log kimliği
    tenant_id       UUID REFERENCES core.tenants(id),            -- Hangi firmaya ait (sistem geneli ise null)
    table_name      VARCHAR(100) NOT NULL,                       -- Değişiklik yapılan tablo adı
    record_id       UUID NOT NULL,                               -- Değişiklik yapılan kaydın kimliği
    action          VARCHAR(20) NOT NULL,                        -- Yapılan işlem: INSERT/UPDATE/DELETE
    old_data        JSONB,                                       -- Değişiklik öncesi veri
    new_data        JSONB,                                       -- Değişiklik sonrası veri
    changed_by      UUID REFERENCES core.users(id),              -- Değişikliği yapan kullanıcı (sistem ise null)
    changed_at      TIMESTAMPTZ NOT NULL DEFAULT now()           -- Değişiklik zamanı
);

-- CDC için outbox pattern tablosu (event'ler burada birikir)
CREATE TABLE audit.outbox (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Benzersiz event kimliği
    aggregate_type  VARCHAR(100) NOT NULL,                       -- Event'in ait olduğu aggregate tipi (örn: Transaction)
    aggregate_id    UUID NOT NULL,                               -- Aggregate'in kimliği
    event_type      VARCHAR(100) NOT NULL,                       -- Event tipi (örn: TransactionCreated)
    payload         JSONB NOT NULL DEFAULT '{}',                 -- Event verisi
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',      -- Durum: PENDING/PUBLISHED/FAILED
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),          -- Event'in oluşturulma zamanı
    published_at    TIMESTAMPTZ                                  -- Event'in yayınlanma zamanı
);

-- İşlenen event'lerin loglarını tutar
CREATE TABLE audit.event_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),  -- Benzersiz log kimliği
    event_id        UUID NOT NULL REFERENCES audit.outbox(id),   -- Hangi event'e ait
    consumer_name   VARCHAR(100) NOT NULL,                       -- Event'i işleyen servis adı
    status          VARCHAR(20) NOT NULL DEFAULT 'SUCCESS',      -- İşlem sonucu: SUCCESS/FAILED
    error_message   TEXT,                                        -- Hata mesajı (varsa)
    processed_at    TIMESTAMPTZ NOT NULL DEFAULT now()           -- İşlenme zamanı
);