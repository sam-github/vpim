//
//  FormatHelper.m
//  contacts
//
//  Created by Shane Celis on Fri Jan 10 2003.
//

#import "FormatHelper.h"

BOOL loose = NO;
BOOL strict = NO;
BOOL firstname_first = YES;

/*
  Returns true if the object is nil or the string is empty (e.g. "").
*/
BOOL isNullString(NSString* string) {
    if (string == nil)
        return true;
    else if ([string length] == 0)
        return true;
    // could trim it and check too.
    else
        return false;
}

/*
  Returns the value for a given property and label (purely convenience).
*/
id getValueForLabel(ABPerson *person,
                    NSString *property,
                    NSString *label) {
    id value;
    int count;
    int index;
    ABMultiValue* multi;
    
    value = [person valueForProperty:property];
    if (label == nil) {
        return value; // may be nil
    }
    multi = value;
    count = [multi count];
    for(index = 0; index < count; index++) {
        if ([label isEqualToString: [multi labelAtIndex: index]]) {
            return [multi valueAtIndex: index];
        }
    }
    return nil;
}

/*
  Returns a string value for a given property and label (purely
  convenience); if the value is nil, it'll return a zero-length
  string.
*/
NSString *getStringForLabel(ABPerson *person,
                           NSString *property,
                           NSString *label) {
    NSString *value;
    value = (NSString *) getValueForLabel(person, property, label);
    if (value == nil)
        return @"";
    return value;
    
}

/*
  Parses the format string for FormatHelper tokens.
*/
NSArray *getFormatHelpers(NSString *format) {
    NSMutableArray *array = [NSMutableArray array];
    char *str;
    
    for(str = (char *) [format cString]; *str != NULL; str++) {
        if (str[0] == '%') {
            if (str[1] != NULL) {
                // skip double percents
                if (str[1] == '%') {
                    str++;
                    [array addObject: [[FormatHelper alloc] 
                                          initWithStringLiteral: @"%"]];
                    continue;
                }

                NSString *token = nil;
                if (str[2] != NULL && (str[2] == 'e' || str[2] == 'p' 
                                       || str[2] == 'n' || str[2] == 'i' 
                                       || str[2] == 'a')) {
                    token = [NSString stringWithFormat: @"%%%c%c", 
                                      str[1], str[2]];
                    str++;
                    str++;
                } else {
                    token = [NSString stringWithFormat: @"%%%c", str[1]];
                    str++;
                }
                    
                FormatHelper *helper = [[FormatHelper alloc] 
                                           initWithFormatToken: token];
                if ([helper headerName] == nil) 
                    fprintf(stderr, "warning: invalid format token given \"%s\"\n",
                            [token cString]);
                else
                    [array addObject: helper];

            }
        } else {
            FormatHelper *helper = [[FormatHelper alloc] initWithStringLiteral: 
                                    [NSString stringWithFormat: @"%c", str[0]]];
            [array addObject: helper];
            //printf("got literal \"%c\"\n", str[0]);
        }
    }

    return array;
}


@implementation FormatHelper

/*
  Initialize with a token (e.g. "%fn").
*/
- (id) initWithFormatToken: (NSString *) atoken {

    token = [atoken retain];
    literalValue = nil;
    return self;
}

- (id) initWithStringLiteral: (NSString *) literal {
    token = nil;
    literalValue = [literal retain];
    return self;
}

/*
  Returns a printf token (e.g. "%-12.11s").
*/
- (NSString *) printfToken {
    if (literalValue != nil)
        return @"%s";

    int size = [self fieldSize];

    if (strict)
        return @"%s";
    else if (loose)
        return [NSString stringWithFormat: @"%%-%ds", size];
    else
        return [NSString stringWithFormat: @"%%-%d.%ds", size, size];
}

