import Foundation

let bufferSize = 8192

func readline(fd: CMutablePointer<FILE>) -> String {
  var buffer = CChar[](count: bufferSize, repeatedValue: 0)

  fgets(&buffer, CInt(bufferSize), fd)

  var len = 0
  for i in 0..bufferSize {
    if buffer[i] == 0x0a {
      len = i + 1
      break
    }
  }

  return NSString(bytes:buffer, length:len, encoding:NSUTF8StringEncoding)
}

let stdin = NSFileHandle.fileHandleWithStandardInput()
let fd: CMutablePointer<FILE> = fdopen(stdin.fileDescriptor, "r")

var wordsDict = Dictionary<String, Int>()

while true {
  var line = readline(fd)
  if line == "" { break }

  line = (line as NSString).stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
  let words = (line as NSString).componentsSeparatedByString(" ")

  for word in words as String[] {
    if (word != "") {
      if let count = wordsDict[word] {
          wordsDict[word] = count + 1
      } else {
        wordsDict[word] = 1
      }
    }
  }
}

var sortedWords = (wordsDict as NSDictionary).keysSortedByValueUsingSelector("compare:")
sortedWords = (sortedWords as NSArray).reverseObjectEnumerator().allObjects

for word in sortedWords as String[] {
  println("\(wordsDict[word]) \(word)")
}
