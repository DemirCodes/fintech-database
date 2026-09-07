-- Active: 1788550056509@@127.0.0.1@55432@fintech


-- Modül 3: İşlem Motoru
-- Fonksiyon: wallet.fn_lock_wallet_for_update
-- Amaç: Cüzdan satırını kilitleyerek eşzamanlı işlemleri engeller.

CREATE OR REPLACE FUNCTION wallet.fn_lock_wallet_for_update(
    p_wallet_id UUID
) RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_wallet_id UUID;
BEGIN
    SELECT id
    INTO v_wallet_id
    FROM wallet.customer_wallets
    WHERE id = p_wallet_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Cüzdan bulunamadı: %', p_wallet_id;
    END IF;

    RETURN v_wallet_id;
END;
$$;