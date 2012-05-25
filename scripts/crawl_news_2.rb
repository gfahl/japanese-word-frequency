# part 2: download news pages
require 'open-uri'
require 'uri'
require 'fileutils'

crawl_dir = "downloads/news"

home_page = "http://www.nihonkiin.or.jp/news/"
remaining = File.readlines("downloads/news/remaining.txt")
not_found = []

header = "## begin Metadata\nurl: %s\nretrieval_date: %s\n## end Metadata\n"
delay = 30
prev_request = nil

while !remaining.empty?
  curr = remaining.shift.chomp
  puts "curr = %s" % curr
  path = crawl_dir + "/" + curr["http://".size..-1]
  if File.exist?(path)
    puts "Page already saved"
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
  end
  puts "Remaining: %d, Not found: %d" % [remaining.size, not_found.size]
end
puts "Not found:"
puts not_found
