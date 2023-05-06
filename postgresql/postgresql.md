进入pg数据库
sudo -i -u postgres
psql
退出
\q

查看命令的语法
\help

SELECT id, name FROM table

ABORT 退出当前事务
ABORT [ WORK | TRANSACTION ]

ALTER AGGREGATE 修改一个聚集函数的定义
ALTER AGGREGATE _name_ ( _argtype_ [ , ... ] ) RENAME TO _new_name_
ALTER AGGREGATE _name_ ( _argtype_ [ , ... ] ) OWNER TO _new_owner_
ALTER AGGREGATE _name_ ( _argtype_ [ , ... ] ) SET SCHEMA _new_schema_

ALTER COLLATION 修改一个排序规则定义
ALTER COLLATION _name_ RENAME TO _new_name_
ALTER COLLATION _name_ OWNER TO _new_owner_
ALTER COLLATION _name_ SET SCHEMA _new_schema_

ALTER CONVERSION 修改一个编码转换的定义
ALTER CONVERSION name RENAME TO new_name
ALTER CONVERSION name OWNER TO new_owner

ALTER DATABASE 修改一个数据库
ALTER DATABASE name SET parameter { TO | = } { value | DEFAULT }
ALTER DATABASE name RESET parameter
ALTER DATABASE name RENAME TO new_name
ALTER DATABASE name OWNER TO new_owner

ALTER DEFAULT PRIVILEGES 定义默认的访问权限
ALTER DEFAULT PRIVILEGES
    [ FOR { ROLE | USER } target_role [, ...] ]
    [ IN SCHEMA schema_name [, ...] ]
    abbreviated_grant_or_revoke

where abbreviated_grant_or_revoke is one of:

GRANT { { SELECT | INSERT | UPDATE | DELETE | TRUNCATE | REFERENCES | TRIGGER }
    [, ...] | ALL [ PRIVILEGES ] }
    ON TABLES
    TO { [ GROUP ] role_name | PUBLIC } [, ...] [ WITH GRANT OPTION ]
...

ALTER DOMAIN 修改一个域的定义
ALTER DOMAIN name { SET DEFAULT expression | DROP DEFAULT }
ALTER DOMAIN name { SET | DROP } NOT NULL
ALTER DOMAIN name ADD domain_constraint
ALTER DOMAIN name DROP CONSTRAINT constraint_name [ RESTRICT | CASCADE ]
ALTER DOMAIN name OWNER TO new_owner

ALTER FUNCTION 修改一个函数的定义
ALTER FUNCTION name ( [ type [, ...] ] ) RENAME TO new_name
ALTER FUNCTION name ( [ type [, ...] ] ) OWNER TO new_owner

ALTER GROUP 修改一个用户组
ALTER GROUP groupname ADD USER username [, ... ]
ALTER GROUP groupname DROP USER username [, ... ]
ALTER GROUP groupname RENAME TO new_name

ALTER INDEX 修改一个索引的定义
ALTER INDEX name OWNER TO new_owner
ALTER INDEX name SET TABLESPACE indexspace_name
ALTER INDEX name RENAME TO new_name

ALTER LANGUAGE 修改一个过程语言的定义
ALTER LANGUAGE name RENAME TO new_name

ALTER OPERATOR 改变一个操作符的定义
ALTER OPERATOR name ( { lefttype | NONE }, { righttype | NONE } )
OWNER TO new_owner

ALTER OPERATOR CLASS 修改一个操作符表的定义
ALTER OPERATOR CLASS name USING index_method RENAME TO new_name
ALTER OPERATOR CLASS name USING index_method OWNER TO new_owner

