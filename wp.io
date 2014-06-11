#!/usr/bin/env io

words := Map clone

while(line := File clone standardInput readLine,
  line split foreach(word,
    if(word isEmpty not,
      words atPut(word, words at(word, 0) + 1))))

sorted := words keys sortBy(block(a, b, words at(b) < words at(a)))
sorted foreach(word, (words at(word) .. " " .. word) println)
