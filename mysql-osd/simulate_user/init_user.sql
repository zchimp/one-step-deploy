-- 创建一个数据库，创建一个用户表，模拟生成10000个用户

CREATE DATABASE IF NOT EXISTS my_database;
USE my_database;
CREATE TABLE IF NOT EXISTS users (
    user_id BIGINT NOT NULL AUTO_INCREMENT,
    address VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    PRIMARY KEY (user_id)
);

DELIMITER //

CREATE PROCEDURE IF NOT EXISTS InsertUsers(IN num_rows INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE random_name VARCHAR(100);
    DECLARE random_address VARCHAR(255);
    DECLARE random_phone VARCHAR(20);
    DECLARE random_gender ENUM('Male', 'Female', 'Other');

    -- Ensure the table is empty before inserting new data (optional)
    -- TRUNCATE TABLE users;

    WHILE i <= num_rows DO
        -- Generate a random name (simplified example)
        SET random_name = CONCAT('Name', FLOOR(RAND() * 1000000));

        -- Generate a random address (simplified example)
        SET random_address = CONCAT('Address', FLOOR(RAND() * 1000), ' Street', FLOOR(RAND() * 100), ' City');

        -- Generate a random phone number (simplified example)
        SET random_phone = CONCAT('+', FLOOR(RAND() * 100 + 1), FLOOR(RAND() * 1000000000));

        -- Generate a random gender
        SET random_gender = ELT(FLOOR(RAND() * 3) + 1, 'Male', 'Female', 'Other');

        -- Insert the generated data into the users table
        INSERT INTO users (address, phone, name, gender) VALUES (random_address, random_phone, random_name, random_gender);

        -- Increment the loop counter
        SET i = i + 1;
    END WHILE;
END //

DELIMITER ;

CALL InsertUsers(10000);
