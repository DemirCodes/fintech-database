-- Active: 1788550056509@@127.0.0.1@55432@fintech


-- Modül 3: İşlem Motoru
-- Fonksiyon: payment.fn_check_idempotency
-- Amaç: Aynı idempotency_key ile daha önce işlenmiş bir işlem var mı kontrol eder.

CREATE OR REPLACE FUNCTION payment.fn_check_idempotency(
    p_tenant_id UUID,
    p_idempotency_key VARCHAR(255)
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

    RETURN v_transaction_id;
END;
$$;