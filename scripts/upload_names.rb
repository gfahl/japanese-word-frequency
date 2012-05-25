puts Time.now
require 'nokogiri'
require 'dbi'

dbh = DBI.connect("DBI:Mysql:dict:localhost", "dict", "welcome")
dbh.do("SET NAMES 'utf8'")
dbh.do("SET SESSION sql_mode = 'TRADITIONAL'")
dbh['AutoCommit'] = false

File.open("names.xml") do |f|
  puts "Parsing XML..."
  doc = Nokogiri::XML(f)
  #
  puts "Inserting into part-of-speech lookup table..."
  pos_hash = {} # { "adjective (keiyoushi)" => "adj-i" etc. }
  doc.internal_subset.entities.each do |k, v|
    dbh.do("insert into information (code, description) values (?, ?)", "name-" + k, v.content)
    pos_hash[v.content] = "name-" + k
  end
  #
  puts "Inserting entries..."
  i = 0
  doc.xpath("JMnedict/entry").each do |e|
    $stderr.print("\x08" * 6, i) if (i += 1) % 100 == 0
    dbh.do("insert into entry () values ()")
    entry_id = dbh.func(:insert_id)
    dbh.do("insert into name_entry (id) values (?)", entry_id)
    #
    e.xpath("k_ele").each do |k_ele|
      word = k_ele.at_xpath("keb").text
      lookup = word
      res = dbh.select_one("select id from lookup_item where characters = ?", lookup)
      lookup_item_id =
        if res then res[0]
        else
          dbh.do("insert into lookup_item (characters) values (?)", lookup)
          dbh.func(:insert_id)
        end
      dbh.do("insert into kanji_representation (entry_id, word, lookup_item_id) values (?, ?, ?)", entry_id, word, lookup_item_id)
    end
    e.xpath("r_ele").each do |r_ele|
      dbh.do("insert into reading (entry_id, word) values (?, ?)", entry_id, r_ele.at_xpath("reb").text)
    end
    e.xpath("trans").each do |meaning|
      dbh.do("insert into meaning (entry_id) values (?)", entry_id)
      meaning_id = dbh.func(:insert_id)
      meaning.xpath("name_type").map(&:text).uniq.each do |pos_text| # sometimes contains duplicates
        dbh.do("insert into part_of_speech (meaning_id, information_code) values (?, ?)", meaning_id, pos_hash[pos_text])
      end
      meaning.xpath("trans_det").map(&:text).uniq.each do |word| # sometimes contains duplicates
        res = dbh.select_one("select id from translation where word = ?", word)
        translation_id =
          if res then res[0]
          else
            dbh.do("insert into translation (word) values (?)", word)
            dbh.func(:insert_id)
          end
        dbh.do("insert into meaning_translation (meaning_id, translation_id) values (?, ?)", meaning_id, translation_id)
      end
    end
    # break if i == 250
  end
  $stderr.print("\x08" * 6, i, "\n")
end
dbh.commit
puts Time.now
