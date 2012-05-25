# encoding: utf-8
require 'find'

File.open("extracted_commentary.jtxt", "w") do |f|
  Find.find("downloads/commentary") do |path|
    begin
      if !FileTest.directory?(path)
        puts "Checking %s" % path
        s = File.open(path, "r:euc-jp:utf-8") { |f| f.read }
        s =~ /## begin Metadata\nurl: (.*)\nretrieval_date: (.*)\n## end Metadata\n/
        url, retrieval_date = $1, $2
        s = $~.post_match
        if s =~ /<!--★★記事本文エリア[^>]*★★-->(.*?)<!--/m ||
            s =~ /<!-- Start of kiji -->(.*?)(<!--|次の譜へ)/m
          f.puts("-- %s\n%s\n" % [url, $1])
        end
      end
    rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError => e
      puts e.message
    end
  end
end
