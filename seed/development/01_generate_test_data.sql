-- ============================================
-- FINTECH TEST VERİSİ ÜRETİM SCRIPT'I
-- Amaç: Gerçekçi test senaryoları için sahte veri üretmek
-- ============================================

-- 1. TENANT'LARI OLUŞTUR (10 Firma)
INSERT INTO core.tenants (name, subdomain, api_key, status) 
SELECT 
    'Firma ' || i,
    'tenant' || i,
    'api_key_' || md5(random()::text),
    'ACTIVE'
FROM generate_series(1, 10) AS i;

-- 2. HER TENANT İÇİN BAKİYE OLUŞTUR (TRY, USD, EUR)
INSERT INTO core.tenant_balances (tenant_id, currency, available_balance, pending_balance)
SELECT 
    t.id,
    c.code,
    (random() * 100000)::NUMERIC(20,2),
    0
FROM core.tenants t
CROSS JOIN core.currencies c
WHERE c.code IN ('TRY', 'USD', 'EUR');

-- 3. KULLANICILAR OLUŞTUR (Her tenant'a 5 kullanıcı)
INSERT INTO core.users (tenant_id, email, password_hash, full_name, role)
SELECT 
    t.id,
    'user' || s.i || '@' || t.subdomain || '.com',
    md5(random()::text),
    'Kullanıcı ' || s.i,
    CASE WHEN s.i = 1 THEN 'ADMIN' ELSE 'VIEWER' END
FROM core.tenants t
CROSS JOIN generate_series(1, 5) AS s(i);

-- 4. MÜŞTERİLER OLUŞTUR (Her tenant'a 1000 müşteri)
INSERT INTO customer.customers (tenant_id, email, phone, full_name, status)
SELECT 
    t.id,
    'customer' || s.i || '@' || t.subdomain || '.com',
    '05' || (random() * 100000000)::INT,
    'Müşteri ' || s.i,
    'ACTIVE'
FROM core.tenants t
CROSS JOIN generate_series(1, 1000) AS s(i);

-- 5. CÜZDANLAR OLUŞTUR (Her müşteriye TRY cüzdanı)
INSERT INTO wallet.customer_wallets (tenant_id, customer_id, currency, balance)
SELECT 
    c.tenant_id,
    c.id,
    'TRY',
    (random() * 10000)::NUMERIC(20,2)
FROM customer.customers c;

-- 6. TRANSACTIONS OLUŞTUR (1 Milyon işlem)
-- Bu işlem biraz zaman alabilir (30-60 saniye)
INSERT INTO payment.transactions (
    tenant_id, customer_id, wallet_id, transaction_type, 
    source_type, destination_type, amount, currency, 
    status, idempotency_key, created_at, completed_at
)
SELECT 
    w.tenant_id,
    w.customer_id,
    w.id,
    CASE WHEN random() < 0.8 THEN 'PAYMENT' ELSE 'DEPOSIT' END,
    CASE WHEN random() < 0.7 THEN 'CARD' ELSE 'BANK_TRANSFER' END,
    'MERCHANT',
    (random() * 1000 + 10)::NUMERIC(20,2),
    'TRY',
    'COMPLETED',
    md5(random()::text || clock_timestamp()::text),
    now() - (random() * 30) * INTERVAL '1 day',
    now() - (random() * 29) * INTERVAL '1 day'
FROM wallet.customer_wallets w
CROSS JOIN generate_series(1, 100) AS s(i);