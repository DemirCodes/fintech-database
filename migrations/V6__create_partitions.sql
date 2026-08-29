-- V6: Partitioning
-- Amaç: Anayasadaki Partitioning Stratejisi bölümünde belirtilen tabloları partition'lı hale getir
-- Anayasa Referansı: Partitioning Stratejisi

-- ==================== TRANSACTIONS PARTITIONING ====================
-- Aralık: Aylık | Arşiv: 24 ay

-- Mevcut tabloyu sil
DROP TABLE IF EXISTS payment.transaction_details CASCADE;
DROP TABLE IF EXISTS payment.transactions CASCADE;

-- Partition'lı olarak yeniden oluştur
CREATE TABLE payment.transactions (
    id              UUID DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES core.tenants(id),
    customer_id     UUID NOT NULL REFERENCES customer.customers(id),
    wallet_id       UUID NOT NULL REFERENCES wallet.customer_wallets(id),
    transaction_type VARCHAR(30) NOT NULL,
    source_type     VARCHAR(20),
    destination_type VARCHAR(20),
    amount          NUMERIC(20,2) NOT NULL,
    currency        CHAR(3) NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    idempotency_key VARCHAR(255) NOT NULL,
    description     TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at    TIMESTAMPTZ,
    PRIMARY KEY (id, created_at),
    UNIQUE (tenant_id, idempotency_key, created_at)
) PARTITION BY RANGE (created_at);

-- İlk partition'ları oluştur (2026 Ağustos - 2026 Aralık)
CREATE TABLE payment.transactions_2026_08 PARTITION OF payment.transactions
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');

CREATE TABLE payment.transactions_2026_09 PARTITION OF payment.transactions
    FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');

CREATE TABLE payment.transactions_2026_10 PARTITION OF payment.transactions
    FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');

CREATE TABLE payment.transactions_2026_11 PARTITION OF payment.transactions
    FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');

CREATE TABLE payment.transactions_2026_12 PARTITION OF payment.transactions
    FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');

-- transaction_details tablosunu yeniden oluştur
CREATE TABLE payment.transaction_details (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id  UUID NOT NULL,
    source_account  VARCHAR(50),
    destination_account VARCHAR(50),
    fee_amount      NUMERIC(20,2) DEFAULT 0,
    net_amount      NUMERIC(20,2),
    metadata        JSONB DEFAULT '{}'
);

-- ==================== WALLET LEDGER PARTITIONING ====================
-- Aralık: Aylık | Arşiv: 24 ay

-- Mevcut tabloyu sil
DROP TABLE IF EXISTS wallet.wallet_ledger CASCADE;

-- Partition'lı olarak yeniden oluştur
CREATE TABLE wallet.wallet_ledger (
    id              UUID DEFAULT gen_random_uuid(),
    wallet_id       UUID NOT NULL REFERENCES wallet.customer_wallets(id),
    tenant_id       UUID NOT NULL REFERENCES core.tenants(id),
    transaction_id  UUID,
    entry_type      VARCHAR(20) NOT NULL,
    amount          NUMERIC(20,2) NOT NULL,
    running_balance NUMERIC(20,2) NOT NULL,
    description     TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- İlk partition'ları oluştur
CREATE TABLE wallet.wallet_ledger_2026_08 PARTITION OF wallet.wallet_ledger
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');

CREATE TABLE wallet.wallet_ledger_2026_09 PARTITION OF wallet.wallet_ledger
    FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');

CREATE TABLE wallet.wallet_ledger_2026_10 PARTITION OF wallet.wallet_ledger
    FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');

CREATE TABLE wallet.wallet_ledger_2026_11 PARTITION OF wallet.wallet_ledger
    FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');

CREATE TABLE wallet.wallet_ledger_2026_12 PARTITION OF wallet.wallet_ledger
    FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');

-- ==================== AUDIT LOGS PARTITIONING ====================
-- Aralık: Aylık | Arşiv: 12 ay

-- Mevcut tabloyu sil
DROP TABLE IF EXISTS audit.audit_logs CASCADE;

-- Partition'lı olarak yeniden oluştur
CREATE TABLE audit.audit_logs (
    id              UUID DEFAULT gen_random_uuid(),
    tenant_id       UUID REFERENCES core.tenants(id),
    table_name      VARCHAR(100) NOT NULL,
    record_id       UUID NOT NULL,
    action          VARCHAR(20) NOT NULL,
    old_data        JSONB,
    new_data        JSONB,
    changed_by      UUID REFERENCES core.users(id),
    changed_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id, changed_at)
) PARTITION BY RANGE (changed_at);

-- İlk partition'ları oluştur
CREATE TABLE audit.audit_logs_2026_08 PARTITION OF audit.audit_logs
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');

CREATE TABLE audit.audit_logs_2026_09 PARTITION OF audit.audit_logs
    FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');

CREATE TABLE audit.audit_logs_2026_10 PARTITION OF audit.audit_logs
    FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');

CREATE TABLE audit.audit_logs_2026_11 PARTITION OF audit.audit_logs
    FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');

CREATE TABLE audit.audit_logs_2026_12 PARTITION OF audit.audit_logs
    FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');

-- ==================== OUTBOX PARTITIONING ====================
-- Aralık: Haftalık | Arşiv: 30 gün

-- Mevcut tabloyu sil
DROP TABLE IF EXISTS audit.event_logs CASCADE;
DROP TABLE IF EXISTS audit.outbox CASCADE;

-- Partition'lı olarak yeniden oluştur
CREATE TABLE audit.outbox (
    id              UUID DEFAULT gen_random_uuid(),
    aggregate_type  VARCHAR(100) NOT NULL,
    aggregate_id    UUID NOT NULL,
    event_type      VARCHAR(100) NOT NULL,
    payload         JSONB NOT NULL DEFAULT '{}',
    status          VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    published_at    TIMESTAMPTZ,
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

-- İlk haftalık partition'ları oluştur (Ağustos 2026 - 4 hafta)
CREATE TABLE audit.outbox_2026_w33 PARTITION OF audit.outbox
    FOR VALUES FROM ('2026-08-10') TO ('2026-08-17');

CREATE TABLE audit.outbox_2026_w34 PARTITION OF audit.outbox
    FOR VALUES FROM ('2026-08-17') TO ('2026-08-24');

CREATE TABLE audit.outbox_2026_w35 PARTITION OF audit.outbox
    FOR VALUES FROM ('2026-08-24') TO ('2026-08-31');

CREATE TABLE audit.outbox_2026_w36 PARTITION OF audit.outbox
    FOR VALUES FROM ('2026-08-31') TO ('2026-09-07');

-- event_logs tablosunu yeniden oluştur
CREATE TABLE audit.event_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id        UUID NOT NULL,
    consumer_name   VARCHAR(100) NOT NULL,
    status          VARCHAR(20) NOT NULL DEFAULT 'SUCCESS',
    error_message   TEXT,
    processed_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);