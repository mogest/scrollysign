#!/usr/bin/ruby

require 'rubygems'
require 'open-uri'
require 'scrollysign'
require 'json'

loop do
  feed = open("http://api.twitter.com/1/statuses/public_timeline.json").read
  posts = JSON.parse(feed)

  ScrollySign.open("/dev/tty.usbserial-FTEMNHQ2") do |sign|
    text = sign.build_text do |t|
      posts.reject {|post| post['text'] =~ /[\x7f-\xff]/}.each do |post|
        t.control 'red'
        t.text "@#{post["user"]["screen_name"]} "
        t.control 'green'
        t.text post['text']
        t.control 'brown'
        t.text '    **    '
      end
    end

    sign.write_text(text, 'A', 'compressed_rotate')
  end

  sleep 30
end
