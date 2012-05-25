require 'find'
require 'nokogiri'

File.open("extracted_news.jtxt", "w") do |f|
  Find.find("downloads/news") do |path|
    if !FileTest.directory?(path) && path =~ /\.html?$/
      puts "Checking %s" % path
      s = File.open(path, "r") { |f| f.read }
      s.force_encoding("utf-8")
      s =~ /## begin Metadata\nurl: (.*)\nretrieval_date: (.*)\n## end Metadata\n/
      url, retrieval_date = $1, $2
      doc = Nokogiri.HTML($~.post_match)
      f.puts("-- %s\n" % url)
      doc.xpath("//div[@class='entry-text']//text()").each do |textnode|
        s = textnode.to_s
        f.puts(s) if s =~ /\S/
      end
    end
  end
end