/*
  Returns the field size for a particular token.
*/
- (int) fieldSize {
    if (literalValue != nil)
        return 1;
    // these values should be in the preferences...
    switch ([self type]) {
    case 'u':
        return 45;
    case 'n':
        switch ([self subtype]) {
        case 'f':
            return 12;
        case 'l':
            return 12;
        case 'n':
            return 12;
        default:
            return 21;
        }
    case 'w':
        return 25;
    case 'i':
        return 19;
    case 'e':
        return 23;
    case 'a': 
        return 45;
    case 'p':
        return 14;
        //     case 'N':
        //         return @"\nNOTE: %s";
    case 'N':
        return 76;
    default:
        return 12;
    }
}

/*
  Returns the type of the token.  For example, the token "%fn" has a
  'n' type.
*/
- (char) type {
    return [token characterAtIndex: ([token length] - 1)];
}

/*
  Returns the subtype of the token.  For example, the token "%fn" has
  a 'f' type.
*/
- (char) subtype {
    return [token characterAtIndex: ([token length] - 2)];
}

/*
  Returns the header for the token.  For example, the token "%n" has a
  header of "NAME".
*/
- (NSString *) headerName {
    if (literalValue != nil)
        return literalValue;

    int subtype = [self subtype];

    switch ([self type]) {
    case 'u':
        return @"UID";
    case 'n':
        switch (subtype) {
        case 'f':
            return @"FIRST";
        case 'l':
            return @"LAST";
        case 'n':
            return @"NICK";
        default:
            return @"NAME";
        }
    case 'p':
        switch (subtype) {
        case 'h':
            return @"HOME";
        case 'w':
            return @"WORK";
        case 'm':
            return @"MOBILE";
        case 'p':
            return @"PAGER";
        case 'f':
            return @"FAX";
        case 'M':
            return @"MAIN";
        case 'o':
            return @"OTHER";
        default:
            return @"PHONE";
        }
    case 'a':
        switch (subtype) {
        case 'h':
            return @"HOME";
        case 'w':
            return @"WORK";
        default:
            return @"ADDRESS";
        }
    case 'e':
        switch (subtype) {
        case 'h':
            return @"HOME";
        case 'w':
            return @"WORK";
        case 'o':
            return @"OTHER";
        default:
            return @"EMAIL";
        }
    case 't':
        return @"TITLE";
    case 'c':
        return @"COMPANY";
    case 'g':
        return @"GROUP";
    case 'w':
        return @"HOMEPAGE";
    case 'b':
        return @"BIRTHDAY";
    case 'i':
        switch (subtype) {
        case 'a':
            return @"AIM";
        case 'y':
            return @"YAHOO";
        case 'j':
            return @"JABBER";
        case 'i':
            return @"ICQ";
        case 'm':
            return @"MSN";
        default:
            return @"IM";
        }
    case 'N':
        return @"";             // Note doesn't have a header (should
                                // come at the end)
    }
    return nil;
}

/*
  Returns the value for a person with this instance's token.
*/
- (NSString *) valueForPerson: (ABPerson *) person {
    return [self valueForPerson: person withToken: token];
}

