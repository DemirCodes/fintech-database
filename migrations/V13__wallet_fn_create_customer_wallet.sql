-- Active: 1788550056509@@127.0.0.1@55432@fintech

-- Modül 1-2: Tenant & Müşteri Yönetimi
-- Fonksiyon: wallet.fn_create_customer_wallet
-- Amaç: Müşteri için belirli bir para biriminde cüzdan oluşturur.

CREATE OR REPLACE FUNCTION wallet.fn_create_customer_wallet(
    p_tenant_id UUID,
    p_customer_id UUID,
    p_currency CHAR(3)
) RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_wallet_id UUID;
BEGIN
    INSERT INTO wallet.customer_wallets (tenant_id, customer_id, currency)
    VALUES (p_tenant_id, p_customer_id, p_currency)
    RETURNING id INTO v_wallet_id;

    RETURN v_wallet_id;
END;
$$;