-- V3: Constraint Ekleme
-- Amaç: Veri bütünlüğünü sağlayan tüm CHECK ve kuralları ekle
-- Anayasa Referansı: 🔐 Constraint'ler ve Veri Bütünlüğü

-- ==================== WALLET CONSTRAINTS ====================

-- Cüzdan bakiyesi asla negatif olamaz
ALTER TABLE wallet.customer_wallets
    ADD CONSTRAINT chk_wallet_balance_nonneg 
    CHECK (balance >= 0);

-- Blokeli tutar asla negatif olamaz
ALTER TABLE wallet.customer_wallets
    ADD CONSTRAINT chk_wallet_blocked_nonneg 
    CHECK (blocked_amount >= 0);

-- Blokeli tutar bakiyeyi aşamaz
ALTER TABLE wallet.customer_wallets
    ADD CONSTRAINT chk_wallet_blocked_le_balance 
    CHECK (blocked_amount <= balance);

-- ==================== TENANT BALANCE CONSTRAINTS ====================

-- Kullanılabilir bakiye negatif olamaz
ALTER TABLE core.tenant_balances
    ADD CONSTRAINT chk_tenant_available_nonneg 
    CHECK (available_balance >= 0);

-- Bekleyen bakiye negatif olamaz
ALTER TABLE core.tenant_balances
    ADD CONSTRAINT chk_tenant_pending_nonneg 
    CHECK (pending_balance >= 0);

-- ==================== TRANSACTION CONSTRAINTS ====================

-- İşlem tutarı her zaman pozitif olmalı
ALTER TABLE payment.transactions
    ADD CONSTRAINT chk_transaction_amount_positive 
    CHECK (amount > 0);

-- ==================== TRANSFER CONSTRAINTS ====================

-- Transfer tutarı pozitif olmalı
ALTER TABLE payment.transfers
    ADD CONSTRAINT chk_transfer_amount_positive 
    CHECK (amount > 0);

-- Gönderen ve alıcı cüzdan aynı olamaz
ALTER TABLE payment.transfers
    ADD CONSTRAINT chk_transfer_wallets_different 
    CHECK (sender_wallet_id <> receiver_wallet_id);

-- ==================== REFUND CONSTRAINTS ====================

-- İade tutarı pozitif olmalı
ALTER TABLE payment.refunds
    ADD CONSTRAINT chk_refund_amount_positive 
    CHECK (amount > 0);

-- ==================== COMMISSION CONSTRAINTS ====================

-- Komisyon yüzdesi 0-100 arasında olmalı
ALTER TABLE billing.commission_rates
    ADD CONSTRAINT chk_commission_percentage_range 
    CHECK (percentage >= 0 AND percentage <= 100);

-- Sabit komisyon negatif olamaz
ALTER TABLE billing.commission_rates
    ADD CONSTRAINT chk_commission_fixed_fee_nonneg 
    CHECK (fixed_fee >= 0);

-- ==================== INSTALLMENT CONSTRAINTS ====================

-- Taksit sayısı en az 1 olmalı
ALTER TABLE billing.installment_plans
    ADD CONSTRAINT chk_installment_count_positive 
    CHECK (installment_count > 0);

-- Taksit tutarı pozitif olmalı
ALTER TABLE billing.installment_payments
    ADD CONSTRAINT chk_installment_amount_positive 
    CHECK (amount > 0);

-- ==================== CHARGEBACK CONSTRAINTS ====================

-- Chargeback tutarı pozitif olmalı
ALTER TABLE billing.chargebacks
    ADD CONSTRAINT chk_chargeback_amount_positive 
    CHECK (amount > 0);

-- ==================== CURRENCY CONSTRAINTS ====================

-- Döviz kuru pozitif olmalı
ALTER TABLE core.currency_rates
    ADD CONSTRAINT chk_currency_rate_positive 
    CHECK (rate > 0);

-- Geçmiş kur değeri pozitif olmalı
ALTER TABLE core.currency_rate_history
    ADD CONSTRAINT chk_currency_rate_history_positive 
    CHECK (rate > 0);

-- ==================== LEDGER CONSTRAINTS ====================

-- Defter kaydı tutarı pozitif olmalı
ALTER TABLE wallet.wallet_ledger
    ADD CONSTRAINT chk_ledger_amount_positive 
    CHECK (amount > 0);