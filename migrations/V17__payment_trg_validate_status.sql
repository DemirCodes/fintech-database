-- Active: 1788550056509@@127.0.0.1@55432@fintech


-- Modül 3: İşlem Motoru
-- Trigger Fonksiyonu: payment.trg_validate_status
-- Amaç: Status geçiş kurallarını zorlar.

CREATE OR REPLACE FUNCTION payment.trg_validate_status()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.status = 'COMPLETED' AND NEW.status <> 'COMPLETED' THEN
        RAISE EXCEPTION 'COMPLETED durumundan başka duruma geçilemez';
    END IF;

    IF OLD.status = 'FAILED' AND NEW.status <> 'FAILED' THEN
        RAISE EXCEPTION 'FAILED durumundan başka duruma geçilemez';
    END IF;

    IF OLD.status = 'CANCELLED' AND NEW.status <> 'CANCELLED' THEN
        RAISE EXCEPTION 'CANCELLED durumundan başka duruma geçilemez';
    END IF;

    RETURN NEW;
END;
$$;


CREATE TRIGGER trg_validate_status
BEFORE UPDATE OF status ON payment.transactions
FOR EACH ROW
EXECUTE FUNCTION payment.trg_validate_status();