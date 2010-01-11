# selection.rb

# The Clever Algorithms Project: http://www.CleverAlgorithms.com
# (c) Copyright 2010 Jason Brownlee. All Rights Reserved. 
# This work is licensed under a Creative Commons Attribution-Noncommercial-Share Alike 2.5 Australia License.

# Description:
# Enumerate a listing of algorithms (algorithms.txt) and locate the approximate number of results
# from a number of different search engines and search domains (google). Rank the listing of 
# algorithms and order the list by the ranking and by the algorithms allocated kingdom. Output
# the results into a file (results.txt).
# This script does some screen scraping purely in the name of science.
# Never Use It. (use my results) I Ran it once, collected the results, and analyze forever.


# Development Sources (i hacked this program together):
# Screen Scraping Google with Hpricot and Watir: http://refactormycode.com/codes/673-screen-scraping-google-with-hpricot-and-watir
# Scraping with style: scrAPI toolkit for Ruby: http://labnotes.org/2006/07/11/scraping-with-style-scrapi-toolkit-for-ruby/
# How to get the number of results found for a keyword in google: http://stackoverflow.com/questions/1809976/how-to-get-the-number-of-results-found-for-a-keyword-in-google
# Google AJAX Search API + Ruby: http://chris.mowforth.com/post/146052675/google-ajax-search-api-ruby
# Exploring the Google AJAX Search API: http://sophsec.com/research/exploring_ajax_search.html
# Flash and other Non-Javascript Environments (search API): http://code.google.com/apis/ajaxsearch/documentation/#fonje
# Flash and other Non-Javascript Environments (search docs): http://code.google.com/apis/ajaxsearch/documentation/reference.html#_intro_fonje
# Net::HTTP http://ruby-doc.org/stdlib/libdoc/net/http/rdoc/classes/Net/HTTP.html
# Sample code.Python. Perl. Language Ajax api. Post method. 5000. api limit http://osdir.com/ml/GoogleAJAXAPIs/2009-05/msg00118.html
# Hpricot Basics: http://wiki.github.com/whymirror/hpricot/hpricot-basics

# method:
# 1. prepare algorithm list
# 2. assign kingdoms (maybe?)
# 3. calculate scores (add lots of search sources)
# 4. normalize results?
# 5. output results (by kingdom)
# 6. output selections (top 10's)


require 'rubygems'
module JSON
  VARIANT_BINARY = false # hack - god knows why i need it (I get a VARIANT_BINARY undefined error)
end
require 'json'
require 'net/http'
require 'hpricot'

# Google REST (ajax) API: http://code.google.com/apis/ajaxsearch/documentation/#fonje
def get_approx_google_web_results(keyword)
  http = Net::HTTP.new('ajax.googleapis.com', 80)
  header = {'content-type'=>'application/x-www-form-urlencoded', 'charset'=>'UTF-8'}
  path = "/ajax/services/search/web?v=1.0&q=#{keyword}&rsz=small"
  resp, data = http.request_get(path, header)
  rs = JSON.parse(data)
  return 0 if rs.nil? or rs['responseData'].nil? or rs['responseData']['cursor'].nil? or rs['responseData']['cursor']['estimatedResultCount'].nil?
  return rs['responseData']['cursor']['estimatedResultCount']
end

# Google REST (ajax) API: http://code.google.com/apis/ajaxsearch/documentation/#fonje
def get_approx_google_book_results(keyword)
  http = Net::HTTP.new('ajax.googleapis.com', 80)
  header = {'content-type'=>'application/x-www-form-urlencoded', 'charset'=>'UTF-8'}
  path = "/ajax/services/search/books?v=1.0&q=#{keyword}&rsz=small"
  resp, data = http.request_get(path, header)
  rs = JSON.parse(data)
  return 0 if rs.nil? or rs['responseData'].nil? or rs['responseData']['cursor'].nil? or rs['responseData']['cursor']['estimatedResultCount'].nil?
  return rs['responseData']['cursor']['estimatedResultCount']
