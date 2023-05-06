CREATE DATABASE log_center;

CREATE TABLE log_diag(
   app_name varchar(256),
   disk_space integer,
   purge_percent integer,
   severity varchar(256),
   duration integer,
   PRIMARY KEY( app_name )
);