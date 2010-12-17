#!/usr/bin/env ruby -wKU

require 'rubygems'
require 'nokogiri'
require 'mechanize'
require 'yajl'
require 'yajl/json_gem'
require "optparse"
require 'active_support'

class Link 

  attr_accessor :link_text, :link_href, :tags, :count, :description
  
  def initialize(bookmark_nokogiri)
    @bookmark = bookmark_nokogiri
    @date_group = @bookmark.search("div.dateGroup").text.strip
    @link = @bookmark.search('h4 a.taggedlink')
    @link_text = @link.text
    @link_href = @link.attr("href")
    @count = @bookmark.search("span.delNavCount").text
    @tags = @bookmark.search("a.tag").map{|x| x.text}
    @description = @bookmark.search("div.description").text.strip
  end

  def to_hash
    hash = {
      :link => {
        :title => @link_text,
        :href => @link_href
      },
      :tags => @tags,
      :description => @description,
      :date => @date_group,
      :count => @count
    }
  end
  
  def to_json
    to_hash.to_json
  end
  
end

class DeliciousScraper

  def initialize
    @options = ActiveSupport::OrderedHash.new
    @options[:delicious_user_name]  = nil
    @op = OptionParser.new do |x|
        x.banner = 'scrape_delicious -u <declicious_user_name> '
        x.separator ''
        x.on('-u', "--username DELICIOUS_USENAME", "username of the delicious user"){ |u| @options[:delicious_user_name] = u }
        x.on('-v', "set verbose mode on"){ |v| @options[:verbose] = v }
        x.on("-h", "--help", "Show this message") { puts @op;  exit }
    end
    begin
      @op.parse!(ARGV)
    rescue OptionParser::ParseError
      $stderr.print "Error: " + $! + "\n"
      puts @op
      exit
    end
    puts @options.to_yaml if @options[:verbose]
    
  end
  
  def delicious_url
    "http://delicious.com/#{@options[:delicious_user_name]}"
  end
  
  def run
    total_count = 0
    puts "Running a scrape on #{delicious_url}" if @options[:verbose]

    agent = Mechanize.new
    page = agent.get(delicious_url)

    more_pages = true

    all_links = []

    while (more_pages) do 
      posts = page.search("#bookmarklist li.post")
      puts "#{posts.length} posts being scraped" if @options[:verbose]
      links = posts.map do |bookmark|
        link = Link.new(bookmark)
        puts link.link_href if @options[:verbose]
        total_count += 1
        link
      end
      all_links << links
      # puts links.to_json
      next_link = page.links_with(:text => 'Next >')
      if next_link.length > 0
        more_pages = true
        page = next_link[0].click
        sleep_time = rand * 2
        puts "Sleeping for #{sleep_time} to be nice to delicous" if @options[:verbose]
        sleep(sleep_time) # don't want to overwhelm them, so be nice and give a pause
      else
        more_pages = false
      end
      puts "#{total_count} processed so far" if @options[:verbose]
    end
    puts all_links.flatten.to_json
  end
  
end



DeliciousScraper.new.run
exit(0)









# page.links.each do |link|
#   puts link.text
# end

# page = agent.get('http://delicious.com/jhofman/')
# page.search("#bookmarklist li.post").each do |bookmark|
#   
#   link = bookmark.search('h4 a.taggedlink')
#   link_text = link.text
#   link_href = link.attr("href")
#   tags = bookmark.search("a.tag").map{|x| x.text}
#   puts tags
#   
#   description = bookmark.search("div.description")
#   puts "#{link_text} - #{link_href}"
#   # puts bookmark
#   puts "=============="
# 
# end

