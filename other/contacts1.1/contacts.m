/*
 * contacts.m
 *
 * Makes the Mac OS X address book available from the command-line
 *
 * AddressBook info available from this URL:
 *
 * http://developer.apple.com/techpubs/macosx/AdditionalTechnologies/AddressBook
 *
 * @author Shane Celis <shane@gnufoo.org>
 *
 */

/*
 * Here are the format specifies:
 *
 * %u   unique identifier
 *
 * %n   name (first and last)
 * %fn  first name
 * %ln  last name
 * %nn  nick name
 *
 * %p   phone (whichever comes up first)
 * %hp  home phone
 * %wp  work phone
 * %mp  mobile phone
 * %Mp  main phone
 * %fp  fax phone
 * %op  other phone
 * %pp  pager phone
 *
 * %a   addresss (whichever comes up first)
 * %ha  home address
 * %wa  work address
 *
 * %e   email (whichever comes up first)
 * %he  home email
 * %we  work email
 * %oe  other email
 *
 * %t   title
 * %c   company
 * %g   group
 * %w   homepage/webpage
 *
 * %i   instant messaging
 * %ai  aim IM
 * %yi  Yahoo IM
 * %ji  Jabber IM
 * %ii  ICQ IM
 * %mi  MSN IM
 *
 * %N   note
 *
 * Maybe the best way to do this would be to create a map.  Use the
 * format tag (e.g. "%n") as the key and the header (e.g. "NAME") and
 * the printf format tag (e.g. "%-15s") pair as the value.  This would
 * be a nice solution for _most_ of the entries, however, there are a
 * number of special cases that require more than just a map.
 *
 */

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import <unistd.h>
#import "FormatHelper.h"

// <prototypes>
int usage();

void printPeopleWithFormat(NSArray *people, NSString *format);
void printPeopleAsVcards(NSArray *people);

void showHeader(NSArray* formatters);

int peopleSort(id peep1, id peep2, void *context);

// </prototypes>

// members
BOOL show_headers = YES;
BOOL sort = NO;
BOOL xport = NO;
BOOL utf8 = NO;

// These are declared in FormatHelper.m
extern BOOL loose;
extern BOOL strict;
extern BOOL firstname_first;

/*
  Prints usage and returns an error code of 2.
*/
int usage() {
    fprintf(stderr, "usage: contacts [-hHsmnlSx] [-f format] [search]\n");
    // I don't know if I should make it a full-fledged client.

    //fprintf(stderr, "       contacts -a first-name last-name phone-number\n");

    fprintf(stderr, "      -h displays help (this)\n");
    fprintf(stderr, "      -H suppress header\n");
    fprintf(stderr, "      -s sort list\n");
    fprintf(stderr, "      -m show me\n");
    fprintf(stderr, "      -n displays note below each record\n");
    fprintf(stderr, "      -l loose formatting (doesn't truncate record values)\n");
    fprintf(stderr, "      -S strict formatting (doesn't add space between columns)\n");
    fprintf(stderr, "      -f accepts a format string (see man page)\n");
    fprintf(stderr, "      -x export matching in vCard format\n");
    fprintf(stderr, "      -8 force vCard output to be UTF-8 instead of UTF-16\n");
    fprintf(stderr, "\n");
    fprintf(stderr, "displays contacts from the AddressBook database\n");

    return 2;
}

