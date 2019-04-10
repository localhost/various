# nim c -o:wpnim -d:release --overflowChecks:off wp.nim

import algorithm, sequtils, strutils, tables

# CountTable.sort uses Shell sort and is very slow for millions of words
# so we use a normal table and sort it using algorithm.sort (merge sort)

var words = initTable[string, int]()

for line in stdin.lines:
  for word in line.splitWhitespace:
    if not words.hasKey(word):
      words[word]  = 1
    else:
      words[word] += 1

var ws = toSeq(words.pairs)
ws.sort(proc (x,y: tuple[word: string, cnt: int]): int =
  cmp(y[1], x[1]))

for word in ws.items:
  echo word[0], " ", word[1]
