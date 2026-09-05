-- Active: 1788550056509@@127.0.0.1@55432@fintech

-- Modül 1-2: Tenant & Müşteri Yönetimi
-- Fonksiyon: core.fn_generate_api_key
-- Amaç: Benzersiz api_key üretir.

CREATE OR REPLACE FUNCTION core.fn_generate_api_key()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_key TEXT;
BEGIN
    LOOP
        v_key := replace(gen_random_uuid()::text, '-', '');

        BEGIN
            RETURN v_key;
        END;
    END LOOP;
END;
$$;