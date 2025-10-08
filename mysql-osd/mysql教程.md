# 数据库表
## 创建数据库
```
CREATE DATABASE IF NOT EXISTS <database_name>
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;
```
## 删除数据库
```
DROP DATABASE [IF EXISTS] <database_name>;
```
## 创建数据表
```
CREATE TABLE IF NOT EXISTS table_name (
`id` INT UNSIGNED AUTO_INCREMENT,
`title` VARCHAR(100) NOT NULL,
`author` VARCHAR(40) NOT NULL,
`submission_date` DATE,
PRIMARY KEY ( `id` )
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```
## 删除数据表
```
DROP TABLE [IF EXISTS] table_name;
```
# 数据操作
## 插入数据
```
INSERT INTO users (username, email, birthdate, is_active)
VALUES
 ('test1', 'test1@outlook.com', '1985-07-10', true),
 ('test2', 'test2@outlook.com', '1988-11-25', false),
 ('test3', 'test3@outlook.com', '1993-05-03', true);
```
## 查询数据
```
SELECT column1, column2, ...
FROM table_name
[WHERE condition]
[ORDER BY column_name [ASC | DESC]]
[LIMIT number];
```
```
-- 案例
-- 选择所有列的所有行
SELECT * FROM users;

-- 选择特定列的所有行
SELECT username, email FROM users;

-- 添加 WHERE 子句，选择满足条件的行
SELECT * FROM users WHERE is_active = TRUE;

-- 添加 ORDER BY 子句，按照某列的升序排序
SELECT * FROM users ORDER BY birthdate;

-- 添加 ORDER BY 子句，按照某列的降序排序
SELECT * FROM users ORDER BY birthdate DESC;

-- 添加 LIMIT 子句，限制返回的行数
SELECT * FROM users LIMIT 10;

-- 使用 AND 运算符和通配符
SELECT * FROM users WHERE username LIKE 'j%' AND is_active = TRUE;

-- 使用 OR 运算符
SELECT * FROM users WHERE is_active = TRUE OR birthdate < '1990-01-01';

-- 使用 IN 子句
SELECT * FROM users WHERE birthdate IN ('1990-01-01', '1992-03-15', '1993-05-03');
```

# WHERE子句
```
-- 等于条件
SELECT * FROM users WHERE username = 'test';

-- 不等于条件
SELECT * FROM users WHERE username != 'runoob';

-- 大于条件
SELECT * FROM products WHERE price > 50.00;

-- 小于条件
SELECT * FROM orders WHERE order_date < '2023-01-01';

-- 大于等于条件
SELECT * FROM employees WHERE salary >= 50000;

-- 小于等于条件
SELECT * FROM students WHERE age <= 21;

-- 组合条件（AND、OR）
SELECT * FROM products WHERE category = 'Electronics' AND price > 100.00;

SELECT * FROM orders WHERE order_date >= '2023-01-01' OR total_amount > 1000.00;

-- 模糊匹配条件（LIKE）
SELECT * FROM customers WHERE first_name LIKE 'J%';

-- IN 条件
SELECT * FROM countries WHERE country_code IN ('US', 'CA', 'MX');

-- NOT 条件
SELECT * FROM products WHERE NOT category = 'Clothing';

-- BETWEEN 条件
SELECT * FROM orders WHERE order_date BETWEEN '2023-01-01' AND '2023-12-31';

-- IS NULL 条件
SELECT * FROM employees WHERE department IS NULL;

-- IS NOT NULL 条件
SELECT * FROM customers WHERE email IS NOT NULL;
```

# UPDATE更新
```
-- 更新多个列的值
UPDATE orders
SET status = 'Shipped', ship_date = '2023-03-01'
WHERE order_id = 1001;

-- 更新使用子查询的值
UPDATE customers
SET total_purchases = (
 SELECT SUM(amount)
 FROM orders
 WHERE orders.customer_id = customers.customer_id
)
WHERE customer_type = 'Premium';
```

# DELETE语句
```
-- 删除符合条件的行
DELETE FROM students
WHERE graduation_year = 2021;

-- 结合子查询
DELETE FROM customers
WHERE customer_id IN (
 SELECT customer_id
 FROM orders
 WHERE order_date < '2023-01-01'
);
```

# LIKE子句
```
-- 分号通配符 % 表示零个或多个字符。例如，'a%' 匹配以字母 'a' 开头的任何字符串
SELECT * FROM customers WHERE last_name LIKE 'S%';

-- 下划线通配符 _ 表示一个字符。例如，'_r%' 匹配第二个字母为 'r' 的任何字符串。
SELECT * FROM products WHERE product_name LIKE '_a%';

-- 默认情况下，mysql like不区分大小写
-- 不区分大小写进行匹配
SELECT * FROM employees WHERE last_name LIKE 'smi%' COLLATE utf8mb4_general_ci;

-- 区分大小写进行匹配
SELECT * FROM employees WHERE BINARY last_name LIKE 'smi%';
```

