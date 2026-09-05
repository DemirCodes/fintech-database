-- Active: 1788550056509@@127.0.0.1@55432@fintech

-- Modül 1-2: Tenant & Müşteri Yönetimi
-- Fonksiyon: core.fn_validate_session
-- Amaç: Oturumun geçerli olup olmadığını kontrol eder.

CREATE OR REPLACE FUNCTION core.fn_validate_session(
    p_session_id UUID,
    p_user_id UUID,
    p_ip INET,
    p_ua TEXT
) RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    v_expires_at TIMESTAMPTZ;
    v_ip INET;
    v_ua TEXT;
BEGIN
    SELECT expires_at, ip_address, user_agent
    INTO v_expires_at, v_ip, v_ua
    FROM core.user_sessions
    WHERE id = p_session_id
      AND user_id = p_user_id;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    IF v_expires_at IS NOT NULL AND v_expires_at < now() THEN
        RETURN FALSE;
    END IF;

    IF v_ip IS NOT NULL AND v_ip <> p_ip THEN
        RETURN FALSE;
    END IF;

    IF v_ua IS NOT NULL AND v_ua <> p_ua THEN
        RETURN FALSE;
    END IF;

    RETURN TRUE;
END;
$$;