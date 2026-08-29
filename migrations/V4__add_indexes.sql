-- V4: Index Oluşturma
-- Amaç: Anayasadaki Index Stratejisi bölümünde belirtilen tüm index'leri oluştur
-- Anayasa Referansı: 📈 Index Stratejisi

-- ==================== TRANSACTION INDEX'leri ====================

-- Müşteri işlem geçmişi sorguları için
-- Kullanım: SELECT * FROM payment.transactions WHERE tenant_id = ? AND customer_id = ? ORDER BY created_at DESC
CREATE INDEX idx_transactions_customer_time 
    ON payment.transactions (tenant_id, customer_id, created_at DESC);

-- ==================== LEDGER INDEX'leri ====================

-- Bakiye hesaplama ve mutabakat için
-- Kullanım: SELECT * FROM wallet.wallet_ledger WHERE wallet_id = ? ORDER BY created_at
CREATE INDEX idx_ledger_wallet_time 
    ON wallet.wallet_ledger (wallet_id, created_at);

-- ==================== OUTBOX INDEX'leri ====================

-- Pending event'leri hızlı çekmek için (partial index)
-- Kullanım: SELECT * FROM audit.outbox WHERE status = 'PENDING' ORDER BY created_at
CREATE INDEX idx_outbox_pending 
    ON audit.outbox (created_at) 
    WHERE status = 'PENDING';

-- ==================== CHARGEBACK INDEX'leri ====================

-- Açık chargeback'leri listeleme için
-- Kullanım: SELECT * FROM billing.chargebacks WHERE tenant_id = ? AND status = 'OPEN'
CREATE INDEX idx_chargebacks_open 
    ON billing.chargebacks (tenant_id, status) 
    WHERE status = 'OPEN';

-- ==================== RECONCILIATION INDEX'leri ====================

-- Eşleşmemiş kalemleri bulma için
-- Kullanım: SELECT * FROM reconciliation.reconciliation_items WHERE batch_id = ? AND status = 'MISMATCHED'
CREATE INDEX idx_reconciliation_mismatched 
    ON reconciliation.reconciliation_items (batch_id) 
    WHERE status = 'MISMATCHED';

-- ==================== INSTALLMENT INDEX'leri ====================

-- Geciken taksitleri tespit etme için
-- Kullanım: SELECT * FROM billing.installment_payments WHERE status = 'PENDING' AND due_date < CURRENT_DATE
CREATE INDEX idx_installment_due 
    ON billing.installment_payments (status, due_date) 
    WHERE status IN ('PENDING', 'OVERDUE');