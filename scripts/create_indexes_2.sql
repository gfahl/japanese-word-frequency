ALTER TABLE dictionary_entry
	ADD PRIMARY KEY (id),
	ADD FOREIGN KEY (id) REFERENCES entry (id);

ALTER TABLE jmdict_entry
	ADD PRIMARY KEY (id),
	ADD FOREIGN KEY (id) REFERENCES dictionary_entry (id);

ALTER TABLE my_entry
	ADD PRIMARY KEY (id),
	ADD FOREIGN KEY (id) REFERENCES dictionary_entry (id);

ALTER TABLE name_entry
	ADD PRIMARY KEY (id),
	ADD FOREIGN KEY (id) REFERENCES entry (id);

ALTER TABLE kanji_representation
	ADD FOREIGN KEY (entry_id) REFERENCES entry (id),
	ADD FOREIGN KEY (lookup_item_id) REFERENCES lookup_item (id),
	ADD INDEX (entry_id),
	ADD INDEX (word),
	ADD INDEX (lookup_item_id);

ALTER TABLE reading
	ADD FOREIGN KEY (entry_id) REFERENCES entry (id),
	ADD INDEX (entry_id),
	ADD INDEX (word);

ALTER TABLE meaning
	ADD FOREIGN KEY (entry_id) REFERENCES entry (id),
	ADD INDEX (entry_id);

ALTER TABLE meaning_translation
	ADD PRIMARY KEY (meaning_id, translation_id),
	ADD FOREIGN KEY (meaning_id) REFERENCES meaning (id),
	ADD FOREIGN KEY (translation_id) REFERENCES translation (id),
	ADD INDEX (meaning_id),
	ADD INDEX (translation_id);

ALTER TABLE information
	ADD PRIMARY KEY (code);

ALTER TABLE part_of_speech
	ADD PRIMARY KEY (meaning_id, information_code),
	ADD FOREIGN KEY (meaning_id) REFERENCES meaning (id),
	ADD FOREIGN KEY (information_code) REFERENCES information (code),
	ADD INDEX (meaning_id);
