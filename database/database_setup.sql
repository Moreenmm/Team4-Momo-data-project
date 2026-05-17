-- MoMo SMS Database Setup
-- Team 4: Moreen Muthoni Murugi & Emna Barezi

-- categories come first because transactions need them
CREATE TABLE Transaction_Categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT COMMENT 'unique ID for each category',
    category_name VARCHAR(50) NOT NULL UNIQUE COMMENT 'type of transaction e.g incoming or outgoing',
    description VARCHAR(200) COMMENT 'explains what this category means',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'when this category was added',
    CONSTRAINT chk_category_name CHECK (category_name IN (
        'incoming', 'outgoing', 'airtime_payment', 
        'withdrawal', 'bank_deposit', 'bundle_purchase'
    ))
);

-- people who send or receive money
CREATE TABLE Users (
    user_id INT PRIMARY KEY AUTO_INCREMENT COMMENT 'unique ID for each user',
    full_name VARCHAR(100) NOT NULL COMMENT 'full name of the user',
    phone_number VARCHAR(20) NOT NULL UNIQUE COMMENT 'phone number used for MoMo',
    account_type VARCHAR(20) DEFAULT 'personal' COMMENT 'personal, merchant or agent',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'when this user was added',
    CONSTRAINT chk_account_type CHECK (account_type IN ('personal', 'merchant', 'agent'))
);

-- the actual transactions from the XML file
CREATE TABLE Transactions (
    transaction_id VARCHAR(20) PRIMARY KEY COMMENT 'unique transaction ID from the SMS',
    category_id INT NOT NULL COMMENT 'links to Transaction_Categories table',
    sender_id INT COMMENT 'the user who sent the money',
    receiver_id INT COMMENT 'the user who received the money',
    amount DECIMAL(15, 2) NOT NULL COMMENT 'how much money was transferred in RWF',
    fee DECIMAL(15, 2) DEFAULT 0.00 COMMENT 'transaction fee charged by MoMo',
    currency VARCHAR(5) DEFAULT 'RWF' COMMENT 'currency used, always RWF for Rwanda',
    balance_after DECIMAL(15, 2) COMMENT 'account balance after the transaction',
    status VARCHAR(20) DEFAULT 'completed' COMMENT 'completed, failed or pending',
    transaction_date DATETIME NOT NULL COMMENT 'date and time the transaction happened',
    message TEXT COMMENT 'original SMS message text',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'when this record was inserted',
    CONSTRAINT chk_amount CHECK (amount > 0),
    CONSTRAINT chk_fee CHECK (fee >= 0),
    CONSTRAINT chk_status CHECK (status IN ('completed', 'failed', 'pending')),
    FOREIGN KEY (category_id) REFERENCES Transaction_Categories(category_id),
    FOREIGN KEY (sender_id) REFERENCES Users(user_id),
    FOREIGN KEY (receiver_id) REFERENCES Users(user_id)
);

-- logs to track what happened during processing
CREATE TABLE System_Logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT COMMENT 'unique ID for each log entry',
    transaction_id VARCHAR(20) COMMENT 'which transaction this log is about',
    event VARCHAR(50) NOT NULL COMMENT 'what happened e.g transaction_processed',
    status VARCHAR(20) NOT NULL COMMENT 'success, error or warning',
    message TEXT COMMENT 'more details about what happened',
    logged_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'when this log was created',
    CONSTRAINT chk_log_status CHECK (status IN ('success', 'error', 'warning')),
    FOREIGN KEY (transaction_id) REFERENCES Transactions(transaction_id)
);

