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

-- output:  docker exec -i fintech_postgres psql -U fintech_admin -d fintech -c "SELECT core.fn_generate_api_key();"
--   fn_generate_api_key        
----------------------------------
--ec0e140952e40338c24afaac6c1f65a
-- (1 row)