end

# http://scholar.google.com.au/scholar?q=%22genetic+algorithm%22&hl=en&btnG=Search&as_sdt=2001&as_sdtp=on
def get_approx_google_scholar_results(keyword)
  http = Net::HTTP.new('scholar.google.com.au', 80)
  header = {}
  path = "/scholar?q=#{keyword}&hl=en&btnG=Search&as_sdt=2001&as_sdtp=on"
  resp, data = http.request_get(path, header)
  doc = Hpricot(data)
  rs = doc.search("//td[@bgcolor='#dcf6db']/font/b")
  return 0 if rs.nil? or rs.size!=5 # no results or unexpected results
  rs = rs[3].inner_html.gsub(',', '') # strip comma    
  return rs
end

# http://springerlink.com/home/main.mpx
# http://springerlink.com/content/?k=%22genetic+algorithm%22
def get_approx_springer_results(keyword)
  http = Net::HTTP.new('springerlink.com', 80)
  header = {}
  path = "/content/?k=#{keyword}"
  resp, data = http.request_get(path, header)
  doc = Hpricot(data)
  rs = doc.search("//span[@id='ctl00_PageSidebar_ctl01_Sidebarplaceholder1_StartsWith_ResultsCountLabel']")
  return 0 if rs.nil? # no results
  rs = rs.first.inner_html
  rs = rs.split(' ').first.gsub(',', '') # strip comma
  return rs
end

# http://www.scirus.com/
# http://www.scirus.com/srsapp/search?q=%22genetic+algorithm%22&t=all&sort=0&g=s
def get_approx_scirus_results(keyword)
  http = Net::HTTP.new('scirus.com', 80)
  header = {'User-Agent'=>'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.0.1) Gecko/20060111 Firefox/1.5.0.1'}
  path = "/srsapp/search?q=#{keyword}&t=all&sort=0&g=s"
  resp, data = http.request_get(path, header)
  return 0 if data.include?("Sorry, your search has not produced any results.")
  doc = Hpricot(data)
  rs = doc.search("//div[@class='headerAllText']")
  return 0 if rs.nil? # no results
  rs = rs.first.inner_html
  rs = rs.split(' ')[2].gsub(',', '') # strip comma
  return rs
end

def get_results(algorithm_name)  
  # spaces to plus, lowercase, quote using %22 - good for all search services used
  keyword = algorithm_name.gsub(/ /, "+")
  keyword = "%22#{keyword.downcase}%22"
  
  # scores = {}
  # # Google Web Search
  # scores['google_web'] = get_approx_google_web_results(keyword)
  # # Google Book Search
  # scores['google_book'] = get_approx_google_book_results(keyword)
  # # Google Scholar Search
  # scores['google_scholar'] = get_approx_google_scholar_results(keyword)
  # # Springer Article Search
  # scores['springer'] = get_approx_springer_results(keyword)
  # # Scirus Search
  # scores['scirus'] = get_approx_scirus_results(keyword)
  
  scores = []
  # Google Web Search
  scores << get_approx_google_web_results(keyword)
  # Google Book Search
  scores << get_approx_google_book_results(keyword)
  # Google Scholar Search
  scores << get_approx_google_scholar_results(keyword)
  # Springer Article Search
  scores << get_approx_springer_results(keyword)
  # Scirus Search
  scores << get_approx_scirus_results(keyword)
  
  return scores
end

def timer
  start = Time.now
  yield
  Time.now - start
end

# calculate results
if File.exists?("./results.txt") 
  puts "Results already available, not generating."
else
  puts "No existing results, generating...(will take a while - upto 10sec per algorithm)"
  # load the list of algorithms
  algorithms_list = IO.readlines("./algorithms.txt")
  # rank, push results to disk each loop in case we crash
  results = File.new("./results.txt", "w")
  
  algorithms_list.each_with_index do |line, i|
    algorithm_name, scores = line.split(',')[1].strip, nil
    # calculate scores
    clock = timer{scores = get_results(algorithm_name)}
    results.puts("#{line.strip},#{scores.join(",")}")
    results.flush
    puts(" > #{(i+1)}/#{algorithms_list.size}: #{algorithm_name}, #{clock.to_i} seconds, rank=#{scores['rank']}")
  end
  
  results.close
