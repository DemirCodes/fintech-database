-- Active: 1788550056509@@127.0.0.1@55432@fintech


-- Modül 3: İşlem Motoru
-- Fonksiyon: payment.fn_create_transaction
-- Amaç: Ana transaction kaydını PENDING statüsünde oluşturur.
-- Not: unique_violation durumunda mevcut kaydı döndürür.

-- Modül 3: İşlem Motoru
-- Fonksiyon: payment.fn_create_transaction
-- Amaç: Ana transaction kaydını PENDING statüsünde oluşturur.
-- Not: Partitioned table olduğu için unique_violation yerine SELECT ile idempotency kontrolü yapılır.

CREATE OR REPLACE FUNCTION payment.fn_create_transaction(
    p_tenant_id UUID,
    p_customer_id UUID,
    p_wallet_id UUID,
    p_transaction_type VARCHAR(30),
    p_source_type VARCHAR(20),
    p_destination_type VARCHAR(20),
    p_amount NUMERIC(20,2),
    p_currency CHAR(3),
    p_idempotency_key VARCHAR(255),
    p_description TEXT DEFAULT NULL
) RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_transaction_id UUID;
BEGIN
    SELECT id
    INTO v_transaction_id
    FROM payment.transactions
    WHERE tenant_id = p_tenant_id
      AND idempotency_key = p_idempotency_key
    LIMIT 1;

    IF v_transaction_id IS NOT NULL THEN
        RETURN v_transaction_id;
    END IF;

    INSERT INTO payment.transactions (
        tenant_id,
        customer_id,
        wallet_id,
        transaction_type,
        source_type,
        destination_type,
        amount,
        currency,
        status,
        idempotency_key,
        description
    ) VALUES (
        p_tenant_id,
        p_customer_id,
        p_wallet_id,
        p_transaction_type,
        p_source_type,
        p_destination_type,
        p_amount,
        p_currency,
        'PENDING',
        p_idempotency_key,
        p_description
    )
    RETURNING id INTO v_transaction_id;

    RETURN v_transaction_id;
END;
$$;