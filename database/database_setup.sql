-- MoMo SMS Data Processing System
-- Team 4: Moreen Muthoni Murugi & Emna Barezi
-- This script creates our database tables and adds test data

CREATE DATABASE IF NOT EXISTS momo_data;
USE momo_data;

-- Categories of transactions (incoming, outgoing, etc.)
CREATE TABLE Transaction_Categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(200),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- People who send or receive money
CREATE TABLE Users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20) NOT NULL UNIQUE,
    account_type VARCHAR(20) DEFAULT 'personal',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_account_type CHECK (account_type IN ('personal', 'merchant', 'agent'))
);

-- Main transactions table
-- stores every MoMo transaction we parse from the XML file
CREATE TABLE Transactions (
    transaction_id VARCHAR(20) PRIMARY KEY,
    category_id INT NOT NULL,
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
    FOREIGN KEY (category_id) REFERENCES Transaction_Categories(category_id)
);

-- Junction table to handle M:N relationship
-- A transaction can involve multiple users
-- and a user can be in multiple transactions
CREATE TABLE Transaction_Participants (
    id INT PRIMARY KEY AUTO_INCREMENT,
    transaction_id VARCHAR(20) NOT NULL,
    user_id INT NOT NULL,
    role VARCHAR(20) NOT NULL,
    CONSTRAINT chk_role CHECK (role IN ('sender', 'receiver')),
    FOREIGN KEY (transaction_id) REFERENCES Transactions(transaction_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    UNIQUE (transaction_id, user_id, role)
);

-- Logs table to track what happens when we process the XML data
CREATE TABLE System_Logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    transaction_id VARCHAR(20),
    event VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL,
    severity VARCHAR(10) DEFAULT 'info',
    source_file VARCHAR(100) DEFAULT 'momo.xml',
    message TEXT,
    logged_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_log_status CHECK (status IN ('success', 'error', 'warning')),
    CONSTRAINT chk_severity CHECK (severity IN ('info', 'warning', 'critical')),
    FOREIGN KEY (transaction_id) REFERENCES Transactions(transaction_id)
);

-- Indexes to make queries faster
CREATE INDEX idx_transactions_date ON Transactions(transaction_date);
CREATE INDEX idx_transactions_status ON Transactions(status);
CREATE INDEX idx_participants_user ON Transaction_Participants(user_id);
CREATE INDEX idx_logs_status ON System_Logs(status);

-- Adding our test categories
INSERT INTO Transaction_Categories (category_name, description) VALUES
('incoming', 'Money received from another MoMo user'),
('outgoing', 'Money sent to another MoMo user'),
('airtime_payment', 'Payment for airtime or data bundle'),
('withdrawal', 'Cash withdrawal from MoMo agent'),
('bank_deposit', 'Money transferred to a bank account'),
('bundle_purchase', 'Internet or data bundle purchase');

-- Adding test users based on real MoMo messages
INSERT INTO Users (full_name, phone_number, account_type) VALUES
('Jean D Amour Mudaheranwa', '250788****274', 'personal'),
('Valentin Niyokwizerwa', '250792063314', 'personal'),
('Emna Barezi', '250780000000', 'personal'),
('MTN Airtime', '182', 'merchant'),
('Test User Rwanda', '250700000001', 'personal');

-- Adding test transactions from real MoMo SMS messages
INSERT INTO Transactions (transaction_id, category_id, amount, fee, currency, balance_after, status, transaction_date) VALUES
('27846512104', 1, 3000.00, 0.00, 'RWF', 3003.00, 'completed', '2026-05-11 12:31:50'),
('27805517622', 2, 500.00, 20.00, 'RWF', 2483.00, 'completed', '2026-05-15 09:29:01'),
('27846334048', 3, 200.00, 0.00, 'RWF', 3.00, 'completed', '2026-05-11 12:23:01'),
('27805517600', 2, 1000.00, 20.00, 'RWF', 1500.00, 'completed', '2026-05-10 08:15:00'),
('27805517588', 1, 2000.00, 0.00, 'RWF', 3500.00, 'completed', '2026-05-09 14:20:00');

-- Linking users to transactions (M:N junction table)
INSERT INTO Transaction_Participants (transaction_id, user_id, role) VALUES
('27846512104', 1, 'sender'),
('27846512104', 3, 'receiver'),
('27805517622', 3, 'sender'),
('27805517622', 2, 'receiver'),
('27846334048', 3, 'sender'),
('27846334048', 4, 'receiver'),
('27805517600', 3, 'sender'),
('27805517600', 5, 'receiver'),
('27805517588', 5, 'sender'),
('27805517588', 3, 'receiver');

-- Adding logs for each transaction
INSERT INTO System_Logs (transaction_id, event, status, severity, source_file, message) VALUES
('27846512104', 'transaction_processed', 'success', 'info', 'momo.xml', 'Transaction parsed and stored successfully'),
('27805517622', 'transaction_processed', 'success', 'info', 'momo.xml', 'Transaction parsed and stored successfully'),
('27846334048', 'transaction_processed', 'success', 'info', 'momo.xml', 'Transaction parsed and stored successfully'),
('27805517600', 'transaction_processed', 'success', 'info', 'momo.xml', 'Transaction parsed and stored successfully'),
('27805517588', 'transaction_processed', 'success', 'info', 'momo.xml', 'Transaction parsed and stored successfully');

-- Test queries to check everything works

-- Show all transactions with category and participants
SELECT 
    t.transaction_id,
    t.amount,
    t.currency,
    t.fee,
    t.status,
    t.transaction_date,
    c.category_name,
    sender.full_name AS sender_name,
    receiver.full_name AS receiver_name
FROM Transactions t
JOIN Transaction_Categories c ON t.category_id = c.category_id
LEFT JOIN Transaction_Participants sp ON t.transaction_id = sp.transaction_id AND sp.role = 'sender'
LEFT JOIN Users sender ON sp.user_id = sender.user_id
LEFT JOIN Transaction_Participants rp ON t.transaction_id = rp.transaction_id AND rp.role = 'receiver'
LEFT JOIN Users receiver ON rp.user_id = receiver.user_id;

-- Show how much each user received in total
SELECT 
    u.full_name,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(t.amount) AS total_received
FROM Users u
JOIN Transaction_Participants tp ON u.user_id = tp.user_id AND tp.role = 'receiver'
JOIN Transactions t ON tp.transaction_id = t.transaction_id
GROUP BY u.user_id, u.full_name;

-- Check for any errors in the logs
SELECT * FROM System_Logs WHERE status = 'error';

-- Check for any failed transactions
SELECT * FROM Transactions WHERE status = 'failed';