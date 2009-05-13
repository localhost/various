#!/usr/bin/env io

/*
 * spell-correct.io by Alex Brem <alex@freQvibez.net>
 * This is my conversion of Peter Norvig's Spelling Corrector
 * (http://www.norvig.com/spell-correct.html) to the Io language 
 */

Importer Regex

words := method(text, text lowercase asMutable allMatchesOfRegex("[a-z]+") map(m, m string))

train := method(features,
  model := Map clone
  features foreach(f, model atPut(f, model atIfAbsentPut(f, 0) + 1)))

NWORDS := train(words(File clone openForReading("words.txt") contents))

alphabet := 97 to(122) map(n, n asCharacter)

edits1 := method(word,
  s := word asMutable allMatchesOfRegex("[a-z]") map(m, m string)
  deletes := 0 to(s size-1) map(i, list(s slice(0, i), s slice(i+1)) flatten join)
  transposes := 0 to(s size-2) map(i, list(s slice(0, i), s at(i+1), s at(i), s slice(i+2)) flatten join)
  inserts := 0 to(s size) map(i, alphabet map(c, list(s slice(0, i), c, s slice(i)) flatten join))
  replaces := 0 to(s size-1) map(i, alphabet map(c, list(s slice(0, i), c, s slice(i+1)) flatten join))
  list(deletes, inserts, replaces, transposes) flatten)

known := method(words,
  if((res := NWORDS select(w, words contains(w))) size != 0, res, nil))

correct := method(word,
  (candidates := known(list(word))) or (candidates := known(edits1(word))) or (candidates := Map clone with(word, 0))
  candidates map(k, v, if(ifNil(c) or v > c, c :=k )) first)

correct("arthur") println
correct("arthurr") println
correct("abthur") println
correct("arhtur") println
