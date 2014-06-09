@import Foundation;

#define BUFFER_SIZE 8192

@implementation NSMutableDictionary(NSMutableDictionaryExt)

- (void)incrementNumberForKey:(NSString *)key {
    NSNumber *count = [self objectForKey:key];
    count = (count) ? [NSNumber numberWithInt:[count intValue] + 1]
                    : [NSNumber numberWithInt:1];
    [self setObject:count forKey:key];
}

@end

@implementation NSFileHandle(NSFileHandleExt)

- (NSString *)readLine {
    char buffer[BUFFER_SIZE];
    return fgets(buffer, sizeof buffer, stdin)
        ? [NSString stringWithCString:buffer encoding:NSASCIIStringEncoding]
            : @"";
}

@end

int main(void) {
    @autoreleasepool {

        NSMutableDictionary *wordsDict = [[NSMutableDictionary alloc] init];
        NSString *line;
        NSFileHandle *stdin = [NSFileHandle fileHandleWithStandardInput];

        do {
            line = [stdin readLine];
            NSArray *words = [[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@" "];

            [words enumerateObjectsUsingBlock:^(id word, __unused NSUInteger idx, __unused BOOL *stop) {
                if ([word length] > 0)
                    [wordsDict incrementNumberForKey:word];
            }];

        } while ([line length] > 0);

        NSArray *wordList = [wordsDict keysSortedByValueUsingSelector:@selector(compare:)];
        [wordList enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id word, __unused NSUInteger idx, __unused BOOL *stop) {
            printf("%lu %s\n", (unsigned long)[[wordsDict objectForKey:word] intValue], [word cString]);
        }];

    }

    return 0;
}
