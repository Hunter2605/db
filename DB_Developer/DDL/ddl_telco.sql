-- =========================================================
-- Telco Customer Churn — Final DDL
-- Source CSV: /mnt/data/WA_Fn-UseC_-Telco-Customer-Churn.csv
-- Use this file to create schema and objects for normalization.
-- Run in MySQL Workbench: open new SQL tab, paste and execute.
-- =========================================================

CREATE DATABASE IF NOT EXISTS telco
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE telco;

-- =========================================================
-- STAGING TABLE (raw CSV import) — keep existing if already present
-- If you already have a table named `telco_staging`, skip creation.
-- The staging table columns mirror the CSV exactly.
-- =========================================================
DROP TABLE IF EXISTS telco_staging;

CREATE TABLE telco_staging (
  customerID VARCHAR(50) PRIMARY KEY,
  gender VARCHAR(10),
  SeniorCitizen TINYINT,
  Partner VARCHAR(10),
  Dependents VARCHAR(10),
  tenure INT,
  PhoneService VARCHAR(30),
  MultipleLines VARCHAR(30),
  InternetService VARCHAR(30),
  OnlineSecurity VARCHAR(30),
  OnlineBackup VARCHAR(30),
  DeviceProtection VARCHAR(30),
  TechSupport VARCHAR(30),
  StreamingTV VARCHAR(30),
  StreamingMovies VARCHAR(30),
  Contract VARCHAR(30),
  PaperlessBilling VARCHAR(10),
  PaymentMethod VARCHAR(80),
  MonthlyCharges DECIMAL(8,2),
  TotalCharges VARCHAR(50),
  Churn VARCHAR(10),
  ImportedAt DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- =========================================================
-- CORE TABLES
-- customers, contracts, billing, services, customer_services
-- =========================================================

-- CUSTOMERS
DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
  customer_id VARCHAR(50) PRIMARY KEY,
  gender VARCHAR(10),
  senior_citizen TINYINT,
  partner BOOLEAN,
  dependents BOOLEAN,
  tenure INT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_customers_tenure (tenure)
) ENGINE=InnoDB;

-- CONTRACTS (dictionary)
DROP TABLE IF EXISTS contracts;
CREATE TABLE contracts (
  contract_id INT AUTO_INCREMENT PRIMARY KEY,
  contract_type VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- BILLING (current billing snapshot)
DROP TABLE IF EXISTS billing;
CREATE TABLE billing (
  billing_id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id VARCHAR(50) NOT NULL,
  monthly_charges DECIMAL(8,2),
  total_charges DECIMAL(12,2),
  paperless_billing BOOLEAN,
  payment_method VARCHAR(80),
  last_updated DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
  INDEX idx_billing_customer (customer_id),
  INDEX idx_billing_monthly_total (monthly_charges, total_charges)
) ENGINE=InnoDB;

-- SERVICES (dictionary)
DROP TABLE IF EXISTS services;
CREATE TABLE services (
  service_id INT AUTO_INCREMENT PRIMARY KEY,
  service_name VARCHAR(100) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- CUSTOMER_SERVICES (normalized feature flags)
DROP TABLE IF EXISTS customer_services;
CREATE TABLE customer_services (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  customer_id VARCHAR(50) NOT NULL,
  service_id INT NOT NULL,
  service_value VARCHAR(80),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
  FOREIGN KEY (service_id) REFERENCES services(service_id) ON DELETE CASCADE,
  UNIQUE KEY uq_customer_service (customer_id, service_id),
  INDEX idx_cs_customer (customer_id),
  INDEX idx_cs_service (service_id)
) ENGINE=InnoDB;

-- =========================================================
-- OPTIONAL: materialized-like helper tables or small lookups
-- (kept as CREATE TABLE ... SELECT when needed via ETL)
-- =========================================================

-- =========================================================
-- SAMPLE INSERTS INTO services (idempotent)
-- Run once after creating tables (or keep in a separate script)
-- =========================================================
INSERT IGNORE INTO services (service_name) VALUES
('PhoneService'),
('MultipleLines'),
('InternetService'),
('OnlineSecurity'),
('OnlineBackup'),
('DeviceProtection'),
('TechSupport'),
('StreamingTV'),
('StreamingMovies');

-- =========================================================
-- RECOMMENDED INDEXES (add after bulk-load)
-- =========================================================
ALTER TABLE telco_staging ADD INDEX idx_staging_contract_payment_churn (Contract, PaymentMethod, Churn);
ALTER TABLE telco_staging ADD INDEX idx_staging_tenure (tenure);
ALTER TABLE customers ADD INDEX idx_customers_created (created_at);

-- =========================================================
-- ANALYTICAL VIEWs (optional, considered part of DDL)
-- =========================================================
DROP VIEW IF EXISTS view_churn_overview;
CREATE VIEW view_churn_overview AS
SELECT s.customerID AS customer_id,
       c.tenure,
       b.monthly_charges,
       b.total_charges,
       s.Contract AS contract_type,
       s.PaymentMethod AS payment_method,
       s.Churn AS churn
FROM telco_staging s
LEFT JOIN customers c ON c.customer_id = s.customerID
LEFT JOIN billing b ON b.customer_id = s.customerID;

DROP VIEW IF EXISTS view_service_counts;
CREATE VIEW view_service_counts AS
SELECT cs.customer_id,
       SUM(CASE WHEN cs.service_value IN ('Yes','DSL','Fiber optic') THEN 1 ELSE 0 END) AS active_services_count
FROM customer_services cs
GROUP BY cs.customer_id;

DROP VIEW IF EXISTS view_churn_by_segment;
CREATE VIEW view_churn_by_segment AS
SELECT COALESCE(c.tenure, -1) AS tenure_bucket,
       COALESCE(b.payment_method, 'Unknown') AS payment_method,
       s.Contract AS contract_type,
       COUNT(*) AS total_customers,
       SUM(CASE WHEN s.Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
       ROUND(100 * SUM(CASE WHEN s.Churn = 'Yes' THEN 1 ELSE 0 END)/COUNT(*),2) AS churn_rate
FROM telco_staging s
LEFT JOIN customers c ON c.customer_id = s.customerID
LEFT JOIN billing b ON b.customer_id = s.customerID
GROUP BY tenure_bucket, payment_method, contract_type;

-- =========================================================
-- End of DDL
-- =========================================================