int main (int argc, char * argv[]) {

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    BOOL show_me = NO;
    BOOL show_all = NO;
    BOOL display_note = NO;
    char ch;
    NSString *format = @"%n %p %i %e";

    while ((ch = getopt(argc, argv, "lSHsnmhf:x8")) != -1)
        switch (ch) {
        case 'l':
            loose = YES;
            break;
        case 'f':
            format = [NSString stringWithCString: optarg];
            break;
        case 'H':
            show_headers = NO;
            break;
        case 'n':
            display_note = YES;
            break;
        case 'm':
            show_me = YES;
            break;
        case 's':
            sort = YES;
            break;
        case 'S':
            strict = YES;
            break;
        case 'x':
            xport = YES;
            break;
        case '8':
             utf8 = YES;
            break;
        case 'h':
        default:
            return usage();
        }
    argc -= optind;
    argv += optind;

    if (argc == 0) 
        show_all = YES;
    if (argc > 1)
        return usage();

    ABAddressBook *AB = [ABAddressBook sharedAddressBook];

    NSArray *peopleFound; 
    
    firstname_first = ([AB defaultNameOrdering] == kABFirstNameFirst ?
                       YES : NO);
    
    if (display_note)
        format = [format stringByAppendingString: @" %N"];

    if (show_me) {
        
        peopleFound = [NSArray arrayWithObjects: [AB me], nil];
    } else if (show_all) {

        peopleFound = [AB people];
    } else {

        // search for the string given
        NSString *searchString = [NSString stringWithCString: argv[0]];

        ABSearchElement *firstName =
            [ABPerson searchElementForProperty:kABFirstNameProperty
                      label:nil
                      key:nil
                      value:searchString
                      comparison:kABContainsSubStringCaseInsensitive];
        //comparison:kABEqualCaseInsensitive];
        
        ABSearchElement *lastName =
            [ABPerson searchElementForProperty:kABLastNameProperty
                      label:nil
                      key:nil
                      value:searchString
                      comparison:kABContainsSubStringCaseInsensitive];

        ABSearchElement *companyName =
            [ABPerson searchElementForProperty:kABOrganizationProperty
                      label:nil
                      key:nil
                      value:searchString
                      comparison:kABContainsSubStringCaseInsensitive];

        ABSearchElement *homeEmail =
            [ABPerson searchElementForProperty:kABEmailProperty
                      label:kABEmailHomeLabel
                      key:nil
                      value:searchString
                      comparison:kABContainsSubStringCaseInsensitive];

        ABSearchElement *workEmail =
            [ABPerson searchElementForProperty:kABEmailProperty
                      label:kABEmailWorkLabel
                      key:nil
                      value:searchString
                      comparison:kABContainsSubStringCaseInsensitive];

        ABSearchElement *aimName =
            [ABPerson searchElementForProperty:kABAIMInstantProperty
                      label:kABAIMHomeLabel
                      key:nil
                      value:searchString
                      comparison:kABContainsSubStringCaseInsensitive];

        ABSearchElement *notes =
            [ABPerson searchElementForProperty:kABAIMInstantProperty
                      label:kABNoteProperty
                      key:nil
                      value:searchString
                      comparison:kABContainsSubStringCaseInsensitive];


        
        ABSearchElement *criteria =
            [ABSearchElement searchElementForConjunction:kABSearchOr
                             children:[NSArray arrayWithObjects:
                                               firstName, 
                                               lastName,
                                               companyName,
                                               homeEmail,
                                               workEmail, 
                                               aimName,
                                               notes,
                                               nil]];
        
        
        peopleFound = [AB recordsMatchingSearchElement: criteria];
    }

    if(xport)
        printPeopleAsVcards(peopleFound);
    else
        printPeopleWithFormat(peopleFound, format);

    [pool release];
    return 0;
}


/*
  Prints the headers from the given formatters.
*/
void showHeader(NSArray* formatters) {
    NSEnumerator *formatEnumerator = [formatters objectEnumerator];
    FormatHelper *formatter;
    while((formatter = [formatEnumerator nextObject]) != nil) {
        printf([[formatter printfToken] cString], 
               [[formatter headerName] cString]);
    }
    printf("\n");

}

/*

module OSX
  class ABPerson
    def vCard
      card = self.vCardRepresentation.bytes

      # The card representation appears to be either ASCII, or UCS-2. If its
      # UCS-2, then the first byte will be 0, so check for this, and convert
      # if necessary.
      #
      # We know it's 0, because the first character in a vCard must be the 'B'
      # of "BEGIN:VCARD", and in UCS-2 all ascii are encoded as a 0 byte
      # followed by the ASCII byte, UNICODE is great.
      if card[0] == 0
        nsstring = OSX::NSString.alloc.initWithCharacters(card, :length, card.size/2)
        card = nsstring.UTF8String

        # TODO: is nsstring.UTF8String == nsstring.to_s  ?
      end
      card
    end
  end
end
*/

