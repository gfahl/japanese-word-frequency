DROP TABLE IF EXISTS part_of_speech;
DROP TABLE IF EXISTS information;
DROP TABLE IF EXISTS meaning_translation;
DROP TABLE IF EXISTS translation;
DROP TABLE IF EXISTS meaning;
DROP TABLE IF EXISTS reading;
DROP TABLE IF EXISTS kanji_representation;
DROP TABLE IF EXISTS lookup_item;
DROP TABLE IF EXISTS name_entry;
DROP TABLE IF EXISTS dictionary_entry;
DROP TABLE IF EXISTS entry;

CREATE TABLE entry (
	id INT NOT NULL AUTO_INCREMENT,
	PRIMARY KEY (id)
	);

CREATE TABLE dictionary_entry (
	id INT NOT NULL,
	seq_nbr INT NOT NULL
	);

CREATE TABLE name_entry (
	id INT NOT NULL
	);

CREATE TABLE lookup_item (
	id INT NOT NULL AUTO_INCREMENT,
	characters VARCHAR(50),
	PRIMARY KEY (id)
	);

CREATE TABLE kanji_representation (
	id INT NOT NULL AUTO_INCREMENT,
	entry_id INT NOT NULL,
	word VARCHAR(50),
	lookup_item_id INT,
	PRIMARY KEY (id)
	);

CREATE TABLE reading (
	id INT NOT NULL AUTO_INCREMENT,
	entry_id INT NOT NULL,
	word VARCHAR(200),
	PRIMARY KEY (id)
	);

CREATE TABLE meaning (
	id INT NOT NULL AUTO_INCREMENT,
	entry_id INT NOT NULL,
	PRIMARY KEY (id)
	);

CREATE TABLE translation (
	id INT NOT NULL AUTO_INCREMENT,
	word VARCHAR(1000),
	PRIMARY KEY (id)
	);

CREATE TABLE meaning_translation (
	meaning_id INT,
	translation_id INT
	);

CREATE TABLE information (
	code VARCHAR(50) NOT NULL,
	description VARCHAR(200) NOT NULL
	);

CREATE TABLE part_of_speech (
	meaning_id INT,
	information_code VARCHAR(50)
	);