/*
  Returns the value for a person with a particular token (e.g. "%fn")
*/
- (NSString *) valueForPerson: (ABPerson *) person 
                    withToken: (NSString *) aToken {

    NSString *scratch = nil;          // just a temp value
    //int subtype = [self subtype];
    int length = [aToken length];
    char type = [aToken characterAtIndex: (length - 1)];
    char subtype = [aToken characterAtIndex: (length - 2)];

    if (literalValue != nil)
        return literalValue;

    switch (type) {
    case 'u':
        return [person uniqueId];
    case 'n':
        switch (subtype) {
        case 'f':
            return getStringForLabel(person, kABFirstNameProperty, nil);
        case 'l':
            return getStringForLabel(person, kABLastNameProperty, nil);
        case 'n':
            return getStringForLabel(person, kABNicknameProperty, nil);
        default:
            return [self getNameString: person];
            // Show company name if no first and last name is given.
//             if (isNullString([self valueForPerson: person withToken: @"%fn"])
//                && isNullString([self valueForPerson: person withToken: @"%ln"]))
//                 return [self valueForPerson: person withToken: @"%c"];
//             return [NSString stringWithFormat: @"%@ %@",
//                              [self valueForPerson: person withToken: @"%fn"],
//                              [self valueForPerson: person withToken: @"%ln"]];
        }
    case 'p':
        switch (subtype) {
        case 'h':
            return getStringForLabel(person, 
                                    kABPhoneProperty, 
                                    kABPhoneHomeLabel);
        case 'w':
            return getStringForLabel(person, 
                                    kABPhoneProperty, 
                                    kABPhoneWorkLabel);
        case 'm':
            return getStringForLabel(person, 
                                    kABPhoneProperty, 
                                    kABPhoneMobileLabel);
        case 'M':
            return getStringForLabel(person, 
                                    kABPhoneProperty, 
                                    kABPhoneMainLabel);
        case 'f':
            // We don't differentiate here... I don't think it's worth the effort
            scratch = getStringForLabel(person, 
                                       kABPhoneProperty, 
                                       kABPhoneHomeFAXLabel);
            if (!isNullString(scratch))
                return scratch;
            return getStringForLabel(person, 
                                    kABPhoneProperty, 
                                    kABPhoneWorkFAXLabel);
        case 'p':
            return getStringForLabel(person, 
                                    kABPhoneProperty, 
                                    kABPhonePagerLabel);
        case 'o':
            return getStringForLabel(person, 
                                    kABPhoneProperty, 
                                    kABOtherLabel);
        default:
            return [self valueForPerson: person withTokenPref: 
                             [NSArray arrayWithObjects: @"%hp", @"%wp", @"%mp", 
                                      @"%Mp", @"%pp", @"%fp", @"%op", nil]];
        }
    case 'a':
        switch (subtype) {
        case 'h':
            return [self addressForPerson: person
                         withLabel: kABAddressHomeLabel];
        case 'w':
             return [self addressForPerson: person
                          withLabel: kABAddressWorkLabel];
        case 'o':
             return [self addressForPerson: person
                          withLabel: kABOtherLabel];
        default:
             return [self valueForPerson: person withTokenPref: 
                              [NSArray arrayWithObjects: @"%ha", @"wa", 
                                       @"oa", nil]];
        }
        
    case 'e':
        switch (subtype) {
        case 'h':
            return getStringForLabel(person, 
                                    kABEmailProperty, 
                                    kABEmailHomeLabel);
        case 'w':
            return getStringForLabel(person, 
                                    kABEmailProperty, 
                                    kABEmailWorkLabel);
        case 'o':
            return getStringForLabel(person, 
                                    kABEmailProperty, 
                                    kABOtherLabel);
        default:
            return [self valueForPerson: person withTokenPref: 
                             [NSArray arrayWithObjects: @"%he", @"%we", 
                                      @"%oe", nil]];
        }
    case 't':
        return getStringForLabel(person, 
                                kABJobTitleProperty, 
                                nil);
    case 'c':
        return getStringForLabel(person, 
                                kABOrganizationProperty,
                                nil);
    case 'w':
        return getStringForLabel(person, 
                                kABHomePageProperty,
                                nil);
    case 'b':
        return [getStringForLabel(person, 
                                 kABBirthdayProperty,
                                 nil) description];
    case 'i':
        switch (subtype) {
        case 'a':
            return getStringForLabel(person, 
                                    kABAIMInstantProperty, 
                                    kABAIMHomeLabel);
        case 'y':
            return getStringForLabel(person, 
                                    kABYahooInstantProperty, 
                                    kABYahooHomeLabel);
        case 'j':
            return getStringForLabel(person, 
                                    kABJabberInstantProperty, 
                                    kABJabberHomeLabel);
        case 'i':
            return getStringForLabel(person, 
                                    kABICQInstantProperty, 
                                    kABICQHomeLabel);
        case 'm':
            return getStringForLabel(person, 
                                    kABMSNInstantProperty, 
                                    kABMSNHomeLabel);
        default:
            return [self valueForPerson: person withTokenPref: 
                             [NSArray arrayWithObjects: @"%ai", @"%yi", @"%ji",
                                      @"%ii", @"%mi", nil]];
        }
    case 'g':
        return getStringForLabel(person, kABGroupNameProperty, nil);
            
    case 'N':
        // trim the note string
        scratch = getStringForLabel(person, kABNoteProperty, nil);
        scratch = [scratch stringByTrimmingCharactersInSet: 
                              [NSCharacterSet whitespaceAndNewlineCharacterSet]];

        // make it all fit on one line, if we're not loosely formatting
        if (!loose) {
            int len = [scratch length];
            NSMutableString *temp = [NSMutableString stringWithCapacity: len];

            [temp setString: scratch];
            [temp replaceOccurrencesOfString: @"\n" 
                  withString: @" "
                  options: NSLiteralSearch
                  range: NSMakeRange(0, len)];

            scratch = temp;
        }
            
        return [NSString stringWithFormat: @"\nNOTE: %@", scratch];
    }
    return nil;
}

