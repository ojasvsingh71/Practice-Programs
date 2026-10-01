CREATE TABLE customers (
    customer_id NUMBER PRIMARY KEY,
    customer_name VARCHAR2(50),
    phone VARCHAR2(15)
);



CREATE TABLE accounts (
    account_no NUMBER PRIMARY KEY,
    customer_id NUMBER,
    account_type VARCHAR2(20),
    balance NUMBER(10,2),

    FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id)
);


CREATE TABLE transactions (
    transaction_id NUMBER PRIMARY KEY,
    account_no NUMBER,
    transaction_type VARCHAR2(20),
    amount NUMBER(10,2),
    transaction_date DATE,

    FOREIGN KEY (account_no)
    REFERENCES accounts(account_no)
);


INSERT INTO customers VALUES
(1, 'Rahul Sharma', '9876543210');

INSERT INTO customers VALUES
(2, 'Priya Singh', '9876501234');

INSERT INTO customers VALUES
(3, 'Aman Verma', '9876512345');

COMMIT;


INSERT INTO accounts VALUES
(1001, 1, 'SAVINGS', 25000);

INSERT INTO accounts VALUES
(1002, 2, 'SAVINGS', 15000);

INSERT INTO accounts VALUES
(1003, 3, 'CURRENT', 30000);

COMMIT;



CREATE OR REPLACE PROCEDURE deposit_money (
    p_account_no NUMBER,
    p_amount NUMBER
)
IS
BEGIN

    UPDATE accounts
    SET balance = balance + p_amount
    WHERE account_no = p_account_no;

    INSERT INTO transactions
    VALUES (
        1,
        p_account_no,
        'DEPOSIT',
        p_amount,
        SYSDATE
    );

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Money deposited successfully');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;






CREATE OR REPLACE PROCEDURE withdraw_money (
    p_account_no NUMBER,
    p_amount NUMBER
)
IS
    v_balance NUMBER;
BEGIN

    SELECT balance
    INTO v_balance
    FROM accounts
    WHERE account_no = p_account_no;

    IF v_balance >= p_amount THEN

        UPDATE accounts
        SET balance = balance - p_amount
        WHERE account_no = p_account_no;

        INSERT INTO transactions
        VALUES (
            2,
            p_account_no,
            'WITHDRAW',
            p_amount,
            SYSDATE
        );

        COMMIT;

        DBMS_OUTPUT.PUT_LINE('Money withdrawn successfully');

    ELSE

        DBMS_OUTPUT.PUT_LINE('Insufficient balance');

    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Account not found');

    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);

END;






CREATE OR REPLACE PROCEDURE transfer_money (
    p_from_account NUMBER,
    p_to_account NUMBER,
    p_amount NUMBER
)
IS
    v_balance NUMBER;
BEGIN

    SELECT balance
    INTO v_balance
    FROM accounts
    WHERE account_no = p_from_account;

    IF v_balance >= p_amount THEN

        UPDATE accounts
        SET balance = balance - p_amount
        WHERE account_no = p_from_account;

        UPDATE accounts
        SET balance = balance + p_amount
        WHERE account_no = p_to_account;

        COMMIT;

        DBMS_OUTPUT.PUT_LINE('Money transferred successfully');

    ELSE

        DBMS_OUTPUT.PUT_LINE('Insufficient balance');

    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Account not found');

    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);

END;





CREATE OR REPLACE FUNCTION get_balance (
    p_account_no NUMBER
)
RETURN NUMBER
IS
    v_balance NUMBER;
BEGIN

    SELECT balance
    INTO v_balance
    FROM accounts
    WHERE account_no = p_account_no;

    RETURN v_balance;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END;







CREATE OR REPLACE FUNCTION get_customer_balance (
    p_customer_id NUMBER
)
RETURN NUMBER
IS
    v_total NUMBER;
BEGIN

    SELECT SUM(balance)
    INTO v_total
    FROM accounts
    WHERE customer_id = p_customer_id;

    RETURN NVL(v_total, 0);

END;



CREATE OR REPLACE TRIGGER check_balance
BEFORE UPDATE OF balance
ON accounts
FOR EACH ROW
BEGIN

    IF :NEW.balance < 0 THEN

        DBMS_OUTPUT.PUT_LINE(
            'Balance cannot be negative'
        );

    END IF;

END;



CREATE OR REPLACE TRIGGER transaction_date
BEFORE INSERT
ON transactions
FOR EACH ROW
BEGIN

    :NEW.transaction_date := SYSDATE;

END;




SET SERVEROUTPUT ON;


BEGIN
    deposit_money(1001, 5000);
END;




BEGIN
    withdraw_money(1001, 2000);
END;







BEGIN
    transfer_money(1001, 1002, 3000);
END;





SELECT account_no, balance FROM accounts;



SELECT * FROM transactions;



SELECT get_customer_balance(1) FROM dual;