-- this links transactions to users (many to many)
-- one transaction can have multiple people involved
-- one person can be in many transactions
CREATE TABLE Transaction_User_Links (
    link_id INT PRIMARY KEY AUTO_INCREMENT COMMENT 'unique ID for each link',
    transaction_id VARCHAR(20) NOT NULL COMMENT 'which transaction this is',
    user_id INT NOT NULL COMMENT 'which user is involved',
    role VARCHAR(20) NOT NULL COMMENT 'what role they played: sender, receiver or agent',
    CONSTRAINT chk_role CHECK (role IN ('sender', 'receiver', 'agent')),
    FOREIGN KEY (transaction_id) REFERENCES Transactions(transaction_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    UNIQUE KEY uq_tx_user_role (transaction_id, user_id, role)
);

-- indexes to make queries faster
CREATE INDEX idx_transactions_date ON Transactions(transaction_date);
CREATE INDEX idx_transactions_sender ON Transactions(sender_id);
CREATE INDEX idx_transactions_receiver ON Transactions(receiver_id);
CREATE INDEX idx_logs_transaction ON System_Logs(transaction_id);
CREATE INDEX idx_links_transaction ON Transaction_User_Links(transaction_id);
CREATE INDEX idx_links_user ON Transaction_User_Links(user_id);

-- adding the category types
INSERT INTO Transaction_Categories (category_name, description) VALUES
('incoming', 'Money received from another MoMo user'),
('outgoing', 'Money sent to another MoMo user'),
('airtime_payment', 'Payment for airtime or data bundle'),
('withdrawal', 'Cash withdrawal from MoMo agent'),
('bank_deposit', 'Money transferred to bank account');

-- adding the users we found in the XML data
INSERT INTO Users (full_name, phone_number, account_type) VALUES
('Jean D Amour Mudaheranwa', '250788****274', 'personal'),
('Valentin Niyokwizerwa', '250792063314', 'personal'),
('Emna Barezi', '250780000000', 'personal'),
('MTN Airtime', '182', 'merchant'),
('Test User', '250700000001', 'personal');

-- adding 5 real transactions from our XML file
INSERT INTO Transactions (transaction_id, category_id, sender_id, receiver_id, amount, fee, currency, balance_after, status, transaction_date) VALUES
('27846512104', 1, 1, 3, 3000.00, 0.00, 'RWF', 3003.00, 'completed', '2026-05-11 12:31:50'),
('27805517622', 2, 3, 2, 500.00, 20.00, 'RWF', 2483.00, 'completed', '2026-05-15 09:29:01'),
('27846334048', 3, 3, 4, 200.00, 0.00, 'RWF', 3.00, 'completed', '2026-05-11 12:23:01'),
('27805517600', 2, 3, 5, 1000.00, 20.00, 'RWF', 1500.00, 'completed', '2026-05-10 08:15:00'),
('27805517588', 1, 5, 3, 2000.00, 0.00, 'RWF', 3500.00, 'completed', '2026-05-09 14:20:00');

-- logging each transaction as processed
INSERT INTO System_Logs (transaction_id, event, status, message) VALUES
('27846512104', 'transaction_processed', 'success', 'Transaction parsed and stored successfully'),
('27805517622', 'transaction_processed', 'success', 'Transaction parsed and stored successfully'),
('27846334048', 'transaction_processed', 'success', 'Transaction parsed and stored successfully'),
('27805517600', 'transaction_processed', 'success', 'Transaction parsed and stored successfully'),
('27805517588', 'transaction_processed', 'success', 'Transaction parsed and stored successfully');

-- linking users to their transactions and their role
INSERT INTO Transaction_User_Links (transaction_id, user_id, role) VALUES
('27846512104', 1, 'sender'),
('27846512104', 3, 'receiver'),
('27805517622', 3, 'sender'),
('27805517622', 2, 'receiver'),
('27846334048', 3, 'sender'),
('27846334048', 4, 'receiver'),
('27805517600', 3, 'sender'),
('27805517588', 5, 'sender');

-- show all transactions with names instead of IDs
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

-- how much each user received in total
SELECT 
    u.full_name,
    COUNT(t.transaction_id) AS total_transactions,
    SUM(t.amount) AS total_received
FROM Users u
JOIN Transactions t ON u.user_id = t.receiver_id
GROUP BY u.user_id, u.full_name;

-- check for any failed transactions
SELECT * FROM Transactions WHERE status = 'failed';

-- check for any errors in the logs
SELECT * FROM System_Logs WHERE status = 'error';

-- see who was involved in each transaction and their role
SELECT 
    tul.transaction_id,
    u.full_name,
    u.phone_number,
    tul.role
FROM Transaction_User_Links tul
JOIN Users u ON tul.user_id = u.user_id
ORDER BY tul.transaction_id;
