-- ============================================
-- PARA TRANSFERİ PROSEDÜRÜ
-- Amaç: İki cüzdan arasında güvenli para transferi yapmak
-- ============================================

CREATE OR REPLACE FUNCTION payment.sp_transfer_money( -- payment şeması için sp_tansfer_mooney fonksiyonu olusturmak ıstıyoruz
    p_sender_wallet_id UUID,   -- Gelmesini beklediğimiz verilerden p_sender_wallet_id uuid tipinde
    p_receiver_wallet_id UUID,  -- Gelmesini beklediğimiz verilerden
    p_amount NUMERIC, -- Gelmesini beklediğimiz verilerden
    p_currency CHAR(3), -- Gelmesini beklediğimiz verilerden
    p_description TEXT DEFAULT NULL  -- Gelmesini beklediğimiz verilerden
) RETURNS UUID AS $$ -- Fonksiyonun dönüş tipi UUID olacak
DECLARE
    v_tenant_id UUID; -- v_tenant_id değişkeni oluşturduk  UUID tipinde olacak tenant_id'yi tutacak 
    v_sender_balance NUMERIC(20,2); -- v_sender_balance  değişkeni oluşturduk gönderilen cüzdanın bakiyesini tutacak NUMERIC(20,2) tipinde olacak
    v_transfer_id UUID;  -- v_transfer_id değişkeni oluşturduk transfer kaydının id'sini tutacak UUID tipinde olacak
BEGIN
    -- 1. Gönderen cüzdanın tenant_id'sini al ve cüzdanı kilitle
    SELECT tenant_id, balance -- 
    INTO v_tenant_id, v_sender_balance -- tenand_id ye : v_tenant_id değişkenini atayacagız | `balance`'a `v_sender_balance` değişkenini atayacagız 
    FROM wallet.customer_wallets  -- wallet schemasından customer_wallets tablosu 
    WHERE id = p_sender_wallet_id   -- para transferi yapacak olan cuzdanın id si
    FOR UPDATE;  -- Satır kilidi (Pessimistic Locking) > guncelleme için satırı kilitlemek için kullanılır. Bu, aynı anda başka bir işlem tarafından güncellenmesini önler ve veri tutarlılığını sağlar.

    -- 2. Bakiye kontrolü
    IF v_sender_balance < p_amount THEN 
        RAISE EXCEPTION 'Yetersiz bakiye: %', v_sender_balance; -- raise exception ile Yetersiz bakiye ve bakiye miktarını göztererek hata fırlatıyorıuz
    END IF;

    -- 3. Transfer kaydını oluştur
    INSERT INTO payment.transfers (  -- payments şemasından transfers tablosuna veri ekliyoruz  
        tenant_id, 
        sender_wallet_id, 
        receiver_wallet_id, 
        amount, 
        currency, 
        status
    ) VALUES (
        v_tenant_id, -- gönderilen cüzdanın tenant_id'si
        p_sender_wallet_id, -- `payment.transfers` tablosuna gönderilen cüzdanın id'si
        p_receiver_wallet_id, -- `payment.transfers` tablosuna alıcı cüzdanın id'si
        p_amount, -- `payment.transfers` tablosuna transfer edilecek miktar
        p_currency, -- `payment.transfers` tablosuna transfer edilecek para birimi
        'COMPLETED'
    ) RETURNING id INTO v_transfer_id; -- işlem gerçekleştikten sonra transfer kaydının id'sini v_transfer_id değişkenine atıyoruz

    -- 4. Gönderen cüzdandan düş (DEBIT)
    UPDATE wallet.customer_wallets -- 
    SET balance = balance - p_amount,
        version = version + 1,
        updated_at = now()
    WHERE id = p_sender_wallet_id;

    -- 5. Alıcı cüzdana ekle (CREDIT)
    UPDATE wallet.customer_wallets
    SET balance = balance + p_amount,
        version = version + 1,
        updated_at = now()
    WHERE id = p_receiver_wallet_id;

    -- 6. Ledger kayıtları (Defter)
    INSERT INTO wallet.wallet_ledger (
        wallet_id, 
        tenant_id, 
        transaction_id, 
        entry_type, 
        amount, 
        running_balance,
        description
    ) VALUES (
        p_sender_wallet_id,
        v_tenant_id,
        v_transfer_id,
        'DEBIT',
        p_amount,
        (SELECT balance FROM wallet.customer_wallets WHERE id = p_sender_wallet_id),
        p_description
    );

    INSERT INTO wallet.wallet_ledger (
        wallet_id, 
        tenant_id, 
        transaction_id, 
        entry_type, 
        amount, 
        running_balance,
        description
    ) VALUES (
        p_receiver_wallet_id,
        v_tenant_id,
        v_transfer_id,
        'CREDIT',
        p_amount,
        (SELECT balance FROM wallet.customer_wallets WHERE id = p_receiver_wallet_id),
        p_description
    );

    RETURN v_transfer_id;
END;
$$ LANGUAGE plpgsql;