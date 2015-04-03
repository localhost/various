#!/usr/bin/env ruby

words = {}

ARGF.each_line do |line|
  line.split.each do |word|
  	words[word] ||= 0
  	words[word] += 1
  end
end

words.sort_by(&:last).reverse.each { |pair| puts "#{pair.first} #{pair.last}" }
