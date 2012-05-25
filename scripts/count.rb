# encoding: utf-8
require 'dbi'

dbh = DBI.connect("DBI:Mysql:dict:localhost", "dict", "welcome")
dbh.do("SET NAMES 'utf8'")
dbh.do("SET SESSION sql_mode = 'TRADITIONAL'")

source = ARGV.first
File.basename(source) =~ /([^_]+)\.jtxt$/
raise "Unexpected file name" if !$1
source_base = $1
count = Hash.new(0) # lookup_item => number of occurences
visited_pages = []
i = 0
puts "Counting..."
File.open(source, "r") do |f|
  # while (i < 500 && s = f.gets)
  while (s = f.gets)
    s.force_encoding("UTF-8")
    s.gsub!("'", "_") # messes up SQL strings and we're not interested in them anyway
    $stderr.print("\x08" * 6, i) if (i += 1) % 100 == 0
    if s =~ /-- (.*)/
      visited_pages << $1
    else
      while s != "" do
        pos = 0
        found = true
        while found and pos < s.size do
          sql = "select count(*) from lookup_item where characters like '" + s[0..pos] + "%'"
          found = dbh.select_one(sql)[0] >= 1 rescue begin p(s[0..pos]); raise "foo" end
          pos += 1 if found
        end
        while !found and pos >= 1 do
          pos -= 1
          found = dbh.select_one("select count(*) from lookup_item where characters = ?", s[0..pos])[0] >= 1
        end
        if found
          count[s[0..pos]] += 1
        end
        s = s[pos + 1..-1]
      end
    end
  end
end
$stderr.print("\x08" * 6, i, "\n")

template_html = <<EOF
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>Word frequency (%source_base%)</title>
    <style type="text/css">
      table, th, td {border: 1px solid black;}
      table {border-collapse: collapse;}
      th, td {padding: 3px;}
      td.w1 {min-width: 100px;}
      td.w2 {min-width: 150px;}
      td.c {text-align: center;}
      a {text-decoration: none; color: 00c;}
    </style>
  </head>
  <body>
    <table>
%table_header%
%table_rows%
    </table>
    <p>Number of matches: %no_of_matches%<br />Number of distinct matches: %distinct_no_of_matches%</p>
  </body>
</html>
EOF

table_header = <<EOF
<tr>
<th>Rank</th>
<th>Match</th>
<th>Number of<br />occurances</th>
<th>Words</th>
<th>Names</th>
</tr>
EOF

table_header_long = <<EOF
<tr>
<th>Rank</th>
<th>Match</th>
<th>Number of<br />occurances</th>
<th>Word</th>
<th>Readings</th>
<th>Part-of-speech</th>
<th>Meaning</th>
</tr>
EOF

template_table_row = <<EOF
<tr>
<td class='c'>%rank%</td>
<td>%match%</td>
<td class='c'>%count%</td>
<td>%words%</td>
<td>%names%</td>
</tr>
EOF

template_dict_link = "<a href='http://www.jisho.org/words?jap=%word%&eng=&dict=edict'>%word%</a>"
template_name_link = "<a href='http://www.jisho.org/words?jap=%name%&eng=&dict=enamdic'>%name%</a>"

template_table_row_long = <<EOF
<tr>
<td class='c'>%rank%</td>
<td class='w1'>%match%</td>
<td class='c'>%count%</td>
<td class='w1'>%word%</td>
<td class='w2'>%readings%</td>
<td>%part_of_speech%</td>
<td>%meaning%</td>
</tr>
EOF

