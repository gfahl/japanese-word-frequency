ALTER TABLE lookup_item
	ADD UNIQUE INDEX (characters);

ALTER TABLE translation
	ADD INDEX (word);
