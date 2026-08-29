-- V7: Seed Data - Para Birimleri
-- Amaç: Anayasadaki Modül 7: Kur Yönetimi bölümünde belirtilen para birimlerini ekle
-- Anayasa Referansı: Modül 7: Kur Yönetimi

-- ==================== PARA BİRİMLERİ ====================

INSERT INTO core.currencies (code, name, symbol, decimal_places) VALUES
    ('TRY', 'Türk Lirası', '₺', 2),
    ('USD', 'US Dollar', '$', 2),
    ('EUR', 'Euro', '€', 2),
    ('GBP', 'British Pound', '£', 2);

-- ==================== DÖVİZ KURLARI ====================

-- Güncel kurlar (1 birim bazında)
INSERT INTO core.currency_rates (base_currency, target_currency, rate) VALUES
    ('USD', 'TRY', 35.20),
    ('EUR', 'TRY', 38.50),
    ('GBP', 'TRY', 45.80),
    ('EUR', 'USD', 1.09),
    ('GBP', 'USD', 1.30),
    ('USD', 'EUR', 0.92),
    ('USD', 'GBP', 0.77);

    INSERT INTO core.currency_rate_history (rate_id, rate) 
SELECT id, rate FROM core.currency_rates 
WHERE base_currency = 'USD' AND target_currency = 'TRY';