/*
  Prints people's vCards.
ASCII vCards just start with "BEGIN:..."
AB on OS X 10.2 had UCS-2, w/ no BOM. On OS X 10.3, there is a BOM.
0xfe 0xff seems to be BOM for UCS-2 vCards
0xef 0xbb 0xbf seems to be BOM after conversion to UTF-8

*/
void printPeopleAsVcards(NSArray *people) {

    ABPerson *person; 
    NSEnumerator *peopleEnum;
    NSString* vcf = 0;
    const char* bytes;
    size_t bytesSz;

    if ([people count] == 0) {
        printf("error: no one found\n");
        exit(1);
    }
  
    peopleEnum = [people objectEnumerator];
    
    while((person = [peopleEnum nextObject]) != nil) {
        NSData* data = [person vCardRepresentation];

        bytes = [data bytes];
        bytesSz = [data length];

        NSStringEncoding codeIn = bytes[0] == 'B' ? NSASCIIStringEncoding : NSUnicodeStringEncoding;

        NSString* str = [[NSString alloc] initWithBytes: (void*)bytes
                                                 length: bytesSz
                                               encoding: codeIn
                                                 ];

        if(vcf) {
          vcf = [vcf stringByAppendingString: str];
        } else {
          vcf = str;
        }
    }

    if(vcf) {
      // ASCII if possible.
      NSData* data = [vcf dataUsingEncoding: NSASCIIStringEncoding];

      if(!data) {
        // Otherwise 16 bit or 8 bit, as requested.
        if(utf8) {
          data = [vcf dataUsingEncoding: NSUTF8StringEncoding ];
        } else {
          data = [vcf dataUsingEncoding: NSUnicodeStringEncoding];
        }
      }
      bytes = [data bytes];
      bytesSz = [data length];
      if(bytes && bytes[0] == '\xef') {
        bytes += 3;
        bytesSz -= 3;
      }
      write(1, bytes, bytesSz);
    }
}


/*
  Prints people using the given format string.  Here's an example
  format string: "%n %ph %pw %pm".
*/
void printPeopleWithFormat(NSArray *people, 
                           NSString *format) {

    ABPerson *person; 
    NSEnumerator *peopleEnum;
    NSEnumerator *formatEnumerator;
    FormatHelper *formatter;
    NSArray *formatters = getFormatHelpers(format);

    if ([formatters count] == 0) {
//        fprintf(stderr, "error: no formatter tokens found\n");
//        exit(3);
    }

    if ([people count] == 0) {
        printf("error: no one found\n");
        exit(1);
    }

    // print the header first    
    if (show_headers) {
        showHeader(formatters);
    }

    if (sort) {

        people = [people sortedArrayUsingFunction: peopleSort 
                         context: [formatters objectAtIndex: 0]];
    }
    
    peopleEnum = [people objectEnumerator];
    
    while((person = [peopleEnum nextObject]) != nil) {
        
        formatEnumerator = [formatters objectEnumerator];

        while((formatter = [formatEnumerator nextObject]) != nil) {
            
            printf([[formatter printfToken] cString], 
                   [[formatter valueForPerson: person] lossyCString]);
        }
        printf("\n");
    }
}

/*
  Sorts people by the FormatHelper given in the context.
*/
int peopleSort(id peep1, id peep2, void *context) {
    ABPerson *p1 = peep1;
    ABPerson *p2 = peep2;

    FormatHelper *formatter = context;

    NSString *n1 = [formatter valueForPerson: p1];
    NSString *n2 = [formatter valueForPerson: p2];

    return [n1 caseInsensitiveCompare: n2];
}

