# part 1: download index pages
require 'open-uri'
require 'uri'
require 'fileutils'
require 'nokogiri'

crawl_dir = "downloads/news"
FileUtils.mkdir_p(crawl_dir)

home_page = "http://www.nihonkiin.or.jp/news/"
remaining = []
not_found = []

header = "## begin Metadata\nurl: %s\nretrieval_date: %s\n## end Metadata\n"
delay = 30

puts "Downloading index page..."
page_content = open("http://www.nihonkiin.or.jp/news/index.html").read
prev_request = Time.now
n = 1
while page_content
  puts "Looking for links..."
  doc = Nokogiri.HTML(page_content)
  doc.xpath("//div[@class='entry-box']//a").each do |node|
    link = (URI.parse(home_page) + URI.parse(node['href'])).to_s
    link << "index.html" if link[-1] == "/"
    remaining << link if !remaining.include?(link)
  end
  puts "Links found: %s" % remaining.size
  n += 1
  puts "Waiting..."
  sleep([0, delay - (Time.now - prev_request)].max)
  puts "Downloading index page..."
  page_content =
    begin
      open("http://www.nihonkiin.or.jp/news/index_%s.html" % n).read
    rescue Exception => e
      case e.message when /404/ then nil else raise e end
    end
  prev_request = Time.now
end

File.open("downloads/news/remaining.txt", "w") { |f| f.puts(remaining) }
