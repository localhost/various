#!/usr/bin/env ruby

words = Hash(String, Int32).new(0)

STDIN.each_line do |line|
  line.split.each do |word|
    words[word] += 1
  end
end

words.to_a.sort_by(&.[1]).reverse.each { |pair| puts "#{pair[0]} #{pair[1]}" }
