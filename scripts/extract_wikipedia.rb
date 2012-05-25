# encoding: utf-8
require 'find'
require 'nokogiri'

File.open("extracted_wikipedia.jtxt", "w") do |f|
  Find.find("downloads/wikipedia") do |path|
    if !FileTest.directory?(path) && path !~ /Category/ && path !~ /Template_/
      puts "Checking %s" % path
      s = File.open(path, "r") { |f| f.read }
      s.force_encoding("utf-8")
      s =~ /## begin Metadata\nurl: (.*)\nretrieval_date: (.*)\n## end Metadata\n/
      url, retrieval_date = $1, $2
      doc = Nokogiri.HTML($~.post_match)
      f.puts("-- %s\n" % url)
      doc.xpath("//*[@id='siteSub']").remove
      doc.xpath("//*[@id='jump-to-nav']").remove
      doc.xpath("//*[@class='editsection']").remove
      doc.xpath("//*[@class='printfooter']").remove
      doc.xpath("//*[@id='catlinks']").remove
      doc.xpath("//*[@class='navbox']").remove
      doc.xpath("//div[@id='content']//text()").each do |textnode|
        s = textnode.to_s
        f.puts(s) if s =~ /\S/
      end
    end
  end
end
