
#import "FormatHelperTests.h"

@implementation FormatHelperTests

- (void) setUp {
    helper = nil;

}

- (void) tearDown {
    [helper release];
}

- (void)testParsingOfLiterals {
    NSArray *helpers = getFormatHelpers(@"%n %p %i %e");
    // previous behavior with no string literals:
    //[self assertInt: [helpers count] equals: 4];

    // new behavior with string literals:
    [self assertInt: [helpers count] equals: 7];
}

@end
