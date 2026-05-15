-- =====================================================
-- MoMo SMS Data Processing System - Database Setup
-- Team 4: Moreen Muthoni Murugi & Emna Barezi
-- =====================================================

-- Create Transaction_Categories table first
-- because Transactions will reference it
CREATE TABLE Transaction_Categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(200),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_category_name CHECK (category_name IN (
        'incoming', 'outgoing', 'airtime_payment', 
        'withdrawal', 'bank_deposit', 'bundle_purchase'
    ))
);

-- Create Users table
-- stores all people who send or receive money
CREATE TABLE Users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    account_type VARCHAR(20) DEFAULT 'personal',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_account_type CHECK (account_type IN ('personal', 'merchant', 'agent'))
);

-- Create Transactions table
-- stores every MoMo transaction parsed from XML
CREATE TABLE Transactions (
    transaction_id VARCHAR(20) PRIMARY KEY,
    category_id INT NOT NULL,
    sender_id INT,
    receiver_id INT,
    amount DECIMAL(15, 2) NOT NULL,
    fee DECIMAL(15, 2) DEFAULT 0.00,
    currency VARCHAR(5) DEFAULT 'RWF',
    balance_after DECIMAL(15, 2),
    status VARCHAR(20) DEFAULT 'completed',
    transaction_date DATETIME NOT NULL,
    message TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_amount CHECK (amount > 0),
    CONSTRAINT chk_fee CHECK (fee >= 0),
    CONSTRAINT chk_status CHECK (status IN ('completed', 'failed', 'pending')),
    FOREIGN KEY (category_id) REFERENCES Transaction_Categories(category_id),
    FOREIGN KEY (sender_id) REFERENCES Users(user_id),
    FOREIGN KEY (receiver_id) REFERENCES Users(user_id)
);

-- Create System_Logs table
-- tracks every time a transaction is processed
CREATE TABLE System_Logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    transaction_id VARCHAR(20),
    event VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL,
    message TEXT,
    logged_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_log_status CHECK (status IN ('success', 'error', 'warning')),
    FOREIGN KEY (transaction_id) REFERENCES Transactions(transaction_id)
);

-- =====================================================
-- INDEXES for better query performance
-- =====================================================
CREATE INDEX idx_transactions_date ON Transactions(transaction_date);
CREATE INDEX idx_transactions_sender ON Transactions(sender_id);
CREATE INDEX idx_transactions_receiver ON Transactions(receiver_id);
CREATE INDEX idx_logs_transaction ON System_Logs(transaction_id);

-- =====================================================
-- SAMPLE DATA - based on real MoMo SMS messages
-- =====================================================

-- Insert categories
INSERT INTO Transaction_Categories (category_name, description) VALUES
('incoming', 'Money received from another MoMo user'),
('outgoing', 'Money sent to another MoMo user'),
('airtime_payment', 'Payment for airtime or data bundle'),
('withdrawal', 'Cash withdrawal from MoMo agent'),
('bank_deposit', 'Money transferred to bank account');

-- Insert users
INSERT INTO Users (full_name, phone_number, account_type) VALUES
('Jean D Amour Mudaheranwa', '250788****274', 'personal'),
('Valentin Niyokwizerwa', '250792063314', 'personal'),
('Emna Barezi', '250780000000', 'personal'),
('MTN Airtime', '182', 'merchant'),
('Test User', '250700000001', 'personal');

-- Insert transactions
INSERT INTO Transactions (transaction_id, category_id, sender_id, receiver_id, amount, fee, currency, balance_after, status, transaction_date) VALUES
('27846512104', 1, 1, 3, 3000.00, 0.00, 'RWF', 3003.00, 'completed', '2026-05-11 12:31:50'),
('27805517622', 2, 3, 2, 500.00, 20.00, 'RWF', 2483.00, 'completed', '2026-05-15 09:29:01'),
('27846334048', 3, 3, 4, 200.00, 0.00, 'RWF', 3.00, 'completed', '2026-05-11 12:23:01'),
('27805517600', 2, 3, 5, 1000.00, 20.00, 'RWF', 1500.00, 'completed', '2026-05-10 08:15:00'),
('27805517588', 1, 5, 3, 2000.00, 0.00, 'RWF', 3500.00, 'completed', '2026-05-09 14:20:00');

-- Insert system logs
INSERT INTO System_Logs (transaction_id, event, status, message) VALUES
('27846512104', 'transaction_processed', 'success', 'Transaction parsed and stored successfully'),
('27805517622', 'transaction_processed', 'success', 'Transaction parsed and stored successfully'),
('27846334048', 'transaction_processed', 'success', 'Transaction parsed and stored successfully'),
('27805517600', 'transaction_processed', 'success', 'Transaction parsed and stored successfully'),
('27805517588', 'transaction_processed', 'success', 'Transaction parsed and stored successfully');

-- =====================================================
-- SAMPLE QUERIES to test the database
-- =====================================================

-- Get all transactions with sender and receiver names
SELECT 
    t.transaction_id,
    t.amount,
    t.currency,
    t.fee,
    t.status,
    t.transaction_date,
    c.category_name,
    s.full_name AS sender_name,
    r.full_name AS receiver_name
FROM Transactions t
JOIN Transaction_Categories c ON t.category_id = c.category_id
LEFT JOIN Users s ON t.sender_id = s.user_id
LEFT JOIN Users r ON t.receiver_id = r.user_id;

-- Get total amount received by each user
SELECT 
    u.full_name,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(t.amount) AS total_received
FROM Users u
JOIN Transactions t ON u.user_id = t.receiver_id
GROUP BY u.user_id, u.full_name;

-- Get all failed transactions
SELECT * FROM Transactions WHERE status = 'failed';

-- Get transaction logs with errors
SELECT * FROM System_Logs WHERE status = 'error';
