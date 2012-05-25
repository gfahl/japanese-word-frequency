require 'open-uri'
require 'uri'
require 'fileutils'

crawl_dir = "downloads/commentary"
FileUtils.mkdir_p(crawl_dir)

home_page = "http://www.asahi.com/"
start_page = "http://www.asahi.com/igo/meijin/PNDkansen_ichiran.html"
remaining = [start_page]
visited = []
not_found = []

header = "## begin Metadata\nurl: %s\nretrieval_date: %s\n## end Metadata\n"
delay = 30
prev_request = nil

while !remaining.empty?
  curr = remaining.shift
  puts "curr = %s" % curr
  path = crawl_dir + "/" + curr["http://".size..-1]
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
  if page_content
    puts "Looking for links..."
    page_content.scan(/<a href="(.*?)"/).each do |match,|
      link = (URI.parse(home_page) + URI.parse(match)).to_s rescue ""
      link << "index.html" if link[-1] == "/"
      if link =~ Regexp.new("^%s(%s.*\.html?)$" % [Regexp.escape(home_page), Regexp.escape("igo/meijin")])
        remaining << link if !visited.include?(link) && !remaining.include?(link)
      end
    end
    visited << curr
  end
  puts "Visited: %d, Remaining: %d, Not found: %d" % [visited.size, remaining.size, not_found.size]
end
puts "Not found:"
puts not_found
