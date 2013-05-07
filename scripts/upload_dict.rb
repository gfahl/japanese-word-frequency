puts Time.now
require 'nokogiri'
require 'dbi'

dbh = DBI.connect("DBI:Mysql:dict:localhost", "dict", "welcome")
dbh.do("SET NAMES 'utf8'")
dbh.do("SET SESSION sql_mode = 'TRADITIONAL'")
dbh['AutoCommit'] = false

failures = []
File.open("dict.xml") do |f|
  puts "Parsing XML..."
  doc = Nokogiri::XML(f)
  #
  puts "Inserting into part-of-speech lookup table..."
  pos_hash = {} # { "adjective (keiyoushi)" => "adj-i" etc. }
  doc.internal_subset.entities.each do |k, v|
    dbh.do("insert into information (code, description) values (?, ?)", k, v.content)
    pos_hash[v.content] = k
  end
  #
  puts "Inserting entries..."
  i = 0
  doc.xpath("JMdict/entry").each do |e|
    seq_nbr = e.at_xpath("ent_seq").text
    $stderr.print("\x08" * 6, i) if (i += 1) % 100 == 0
    dbh.do("insert into entry () values ()")
    entry_id = dbh.func(:insert_id)
    dbh.do("insert into dictionary_entry (id) values (?)", entry_id)
    dbh.do("insert into jmdict_entry (id, seq_nbr) values (?, ?)", entry_id, seq_nbr)
    #
    pos_list = [] # this entry's part-of-speech
    e.xpath("sense").each do |meaning|
      dbh.do("insert into meaning (entry_id) values (?)", entry_id)
      meaning_id = dbh.func(:insert_id)
      meaning.xpath("pos").each do |pos|
        pos_code = pos_hash[pos.text]
        dbh.do("insert into part_of_speech (meaning_id, information_code) values (?, ?)", meaning_id, pos_code)
        pos_list << pos_code
      end
      meaning.xpath("gloss").each do |translation|
        word = translation.text
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
    e.xpath("k_ele").each do |k_ele|
      word = k_ele.at_xpath("keb").text
      lookup = pos_list.find { |pos| pos == "adj-i" || pos =~ /^v[15]/ } ? word[0..-2] : word
# p word
# p word.encoding
      res = dbh.select_one("select id from lookup_item where characters = ?", lookup)
      lookup_item_id =
        if res then res[0]
        else
          begin
            dbh.do("insert into lookup_item (characters) values (?)", lookup)
            dbh.func(:insert_id)
          rescue Exception => ex
            failures << [seq_nbr, ex]
            nil
          end
        end
      if lookup_item_id
        dbh.do("insert into kanji_representation (entry_id, word, lookup_item_id) values (?, ?, ?)", entry_id, word, lookup_item_id)
      end
    end
    e.xpath("r_ele").each do |r_ele|
      dbh.do("insert into reading (entry_id, word) values (?, ?)", entry_id, r_ele.at_xpath("reb").text)
    end
    # break if i == 250
  end
  $stderr.print("\x08" * 6, i, "\n")
end
puts "Failures:"
failures.each { |f| puts "%s: %s" % f }
dbh.commit
puts Time.now
