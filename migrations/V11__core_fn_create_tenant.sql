-- Active: 1788550056509@@127.0.0.1@55432@fintech

-- Modül 1-2: Tenant & Müşteri Yönetimi
-- Fonksiyon: core.fn_create_tenant
-- Amaç: Yeni firma oluşturur ve desteklenen para birimleri için tenant_balances kayıtlarını açar.

CREATE OR REPLACE FUNCTION core.fn_create_tenant(
    p_name VARCHAR(255),
    p_subdomain VARCHAR(100)
) RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_tenant_id UUID;
BEGIN
    INSERT INTO core.tenants (name, subdomain, api_key)
    VALUES (p_name, p_subdomain, encode(gen_random_bytes(32), 'hex'))
    RETURNING id INTO v_tenant_id;

    INSERT INTO core.tenant_balances (tenant_id, currency, available_balance, pending_balance)
    SELECT v_tenant_id, code, 0.00, 0.00
    FROM core.currencies;

    RETURN v_tenant_id;
END;
$$;