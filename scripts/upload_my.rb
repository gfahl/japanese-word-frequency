puts Time.now
require 'nokogiri'
require 'dbi'

dbh = DBI.connect("DBI:Mysql:dict:localhost", "dict", "welcome")
dbh.do("SET NAMES 'utf8'")
dbh.do("SET SESSION sql_mode = 'TRADITIONAL'")
dbh['AutoCommit'] = false

puts "Inserting into part-of-speech lookup table..."
dbh.do("insert into information (code, description) values ('v', 'verb')")

puts "Inserting entries..."
File.open("go_terminology.txt", "r") do |f|
  f.gets # the first line contains column headers - ignore it
  while (s = f.gets)
    entry = s.force_encoding("utf-8").chomp.split("\t")
    kanji_representations = entry[0..3].reject { |s| s == "" }
    readings = entry[4..5].reject { |s| s == "" }
    part_of_speech = entry[6]
    dbh.do("insert into entry () values ()")
    entry_id = dbh.func(:insert_id)
    dbh.do("insert into dictionary_entry (id) values (?)", entry_id)
    dbh.do("insert into my_entry (id) values (?)", entry_id)
    #
    kanji_representations.each do |word|
      lookup = ["adj-i", "v"].include?(part_of_speech) ? word[0..-2] : word
      res = dbh.select_one("select id from lookup_item where characters = ?", lookup)
      lookup_item_id =
        if res then res[0]
        else
          dbh.do("insert into lookup_item (characters) values (?)", lookup)
          dbh.func(:insert_id)
        end
      dbh.do("insert into kanji_representation (entry_id, word, lookup_item_id) values (?, ?, ?)", entry_id, word, lookup_item_id)
    end
    readings.each do |r|
      dbh.do("insert into reading (entry_id, word) values (?, ?)", entry_id, r)
    end
    dbh.do("insert into meaning (entry_id) values (?)", entry_id)
    meaning_id = dbh.func(:insert_id)
    dbh.do("insert into part_of_speech (meaning_id, information_code) values (?, ?)", meaning_id, part_of_speech)
  end
end

dbh.commit
puts Time.now
