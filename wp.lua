-- Compatible with Lua 5.1+
-- Somewhat balanced between readability and perfomance

local sort   = table.sort
local insert = table.insert
local gmatch = string.gmatch

local words = {}

for line in io.lines() do
  for word in gmatch(line, "%S+") do
    words[word] = (words[word] or 0) + 1
  end
end

local ws = {}
for word, count in pairs(words) do
  insert(ws, {word, count})
end

sort(ws, function(a, b)
  return a[2] > b[2]
end)

for i = 1, #ws do
  local entry = ws[i]
  print(entry[1] .. " " .. entry[2])
end
