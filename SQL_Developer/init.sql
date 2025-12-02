CREATE DATABASE IF NOT EXISTS telco_churn
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE telco_churn;

CREATE TABLE Customers (
    customerID     VARCHAR(20) NOT NULL PRIMARY KEY,
    gender         VARCHAR(10) NOT NULL,
    SeniorCitizen  INT         NOT NULL DEFAULT 0,
    Partner        VARCHAR(5)  NOT NULL,
    Dependents     VARCHAR(5)  NOT NULL,
    tenure         INT         NOT NULL DEFAULT 0
);

CREATE TABLE PhoneService (
    customerID     VARCHAR(20) NOT NULL PRIMARY KEY,
    PhoneService   VARCHAR(20) NOT NULL,
    MultipleLines  VARCHAR(30) NOT NULL,
    CONSTRAINT fk_phoneservice_customer
        FOREIGN KEY (customerID)
        REFERENCES Customers(customerID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE InternetService (
    customerID        VARCHAR(20) NOT NULL PRIMARY KEY,
    InternetService   VARCHAR(30) NOT NULL,
    OnlineSecurity    VARCHAR(30) NOT NULL,
    OnlineBackup      VARCHAR(30) NOT NULL,
    DeviceProtection  VARCHAR(30) NOT NULL,
    TechSupport       VARCHAR(30) NOT NULL,
    StreamingTV       VARCHAR(30) NOT NULL,
    StreamingMovies   VARCHAR(30) NOT NULL,
    CONSTRAINT fk_internetservice_customer
        FOREIGN KEY (customerID)
        REFERENCES Customers(customerID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Contract (
    customerID       VARCHAR(20) NOT NULL PRIMARY KEY,
    Contract         VARCHAR(30) NOT NULL,
    PaperlessBilling VARCHAR(5)  NOT NULL,
    CONSTRAINT fk_contract_customer
        FOREIGN KEY (customerID)
        REFERENCES Customers(customerID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Payment (
    customerID      VARCHAR(20)   NOT NULL PRIMARY KEY,
    PaymentMethod   VARCHAR(50)   NOT NULL,
    MonthlyCharges  DECIMAL(10,2) NOT NULL,
    TotalCharges    DECIMAL(10,2) NULL,
    CONSTRAINT fk_payment_customer
        FOREIGN KEY (customerID)
        REFERENCES Customers(customerID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE Churn (
    customerID  VARCHAR(20) NOT NULL PRIMARY KEY,
    Churn       VARCHAR(5)  NOT NULL,
    CONSTRAINT fk_churn_customer
        FOREIGN KEY (customerID)
        REFERENCES Customers(customerID)
        ON DELETE CASCADE
        ON UPDATE CASCADE