数据类型
数值类型
数值类型由 2 字节、4 字节或 8 字节的整数以及 4 字节或 8 字节的浮点数和可选精度的十进制数组成。
|名字|存储长度|描述|范围|
|-----|:-------------:|------:|------:|
|smallint|2 字节|小范围整数|-32768 到 +32767|
|integer|4 字节|常用的整数|-2147483648 到 +2147483647|
|bigint|8 字节|大范围整数|-9223372036854775808 到 +9223372036854775807|
|decimal|可变长|用户指定的精度，精确|小数点前 131072 位；小数点后 16383 位|
|numeric|可变长|用户指定的精度，精确|小数点前 131072 位；小数点后 16383 位|
|real|4 字节|可变精度，不精确|6 位十进制数字精度|
|double precision|8 字节|可变精度，不精确|15 位十进制数字精度|
|smallserial|2 字节|自增的小范围整数|1 到 32767|
|serial|4 字节|自增整数|1 到 2147483647|
|bigserial|8 字节|自增的大范围整数|1 到 9223372036854775807|

货币类型
money 类型存储带有固定小数精度的货币金额。
numeric、int 和 bigint 类型的值可以转换为 money，不建议使用浮点数来处理处理货币类型，因为存在舍入错误的可能性。
|名字|存储容量|描述|范围|
|-----|:--------|------|------|
|money|8 字节|货币金额|-92233720368547758.08 到 +92233720368547758.07|

字符类型
|名字 & 描述|
|:-------:|
|character varying(n), varchar(n)<br>变长，有长度限制|
|character(n), char(n)<br>f定长,不足补空白|
|text<br>变长，无长度限制|

日期/时间类型
|名字|存储空间|描述|最低值|最高值|分辨率|
|-----|:--------|:------|:------|:------|:------|
|timestamp [ (p) ] [ without time zone ]|8 字节|日期和时间(无时区)|4713 BC|294276 AD|1 毫秒 / 14 位|
|timestamp [ (p) ] with time zone|8 字节|日期和时间，有时区|4713 BC|294276 AD|1 毫秒 / 14 位|
|date|4 字节|只用于日期|4713 BC|5874897 AD|1 天|
|time [ (p) ] [ without time zone ]|8 字节|只用于一日内时间|00:00:00|24:00:00|1 毫秒 / 14 位|
|time [ (p) ] with time zone|12 字节|只用于一日内时间，带时区|00:00:00+1459|24:00:00-1459|1 毫秒 / 14 位|
|interval [ fields ] [ (p) ]|12 字节|时间间隔|-178000000 年|178000000 年|1 毫秒 / 14 位|

布尔类型
|名称|存储格式|描述|
|-----|:--------|:------|
|boolean|1 字节|true/false|

枚举类型
枚举类型是一个包含静态和值的有序集合的数据类型。
PostgtesSQL中的枚举类型类似于 C 语言中的 enum 类型。
与其他类型不同的是枚举类型需要使用 CREATE TYPE 命令创建。
CREATE TYPE mood AS ENUM ('sad', 'ok', 'happy');
CREATE TYPE week AS ENUM ('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun');
CREATE TYPE mood AS ENUM ('sad', 'ok', 'happy');
CREATE TABLE person (
    name text,
    current_mood mood
);
INSERT INTO person VALUES ('Moe', 'happy');
SELECT * FROM person WHERE current_mood = 'happy';
 name | current_mood 
------+--------------
 Moe  | happy
(1 row)

几何类型

|名字|存储空间|说明|表现形式|

|point|16 字节|平面中的点|(x,y)|
|line|32 字节|(无穷)直线(未完全实现)|((x1,y1),(x2,y2))|
|lseg|32 字节|(有限)线段|((x1,y1),(x2,y2))|
|box|32 字节|矩形|((x1,y1),(x2,y2))|
|path|16+16n 字节|闭合路径(与多边形类似)|((x1,y1),...)|
|path|16+16n 字节|开放路径|[(x1,y1),...]|
|polygon|40+16n 字节|多边形(与闭合路径相似)|((x1,y1),...)|
|circle|24 字节|圆|<(x,y),r> (圆心和半径)|