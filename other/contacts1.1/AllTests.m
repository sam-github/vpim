//
//  AllTests.m
//
//  Created by Shane Celis on Tue Jan 28 2003.
//

#import "AllTests.h"
#import "FormatHelperTests.h"

@implementation AllTests
+ (TestSuite *)suite {
    TestSuite *suite = [TestSuite suiteWithName: @"My Tests"];
    
    // Add your tests here ...
    [suite addTest: [TestSuite suiteWithClass: [FormatHelperTests class]]];

    return suite;
}

@end