# UNION 操作符
连接两个以上的 SELECT 语句的结果组合到一个结果集合，并去除重复的行  
```
-- 基本的 UNION 操作
SELECT city FROM customers WHERE category = 'Electronics'
UNION
SELECT city FROM suppliers WHERE category = 'Clothing'
ORDER BY city;

-- UNION 操作中的列数和数据类型必须相同
SELECT first_name, last_name FROM employees
UNION
SELECT department_name, NULL FROM departments
ORDER BY first_name;

-- 使用 UNION ALL 不去除重复行
SELECT city FROM customers
UNION ALL
SELECT city FROM suppliers
ORDER BY city;
```

# ORDER BY语句
```
-- 多列排序
SELECT * FROM employees
ORDER BY department_id ASC, hire_date DESC;

-- 使用数字表示列位置
SELECT first_name, last_name, salary
FROM employees
ORDER BY 3 DESC, 1 ASC;

-- 使用表达式排序
SELECT product_name, price * discount_rate AS discounted_price
FROM products
ORDER BY discounted_price DESC;

-- 从 MySQL 8.0.16 版本开始，可以使用 NULLS FIRST 或 NULLS LAST 处理 NULL 值
-- NULL值排在前面
SELECT product_name, price
FROM products
ORDER BY price DESC NULLS LAST;
```

# GROUP BY分组
初始化数据。
```
SET NAMES utf8;
SET FOREIGN_KEY_CHECKS = 0;
-- ----------------------------
--  Table structure for `employee_tbl`
-- ----------------------------
DROP TABLE IF EXISTS `employee_tbl`;
CREATE TABLE `employee_tbl` (
  `id` INT(11) NOT NULL,
  `name` CHAR(10) NOT NULL DEFAULT '',
  `date` datetime NOT NULL,
  `signin` tinyint(4) NOT NULL DEFAULT '0' COMMENT '登录次数',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
-- ----------------------------
--  Records of `employee_tbl`
-- ----------------------------
BEGIN;
INSERT INTO `employee_tbl` VALUES ('1', '小明', '2016-04-22 15:25:33', '1'), ('2', '小王', '2016-04-20 15:25:47', '3'), ('3', '小丽', '2016-04-19 15:26:02', '2'), ('4', '小王', '2016-04-07 15:26:14', '4'), ('5', '小明', '2016-04-11 15:26:40', '4'), ('6', '小明', '2016-04-04 15:26:54', '2');
COMMIT;
SET FOREIGN_KEY_CHECKS = 1;
```
| id | name | date | signin |  
| :----- | :---- | :---- | :-----: |
| 1 | 小明 | 2016-04-22 15:25:33 | 1 |  
| 2 | 小王 | 2016-04-20 15:25:47 | 3 |  
| 3 | 小丽 | 2016-04-19 15:26:02 | 2 |  
| 4 | 小王 | 2016-04-07 15:26:14 | 4 |  
| 5 | 小明 | 2016-04-11 15:26:40 | 4 |  
| 6 | 小明 | 2016-04-04 15:26:54 | 2 |  

```
SELECT name, COUNT(*) FROMemployee_tbl GROUP BY name;
```
| id | COUNT(*) |
| :----- | :----: |
| 小明 | 3 |
| 小王 | 2 |
| 小丽 | 1 |
## 用WITH ROLLUP在统计数据的基础上再次统计
```
SELECT coalesce(name, '总数'), SUM(signin) as signin_count FROM  employee_tbl GROUP BY name WITH ROLLUP;
```
| id | signin_count |
| :----- | :----: |
| 小明 | 7 |
| 小王 | 7 |
| 小丽 | 2 |
| 总数 | 16 |


# MySQL连接使用
INNER JOIN（内连接,或等值连接）：获取两个表中字段匹配关系的记录。  
LEFT JOIN（左连接）：获取左表所有记录，即使右表没有对应匹配的记录。  
RIGHT JOIN（右连接）： 与 LEFT JOIN 相反，用于获取右表所有记录，即使左表没有对应匹配的记录。  
### 初始化数据
```
SET NAMES utf8;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
--  Table structure for `runoob_tbl`
-- ----------------------------
DROP TABLE IF EXISTS `runoob_tbl`;
CREATE TABLE `runoob_tbl` (
  `runoob_id` int(11) NOT NULL AUTO_INCREMENT,
  `runoob_title` varchar(100) NOT NULL,
  `runoob_author` varchar(40) NOT NULL,
  `submission_date` date DEFAULT NULL,
  PRIMARY KEY (`runoob_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;