template_xml = <<EOF
<?xml version='1.0' encoding='UTF-8'?>
<!DOCTYPE root [
<!ELEMENT root (match*)>
<!ELEMENT match (word*)>
<!ATTLIST match characters CDATA #REQUIRED>
<!ATTLIST match count CDATA #REQUIRED>
<!ATTLIST match name (yes|no) "no">
<!ELEMENT word (#PCDATA)>
]>
<root>
%xml_rows%
</root>
EOF

template_xml_row = "<match characters='%match%' count='%count%'%name_indicator%>%word_elements%</match>"

template_analyzed = <<EOF
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
    <title>Analyzed pages (%source_base%)</title>
  </head>
  <body>
    <p>Analyzed pages (%source_base%):</p>
%visited_pages%
  </body>
</html>
EOF

sql_get_kanji_representations = <<EOF
SELECT  kr.word,
        e.id,
        de.id,
        ne.id
FROM    lookup_item li
        JOIN kanji_representation kr ON li.id = kr.lookup_item_id
        JOIN entry e ON kr.entry_id = e.id
        LEFT OUTER JOIN dictionary_entry de ON e.id = de.id
        LEFT OUTER JOIN name_entry ne ON e.id = ne.id
WHERE   li.characters = ?
ORDER BY kr.word
EOF

sql_get_readings = "SELECT word FROM reading WHERE entry_id = ?"
sql_get_meanings = "SELECT id FROM meaning WHERE entry_id = ?"
sql_get_part_of_speech = "SELECT information_code FROM part_of_speech WHERE meaning_id = ?"

sql_get_translations = <<EOF
SELECT  t.word
FROM    meaning_translation mt,
        translation t
WHERE   mt.meaning_id = ?
AND     mt.translation_id = t.id"
EOF

puts "Preparing reports..."
# count.reject! { |characters, cnt| characters =~ /^[\uFF00-\uFFFF]*$/ } # full-width digits etc.
count.reject! { |characters, cnt| characters !~ /[\u4E00-\u9FFF]/ } # has to have at least one CJK Unified Ideograph
no_of_matches = count.values.inject(:+)
distinct_no_of_matches = count.size
count = count.to_a.sort_by { |characters, cnt| [-cnt, characters] }
no_of_common = count.index { |characters, cnt| cnt.to_f / no_of_matches < 0.0001 }
no_of_common ||= count.size
table_rows, table_rows_long, xml_rows = [], [], []
previous_cnt = -1
j = 0
count.each_with_index do |charcters_and_cnt, i|
  characters, cnt = charcters_and_cnt
  $stderr.print("\x08" * 6, j) if (j += 1) % 100 == 0
  rank = cnt == previous_cnt ? "" : (i + 1).to_s
  words = []
  names = []
  show_lookup = true
  dbh.select_all(sql_get_kanji_representations, characters).each do |row|
    word, entry_id, de_id, ne_id = row
    word.force_encoding("UTF-8")
    if de_id
      words << word
      readings = dbh.select_all(sql_get_readings, entry_id).map { |r| r["word"] }.join("<br />")
      readings.force_encoding("UTF-8")
    end
    show_entry = true
    dbh.select_all(sql_get_meanings, entry_id).each do |row|
      meaning_id = row["id"]
      translations = dbh.select_all(sql_get_translations, meaning_id).map { |r| r["word"] }.join(", ")
      translations.force_encoding("UTF-8")
      if de_id
        part_of_speech = dbh.select_all(sql_get_part_of_speech, meaning_id).map { |r| r["information_code"] }.join(", ")
        part_of_speech.force_encoding("UTF-8")
        table_rows_long << template_table_row_long.dup.
          sub("%rank%", show_lookup ? rank : "").
          sub("%match%", show_lookup ? characters : "").
          sub("%count%", show_lookup ? cnt.to_s : "").
          sub("%word%", show_entry ? word : "").
          sub("%readings%", show_entry ? readings : "").
          sub("%part_of_speech%", part_of_speech).
          sub("%meaning%", translations)
        show_lookup = false
        show_entry = false
      else
        names << translations
      end
    end
  end
  if !names.empty?
    table_rows_long << template_table_row_long.dup.
      sub("%rank%", show_lookup ? rank : "").
      sub("%match%", show_lookup ? characters : "").
      sub("%count%", show_lookup ? cnt.to_s : "").
      sub("%word%", characters).
      sub("%readings%", "").
      sub("%part_of_speech%", "name").
      sub("%meaning%", names.join(", "))
  end
  table_rows << template_table_row.dup.
    sub("%rank%", rank).
    sub("%match%", characters).
    sub("%count%", cnt.to_s).
    sub("%words%",
      words.uniq.map { |word| template_dict_link.dup.gsub("%word%", word) }.join("&#12288;")).
    sub("%names%", names.empty? ? "" : template_name_link.dup.gsub("%name%", characters))
  xml_rows << template_xml_row.dup.
    sub("%match%", characters).
    sub("%count%", cnt.to_s).
    sub("%name_indicator%", names.empty? ? "" : " name='yes'").
    sub("%word_elements%",
      words.uniq.map { |word| "<word>%s</word>" % word }.join)
  previous_cnt = cnt
end
$stderr.print("\x08" * 6, j, "\n")

puts "Creating reports..."
File.open("word_frequency_%s.html" % source_base, "w") do |f|
  f.print(template_html.
    gsub("%source_base%", source_base).
    gsub("%table_header%", table_header).
    gsub("%table_rows%", table_rows.join("\n")).
    gsub("%no_of_matches%", no_of_matches.to_s).
    gsub("%distinct_no_of_matches%", distinct_no_of_matches.to_s))
end

File.open("word_frequency_%s_common.html" % source_base, "w") do |f|
  f.print(template_html.
    gsub("%source_base%", source_base + " common").
    gsub("%table_header%", table_header).
    gsub("%table_rows%", table_rows[0...no_of_common].join("\n")).
    gsub("%no_of_matches%", no_of_matches.to_s).
    gsub("%distinct_no_of_matches%", distinct_no_of_matches.to_s))
end

File.open("word_frequency_%s_long.html" % source_base, "w") do |f|
  f.print(template_html.
    gsub("%source_base%", source_base + " long").
    gsub("%table_header%", table_header_long).
    gsub("%table_rows%", table_rows_long.join("\n")).
    gsub("%no_of_matches%", no_of_matches.to_s).
    gsub("%distinct_no_of_matches%", distinct_no_of_matches.to_s))
end

File.open("word_frequency_%s.xml" % source_base, "w") do |f|
  f.print(template_xml.gsub("%xml_rows%", xml_rows.join("\n")))
end

File.open("visited_pages_%s.html" % source_base, "w") do |f|
  f.print(template_analyzed.
    gsub("%source_base%", source_base).
    gsub("%visited_pages%",
      visited_pages.sort.map { |page| "<a href='%s'>%s</a><br />" % [page, page] }.join("\n")))
end
