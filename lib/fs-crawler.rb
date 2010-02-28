#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "rubygems"
require "rb-inotify"

notifier = INotify::Notifier.new

notifier.watch("rtss-crawler.rb", :all_events) do
  puts "#{notifier.inspect}"
  puts "rtss-crawler.rb was modified!"
end


notifier.run