-- ----------------------------
--  Records of `runoob_tbl`
-- ----------------------------
BEGIN;
INSERT INTO `runoob_tbl` VALUES ('1', '学习 PHP', '菜鸟教程', '2017-04-12'), ('2', '学习 MySQL', '菜鸟教程', '2017-04-12'), ('3', '学习 Java', 'RUNOOB.COM', '2015-05-01'), ('4', '学习 Python', 'RUNOOB.COM', '2016-03-06'), ('5', '学习 C', 'FK', '2017-04-05');
COMMIT;

-- ----------------------------
--  Table structure for `tcount_tbl`
-- ----------------------------
DROP TABLE IF EXISTS `tcount_tbl`;
CREATE TABLE `tcount_tbl` (
  `runoob_author` varchar(255) NOT NULL DEFAULT '',
  `runoob_count` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
--  Records of `tcount_tbl`
-- ----------------------------
BEGIN;
INSERT INTO `tcount_tbl` VALUES ('菜鸟教程', '10'), ('RUNOOB.COM ', '20'), ('Google', '22');
COMMIT;

SET FOREIGN_KEY_CHECKS = 1;
```
| runoob_author | runoob_count |
| :--- | :---: |
| 菜鸟教程  | 10  |
| RUNOOB.COM | 20  |
| Google  | 22  |

| runoob_id | runoob_title  | runoob_author | submission_date |
| :--- | :--- | :--- | :---: |
| 1| 学习 PHP | 菜鸟教程  | 2017-04-12 |
| 2| 学习 MySQL | 菜鸟教程  | 2017-04-12 |
| 3| 学习 Java | RUNOOB.COM | 2015-05-01 |
| 4| 学习 Python | RUNOOB.COM | 2016-03-06 |
| 5| 学习 C | FK | 2017-04-05 |

### 使用内连接查询
```
SELECT a.runoob_id, a.runoob_author, b.runoob_count FROM runoob_tbl a INNER JOIN tcount_tbl b ON a.runoob_author = b.runoob_author;
```
| a.runoob_id | a.runoob_author | b.runoob_count |
| :--- | :--- | :---: |
| 1 | 菜鸟教程 | 10 |
| 2 | 菜鸟教程 | 10 |
| 3 | RUNOOB.COM | 20 |
| 4 | RUNOOB.COM | 20 |
### 左连接
```
 SELECT a.runoob_id, a.runoob_author, b.runoob_count FROM runoob_tbl a LEFT JOIN tcount_tbl b ON a.runoob_author = b.runoob_author;
```
| a.runoob_id | a.runoob_author | b.runoob_count |
| :--- | :--- | :---: |
| 1 | 菜鸟教程 | 10 |
| 2 | 菜鸟教程 | 10 |
| 3 | RUNOOB.COM | 20 |
| 4 | RUNOOB.COM | 20 |
| 5 | FK | NULL |

### 右连接
```
SELECT a.runoob_id, a.runoob_author, b.runoob_count FROM runoob_tbl a RIGHT JOIN tcount_tbl b ON a.runoob_author = b.runoob_author;
```
| a.runoob_id | a.runoob_author | b.runoob_count |
| :--- | :--- | :---: |
| 1 | 菜鸟教程 | 10 |
| 2 | 菜鸟教程 | 10 |
| 3 | RUNOOB.COM | 20 |
| 4 | RUNOOB.COM | 20 |
| NULL | NULL | 22 |

# MySQL事务
在 MySQL 中只有使用了 Innodb 数据库引擎的数据库或表才支持事务。  
事务处理可以用来维护数据库的完整性，保证成批的 SQL 语句要么全部执行，要么全部不执行。  
事务用来管理 insert、update、delete 语句  
事务是必须满足4个条件（ACID）：：原子性（Atomicity，或称不可分割性）、一致性（Consistency）、隔离性（Isolation，又称独立性）、持久性（Durability）。  

原子性：一个事务（transaction）中的所有操作，要么全部完成，要么全部不完成，不会结束在中间某个环节。事务在执行过程中发生错误，会被回滚（Rollback）到事务开始前的状态，就像这个事务从来没有执行过一样。

一致性：在事务开始之前和事务结束以后，数据库的完整性没有被破坏。这表示写入的资料必须完全符合所有的预设规则，这包含资料的精确度、串联性以及后续数据库可以自发性地完成预定的工作。

隔离性：数据库允许多个并发事务同时对其数据进行读写和修改的能力，隔离性可以防止多个事务并发执行时由于交叉执行而导致数据的不一致。事务隔离分为不同级别，包括读未提交（Read uncommitted）、读提交（read committed）、可重复读（repeatable read）和串行化（Serializable）。

持久性：事务处理结束后，对数据的修改就是永久的，即便系统故障也不会丢失。  

在 MySQL 命令行的默认设置下，事务都是自动提交的，即执行 SQL 语句后就会马上执行 COMMIT 操作。因此要显式地开启一个事务务须使用命令 BEGIN 或 START TRANSACTION，或者执行命令 SET AUTOCOMMIT=0，用来禁止使用当前会话的自动提交。

# ALTER命令
## 添加列
```
-- 在 employees 表中添加了一个名为 birth_date 的日期列
ALTER TABLE employees
ADD COLUMN birth_date DATE;
```
## 修改列的数据类型
```
-- 将 employees 表中的 salary 列的数据类型修改为 DECIMAL(10,2)
ALTER TABLE employees
MODIFY COLUMN salary DECIMAL(10,2);
```
## 修改列名
```
-- 将 employees 表中的某个列的名字由 old_column_name 修改为 new_column_name，并且可以同时修改数据类型
ALTER TABLE employees
CHANGE COLUMN old_column_name new_column_name VARCHAR(255);
```

## 删除列
```
--- 将 employees 表中的 birth_date 列删除
ALTER TABLE employees
DROP COLUMN birth_date;
```

## 添加主键
```
-- 在 employees 表中添加了一个主键
ALTER TABLE employees
ADD PRIMARY KEY (employee_id);
```

## 添加外键
```
-- 在 orders 表中添加了一个外键，关联到 customers 表的 customer_id 列
ALTER TABLE orders
ADD CONSTRAINT fk_customer
FOREIGN KEY (customer_id)
REFERENCES customers (customer_id);
```

## 修改表名
```
-- 将表名由 employees 修改为 staff
ALTER TABLE employees
RENAME TO staff;
```

# 索引
索引分为单列索引和组合索引。
单列索引：一个索引只包含单个列，一个表可以有多个单列索引  
组合索引：一个索引包含多个列。  
索引也是一张表，该表保存了主键与索引字段，并指向实体表的记录。需要占用额外的存储空间。进行插入、更新和删除操作时，索引需要维护，可能会影响性能。
## 普通索引
### 创建索引
```
-- students 的表，包含 id、name 和 age 列，在 name 列上创建一个普通索引
CREATE INDEX idx_name ON students (name);
```

### 修改表结构添加索引
```
-- 在已存在的名为 employees 的表上创建一个普通索引
ALTER TABLE employees
ADD INDEX idx_age (age);
```

### 创建表时指定
```
-- 创建一个名为 students 的表，并在 age 列上创建一个普通索引
CREATE TABLE students (
  id INT PRIMARY KEY,
  name VARCHAR(50),
  age INT,
  INDEX idx_age (age)
);
```

### 删除索引
```
-- 有一张employees 的表，并在 age 列上有一个名为 idx_age 的索引，删除这个索引

-- 方法一：使用DROP INDEX ... ON ...；
DROP INDEX idx_age ON employees;

-- 方法二：使用ALTER TABLE修改
ALTER TABLE employees
DROP INDEX idx_age;
```

## 唯一索引
### 创建唯一索引
```
-- 有一个名为 employees的 表，包含 id 和 email 列
-- 现在在email列上创建一个唯一索引，以确保每个员工的电子邮件地址都是唯一的
CREATE UNIQUE INDEX idx_email ON employees (email);
```
### 修改表结构添加唯一索引
```
-- 有一个名为 employees 的表，包含 id 和 email 列，现在在 email 列上创建一个唯一索引，以确保每个员工的电子邮件地址都是唯一的。
ALTER TABLE employees
ADD CONSTRAINT idx_email UNIQUE (email);
```

### 创建表时指定
```
-- 创建一个名为 employees 的表，其中包含 id、name 和 email 列，email 列的值是唯一的，要在创建表时定义唯一索引
CREATE TABLE employees (
  id INT PRIMARY KEY,
  name VARCHAR(50),
  email VARCHAR(100) UNIQUE
);
```

## 使用ALTER命令来添加或者删除索引
```
ALTER TABLE tbl_name ADD PRIMARY KEY (column_list): 该语句添加一个主键，主键列中的值必须唯一，主键的列的列表，可以是一个或多个列，不能包含 NULL 值。  
ALTER TABLE tbl_name ADD UNIQUE index_name (column_list): 这条语句创建索引的值必须是唯一的（除了NULL外，NULL可能会出现多次）。  
ALTER TABLE tbl_name ADD INDEX index_name (column_list): 添加普通索引，索引值可出现多次。  
ALTER TABLE tbl_name ADD FULLTEXT index_name (column_list):该语句指定了索引为 FULLTEXT ，用于全文索引。  
```
## 使用ALTER命令来添加或者删除主键
```
ALTER TABLE testalter_tbl MODIFY i INT NOT NULL;
ALTER TABLE testalter_tbl ADD PRIMARY KEY (i);
ALTER TABLE testalter_tbl DROP PRIMARY KEY;
```

## 显示索引信息
```
SHOW INDEX FROM table_name;
```