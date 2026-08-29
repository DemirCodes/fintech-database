-- V5: Trigger Oluşturma
-- Amaç: Anayasadaki Status Geçiş Kuralları bölümünde belirtilen trigger'ları oluştur
-- Anayasa Referansı: Status Geçiş Kuralları

-- ==================== STATUS GEÇİŞ KONTROLÜ ====================

-- ==================== STATUS GEÇİŞ KONTROLÜ ====================

-- Transaction status geçişlerini kontrol eden fonksiyon
CREATE OR REPLACE FUNCTION payment.validate_transaction_status_transition()
RETURNS TRIGGER AS $$
BEGIN
    -- İzin verilen geçişler:
    -- PENDING -> COMPLETED
    -- PENDING -> FAILED
    -- PENDING -> CANCELLED
    -- Diğer tüm geçişler engellenir
    
    IF OLD.status = 'COMPLETED' OR OLD.status = 'FAILED' OR OLD.status = 'CANCELLED' THEN
        RAISE EXCEPTION 'Geçersiz status geçişi: % -> %', OLD.status, NEW.status;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Transaction status geçiş trigger'ı
CREATE TRIGGER trg_validate_transaction_status
    BEFORE UPDATE OF status ON payment.transactions
    FOR EACH ROW
    EXECUTE FUNCTION payment.validate_transaction_status_transition();

-- ==================== UPDATED_AT OTOMATİK GÜNCELLEME ====================

-- updated_at kolonunu otomatik güncelleyen fonksiyon
CREATE OR REPLACE FUNCTION core.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- tenants tablosu için
CREATE TRIGGER trg_tenants_updated_at
    BEFORE UPDATE ON core.tenants
    FOR EACH ROW
    EXECUTE FUNCTION core.update_updated_at();

-- users tablosu için
CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON core.users
    FOR EACH ROW
    EXECUTE FUNCTION core.update_updated_at();

-- customers tablosu için
CREATE TRIGGER trg_customers_updated_at
    BEFORE UPDATE ON customer.customers
    FOR EACH ROW
    EXECUTE FUNCTION core.update_updated_at();

-- customer_wallets tablosu için
CREATE TRIGGER trg_wallets_updated_at
    BEFORE UPDATE ON wallet.customer_wallets
    FOR EACH ROW
    EXECUTE FUNCTION core.update_updated_at();

-- tenant_balances tablosu için
CREATE TRIGGER trg_tenant_balances_updated_at
    BEFORE UPDATE ON core.tenant_balances
    FOR EACH ROW
    EXECUTE FUNCTION core.update_updated_at();

-- payment_methods tablosu için
CREATE TRIGGER trg_payment_methods_updated_at
    BEFORE UPDATE ON customer.payment_methods
    FOR EACH ROW
    EXECUTE FUNCTION core.update_updated_at();