end


# normalization
if File.exists?("./results_normalized.txt") 
  puts " > skipping normalization results, already exists"  
else
  puts " > outputting normalization results"
  
  raw = IO.readlines("./results.txt")
  # array of arrays
  algorithms_list = []
  raw.each { |line| algorithms_list<<line.split(',')}
  Infinity = 1.0/0
  normalized_scores = Array.new(5) {|i| [10000.0, 0.0]} 
  algorithms_list.each do |row|
    # calculate min/max
    row[2..6].each_with_index do |v, i|
      normalized_scores[i-1][0] = v if v.to_f < normalized_scores[i-1][0].to_f
      normalized_scores[i-1][1] = v if v.to_f > normalized_scores[i-1][1].to_f
    end
  end
  
  # output normalized results
  results = File.new("./results_normalized.txt", "w")
  algorithms_list.each do |algorithm|
    scores = []
    algorithm[2..6].each_with_index do |v,i|
      # (v-min)/(max-min) 
      a = (v.to_f - normalized_scores[i][0].to_f) / ( normalized_scores[i][1].to_f - normalized_scores[i][0].to_f)
      scores << a
      puts "ERROR!!!! v=#{v}, min=#{normalized_scores[i][0]}, max=#{normalized_scores[i][1]}" if a>1.0||a<0.0
    end
    # calculate rank
    rank = scores.inject {|sum, n| sum + n } 
    results.puts("#{algorithm[0]},#{algorithm[1]},#{scores.join(",")},#{rank}")
  end  
  results.close
end


# The Fisher-Yates shuffle: http://en.wikipedia.org/wiki/Knuth_shuffle
def shuffle!(array)
  n = array.length
  for i in 0...n
    r = rand(n-i) + i
    array[r], array[i] = array[i], array[r]
  end
  return array
end


# prepare data structures
raw = IO.readlines("./results_normalized.txt")
# array of arrays
algorithms_list = []
raw.each { |line| algorithms_list<<line.split(',')}
shuffle!(algorithms_list)
# hash of arrays by kingdom
data = {}
algorithms_list.each do |row|
  row.collect! {|v| v.strip}
  data[row[0]] = [] if !data.has_key?(row[0])
  data[row[0]] << row[1..7]
end

# normalization

# organized results, suitable for presenting
if File.exists?("./results_organized.txt") 
  puts " > skipping organized results, already exists"  
else
  puts " > outputting organized results"
  results = File.new("./results_organized.txt", "w")
  data.each_pair do |key, value| 
    value.sort {|x,y| y[7].to_f <=> x[7].to_f} # descending by rank
    results.puts "\nKingdom: #{key} (#{value.size})"
    value.each_with_index do |v, i|
      results.puts v.join(" & ")
    end
  end
  
  results.close
end


puts "Generating statistics..."
puts "------------------------------"
# overall top algorithms
puts "Top 10 Algorithms, Overall:"
algorithms_list.sort {|x,y| y[7].to_f <=> x[7].to_f} # descending by rank
top = 0
algorithms_list.each_with_index do |v, i|
  break if top>=10 # bounded
  if v[0] != "Subfield" 
    puts "#{(top+1)} #{v[1]}"
    top +=1
  end
end
puts "------------------------------"

# process each kingdom
data.each_pair do |key, value| 
  value.sort {|x,y| y[2].to_f <=> x[2].to_f} # descending by rank
  # print top 10
  puts "Top 10 Algorithms for #{key}: (of #{value.size})"
  value.each_with_index do |v, i|
    break if i>=10
    puts "#{(i+1)} #{v[0]}"
  end
  puts "------------------------------"
end