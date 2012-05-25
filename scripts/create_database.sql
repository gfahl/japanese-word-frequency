-- run as root
CREATE DATABASE dict CHARACTER SET utf8 COLLATE utf8_bin;
CREATE USER 'dict'@'localhost' IDENTIFIED BY 'welcome';
GRANT ALL ON dict.* TO 'dict'@'localhost' WITH GRANT OPTION;