/*
  Returns value for a person with a set of tokens in order of preference.
*/
- (NSString *) valueForPerson: (ABPerson *) person 
                 withTokenPref: (NSArray *) tokens
{
    NSEnumerator* tokenEnum = [tokens objectEnumerator];
    NSString* atoken;
    NSString* scratch;

    while((atoken = [tokenEnum nextObject]) != nil) {
        scratch = [self valueForPerson: person withToken: atoken];
        if (!isNullString(scratch))
            return scratch;
    }
    return @"";
}

/*
  Returns a string version of the address.
*/
- (NSString *) addressForPerson: (ABPerson *) person
                      withLabel: (NSString *) label 
{
    NSDictionary *dict;
    NSMutableString *address;
    NSString *value;
    dict = (NSDictionary *) getValueForLabel(person,
                                             kABAddressProperty,
                                             label);
    if (dict == nil)
        return @"";
    address = [NSMutableString string];

    if (value = [dict objectForKey: kABAddressStreetKey]) {
        [address appendFormat: @"%@, ", value];
    }

    if (value = [dict objectForKey: kABAddressCityKey]) {
        [address appendFormat: @"%@, ", value];
    }

    if (value = [dict objectForKey: kABAddressStateKey]) {
        [address appendFormat: @"%@ ", value];
    }

    if (value = [dict objectForKey: kABAddressZIPKey]) {
        [address appendFormat: @"%@", value];
    }
    return [NSString stringWithString: address];
}

/*
  Returns the name of the person, or company, taking into account
  whether it should be firstname first or lastname first.
*/
- (NSString *) getNameString: (ABPerson *) person
{
    NSString * firstname;
    NSString * lastname;
    NSString * companyname;
    int flags;

    firstname = getStringForLabel(person, kABFirstNameProperty, nil);
    lastname = getStringForLabel(person, kABLastNameProperty, nil);
    companyname = getStringForLabel(person, kABOrganizationProperty, nil);
    
    if (isNullString(firstname) && isNullString(lastname)) {
        // Show company name if no first and last name is given.
        return companyname;
    }

    flags = [[person valueForProperty: kABPersonFlags] intValue];

    if (flags & kABShowAsCompany) {
        return companyname;
    }
    
    if (flags & kABLastNameFirst || firstname_first == NO) {
        if (isNullString(lastname))
            return firstname;
        else
            return [NSString stringWithFormat: @"%@, %@",
                             lastname,
                             firstname];
    }
    // by default use firstname first
    
    //printf("flags %d\n", flags);
    return [NSString stringWithFormat: @"%@ %@", 
                     firstname, 
                     lastname];
}

@end
