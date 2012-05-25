require 'open-uri'
require 'uri'
require 'fileutils'
require 'nokogiri'

crawl_dir = "downloads/wikipedia"
FileUtils.mkdir_p(crawl_dir)

home_page = "http://ja.wikipedia.org/"
start_page = "http://ja.wikipedia.org/wiki/Category:%E5%9B%B2%E7%A2%81"
remaining = [start_page]
visited = []
not_found = []

header = "## begin Metadata\nurl: %s\nretrieval_date: %s\n## end Metadata\n"
delay = 30
prev_request = nil

while !remaining.empty?
  curr = remaining.shift
  puts "curr = %s" % curr
  path = crawl_dir + "/" + curr["http://".size..-1][0..149].gsub(/[:\?]/, "_") + ".html"
  page_content =
    if File.exist?(path)
      puts "Page already saved"
      File.read(path)
    else
      puts "Waiting..."
      sleep([0, delay - (Time.now - prev_request)].max) if prev_request
      puts "Downloading..."
      s =
        begin
          open(curr).read
        rescue Exception => e
          case e.message when /404/ then nil else raise e end
        end
      prev_request = Time.now
      if s
        FileUtils.mkdir_p(File.dirname(path))
        File.open(path, "w") { |f| f.puts(header % [curr, prev_request] + s) }
      else
        not_found << curr
      end
      s
    end
  visited << curr if page_content
  if page_content && curr =~ /Category:/
    puts "Looking for links..."
    doc = Nokogiri.HTML(page_content)
    doc.xpath("//div[@id='mw-subcategories' or @id='mw-pages']//a").each do |node|
      link = (URI.parse(home_page) + URI.parse(node['href'])).to_s
      link << "index.html" if link[-1] == "/"
      remaining << link if !visited.include?(link) && !remaining.include?(link)
    end
  end
  puts "Visited: %d, Remaining: %d, Not found: %d" % [visited.size, remaining.size, not_found.size]
end
puts "Not found:"
puts not_found
