#!/usr/bin/env ruby

$:.unshift File.dirname($0)

require 'vpim/rrule'
require 'test/unit'

require 'pp'

class Date
  alias :inspect :to_s
end

class TestRrule < Test::Unit::TestCase

  # Comment out these if you want printing!
  def puts(*args)
  end

  def pp(*args)
  end

  def parse_vec(vec)
    pp  vec
    vec = vec.gsub(/#.*\(/, '(')
    pp  vec
    vec = vec.split("\n")
    pp  vec
    ovec = []

    vec.each do |v|
      time = v[0,18]
      dates = v[18,v.length - 18]

      pp time
      pp dates

      time.gsub!(/\((\d\d\d\d) (\d):/) { "(#{$1} 0#{$2}:" }
      dates.split(';').each do |mondays|
        mon, days = mondays.split(' ')

        #      debug mon
        #      debug days
        days.split(',').each do |d|
          #        debug d
          r = d.split '-'
          #        debug r
          case r.length
          when 1 then r = [ r[0].to_i ]
          when 2 then r = r[0].to_i .. r[1].to_i
          else
            raise "don't grok #{d}"
          end
          r.each do |d0|
            #          debug time, mon, d, d0
            ovec << sprintf("%s%s %.2d", time, mon, d0)
          end
        end
      end
    end

    ovec
  end

  def Test(rule, dtstart = nil, expected = nil)
    puts "---> #{rule}"
    puts "     #{dtstart}" if dtstart

    expected = parse_vec(expected)

    pp expected.length

    start = Time.now

    if dtstart
      start = Vpim::Rrule.time_from_rfc2425(dtstart)
    end

    rrule = Vpim::Rrule.new(start, rule)

    # debug rrule

    #  count = 1
    #  rrule.each do |t|
    #    puts format("count=%3d %s", count, t.to_s)
    #    count += 1
    #  end

    got = rrule.map { |t|
      t.strftime("(%Y %I:%M %p %Z)%B %d")
    }

    if expected && got != expected
      puts "length: got=#{got.length} expected=#{expected.length}"
      (0..expected.length).each do |i|
        if(got[i] != expected[i])
          puts sprintf("%d: %34s %s %s", i, got[i], got[i] == expected[i] ? '==' : '!=', expected[i])
        end
      end
      p got
      p expected
    end
    assert_equal(expected, got)
  end

def test_byday
Test(
  'FREQ=YEARLY;COUNT=5;BYDAY=TU,TH',
  '20060506T090000',
  <<VEC
#   ==> (1998 9:00 AM EST)January 1-31
#       (1999 9:00 AM EST)January 1-31
#       (2000 9:00 AM EST)January 1-30
VEC
  )
end

def test_rfc2445_examples

# Daily for 10 occurrences:
#
#   DTSTART;TZID=US-Eastern:19970902T090000
#   RRULE:FREQ=DAILY;COUNT=10
#
#   ==> (1997 9:00 AM EDT)September 2-11

Test(
  'FREQ=DAILY;COUNT=10',
  '19970902T090000',
  '#   ==> (1997 9:00 AM EDT)September 2-11'
  )

# Daily until December 24, 1997:
#
#   DTSTART;TZID=US-Eastern:19970902T090000
#   RRULE:FREQ=DAILY;UNTIL=19971224T000000Z
#
#   ==> (1997 9:00 AM EDT)September 2-30;October 1-25
#       (1997 9:00 AM EST)October 26-31;November 1-30;December 1-23

Test(
  'FREQ=DAILY;UNTIL=19971224T000000Z',
  '19970902T090000',
  <<VEC
#   ==> (1997 9:00 AM EDT)September 2-30;October 1-25
#       (1997 9:00 AM EST)October 26-31;November 1-30;December 1-23
VEC
  );

# Every other day - forever:
#
#   DTSTART;TZID=US-Eastern:19970902T090000
#   RRULE:FREQ=DAILY;INTERVAL=2
#   ==> (1997 9:00 AM EDT)September2,4,6,8...24,26,28,30;
#        October 2,4,6...20,22,24
#       (1997 9:00 AM EST)October 26,28,30;November 1,3,5,7...25,27,29;
#        Dec 1,3,...

Test(
  'FREQ=DAILY;INTERVAL=2;count=27',
  '19970902T090000',
  <<VEC
#   ==> (1997 9:00 AM EDT)September 2,4,6,8,10,12,14,16,18,20,22,24,26,28,30;October 2,4,6,8,10,12,14,16,18,20,22,24
VEC
  )

# Every 10 days, 5 occurrences:
#
#   DTSTART;TZID=US-Eastern:19970902T090000
#   RRULE:FREQ=DAILY;INTERVAL=10;COUNT=5
#
#   ==> (1997 9:00 AM EDT)September 2,12,22;October 2,12

Test(
  'FREQ=DAILY;COUNT=5;Interval=10',
  '19970902T090000',
  <<VEC
#   ==> (1997 9:00 AM EDT)September 2,12,22;October 2,12
VEC
  )

#
# Everyday in January, for 3 years:
#
#   DTSTART;TZID=US-Eastern:19980101T090000
#   RRULE:FREQ=YEARLY;UNTIL=20000131T090000Z;
#    BYMONTH=1;BYDAY=SU,MO,TU,WE,TH,FR,SA
#   or
#   RRULE:FREQ=DAILY;UNTIL=20000131T090000Z;BYMONTH=1
#
#   ==> (1998 9:00 AM EDT)January 1-31
#       (1999 9:00 AM EDT)January 1-31
#       (2000 9:00 AM EDT)January 1-31

# FIXME -
# I believe the UNTIL time, being in UTC, is BEFORE (2000 9:00 AM
# EDT)January 31 , so the last date in the result vector is not valid.
#
# Also, January is in EST, not EDT!

Test(
  'FREQ=YEARLY;UNTIL=20000131T090000Z;BYMONTH=1;BYDAY=SU,MO,TU,WE,TH,FR,SA',
  '19980101T090000',
  <<VEC
#   ==> (1998 9:00 AM EST)January 1-31
#       (1999 9:00 AM EST)January 1-31
#       (2000 9:00 AM EST)January 1-30
VEC
  )

Test(
  'FREQ=DAILY;UNTIL=20000131T090000Z;BYMONTH=1',
  '19980101T090000',
  <<VEC
#   ==> (1998 9:00 AM EST)January 1-31
#       (1999 9:00 AM EST)January 1-31
#       (2000 9:00 AM EST)January 1-30
VEC
  )

# Weekly for 10 occurrences
#
#   DTSTART;TZID=US-Eastern:19970902T090000
#   RRULE:FREQ=WEEKLY;COUNT=10
#
#   ==> (1997 9:00 AM EDT)September 2,9,16,23,30;October 7,14,21
#       (1997 9:00 AM EST)October 28;November 4

Test(
  'FREQ=WEEKLY;COUNT=10',
  '19970902T090000',
  <<VEC
#   ==> (1997 9:00 AM EDT)September 2,9,16,23,30;October 7,14,21
#       (1997 9:00 AM EST)October 28;November 4
VEC
  )

# Weekly until December 24, 1997
#
#   DTSTART;TZID=US-Eastern:19970902T090000
#   RRULE:FREQ=WEEKLY;UNTIL=19971224T000000Z
#
#   ==> (1997 9:00 AM EDT)September 2,9,16,23,30;October 7,14,21
#       (1997 9:00 AM EST)October 28;November 4,11,18,25;December 2,9,16,23

Test(
  'FREQ=WEEKLY;UNTIL=19971224T000000Z',
  '19970902T090000',
  <<VEC
#   ==> (1997 9:00 AM EDT)September 2,9,16,23,30;October 7,14,21
#       (1997 9:00 AM EST)October 28;November 4,11,18,25;December 2,9,16,23
VEC
  )

# Every other week - forever:
#
#   DTSTART;TZID=US-Eastern:19970902T090000
#   RRULE:FREQ=WEEKLY;INTERVAL=2;WKST=SU
#
#   ==> (1997 9:00 AM EDT)September 2,16,30;October 14
#       (1997 9:00 AM EST)October 28;November 11,25;December 9,23
#       (1998 9:00 AM EST)January 6,20;February
#   ...

Test(
  'FREQ=WEEKLY;INTERVAL=2;WKST=SU;count=11',
  '19970902T090000',
  <<VEC
#   ==> (1997 9:00 AM EDT)September 2,16,30;October 14
#       (1997 9:00 AM EST)October 28;November 11,25;December 9,23
#       (1998 9:00 AM EST)January 6,20
VEC
  )


# Weekly on Tuesday and Thursday for 5 weeks:
#
#  DTSTART;TZID=US-Eastern:19970902T090000
#  RRULE:FREQ=WEEKLY;UNTIL=19971007T000000Z;WKST=SU;BYDAY=TU,TH
#  or
#
#  RRULE:FREQ=WEEKLY;COUNT=10;WKST=SU;BYDAY=TU,TH
#
#  ==> (1997 9:00 AM EDT)September 2,4,9,11,16,18,23,25,30;October 2

=begin
Weekly/byday not implemented

Test(
  'FREQ=WEEKLY;COUNT=10',
  '19970902T090000',
  [
    '(1997 09:00 AM EDT)September 02',
    '(1997 09:00 AM EDT)September 04',
    '(1997 09:00 AM EDT)September 09',
    '(1997 09:00 AM EDT)September 11',
    '(1997 09:00 AM EDT)September 16',
    '(1997 09:00 AM EDT)September 18',
    '(1997 09:00 AM EDT)September 23',
    '(1997 09:00 AM EDT)September 25',
    '(1997 09:00 AM EDT)September 30',
    '(1997 09:00 AM EDT)October 02',
  ]
  )
=end

# Every other week on Monday, Wednesday and Friday until December 24,
# 1997, but starting on Tuesday, September 2, 1997:
#
#   DTSTART;TZID=US-Eastern:19970902T090000
#   RRULE:FREQ=WEEKLY;INTERVAL=2;UNTIL=19971224T000000Z;WKST=SU;
#    BYDAY=MO,WE,FR
#   ==> (1997 9:00 AM EDT)September 2,3,5,15,17,19,29;October
#   1,3,13,15,17
#       (1997 9:00 AM EST)October 27,29,31;November 10,12,14,24,26,28;
#                         December 8,10,12,22
#
# Every other week on Tuesday and Thursday, for 8 occurrences:
#
#   DTSTART;TZID=US-Eastern:19970902T090000
#   RRULE:FREQ=WEEKLY;INTERVAL=2;COUNT=8;WKST=SU;BYDAY=TU,TH
#
#   ==> (1997 9:00 AM EDT)September 2,4,16,18,30;October 2,14,16
#
# Monthly on the 1st Friday for ten occurrences:
#
#   DTSTART;TZID=US-Eastern:19970905T090000
#   RRULE:FREQ=MONTHLY;COUNT=10;BYDAY=1FR
#
#   ==> (1997 9:00 AM EDT)September 5;October 3
#       (1997 9:00 AM EST)November 7;Dec 5
#       (1998 9:00 AM EST)January 2;February 6;March 6;April 3
#       (1998 9:00 AM EDT)May 1;June 5

Test(
  'FREQ=MONTHLY;COUNT=10;BYDAY=1FR',
  '19970905T090000',
  <<VEC
#   ==> (1997 9:00 AM EDT)September 5;October 3
#       (1997 9:00 AM EST)November 7;December 5
#       (1998 9:00 AM EST)January 2;February 6;March 6;April 3
#       (1998 9:00 AM EDT)May 1;June 5
VEC
  )


# Monthly on the 1st Friday until December 24, 1997:
#
#   DTSTART;TZID=US-Eastern:19970905T090000
#   RRULE:FREQ=MONTHLY;UNTIL=19971224T000000Z;BYDAY=1FR
#
#   ==> (1997 9:00 AM EDT)September 5;October 3
#       (1997 9:00 AM EST)November 7;December 5

Test(
  'FREQ=MONTHLY;UNTIL=19971224T000000Z;BYDAY=1FR',
  '19970905T090000',
  <<VEC
#   ==> (1997 9:00 AM EDT)September 5;October 3
#       (1997 9:00 AM EST)November 7;December 5
VEC
  )

# Every other month on the 1st and last Sunday of the month for 10
# occurrences:
#
#   DTSTART;TZID=US-Eastern:19970907T090000
#   RRULE:FREQ=MONTHLY;INTERVAL=2;COUNT=10;BYDAY=1SU,-1SU
#
#   ==> (1997 9:00 AM EDT)September 7,28
#       (1997 9:00 AM EST)November 2,30
#       (1998 9:00 AM EST)January 4,25;March 1,29
#       (1998 9:00 AM EDT)May 3,31

Test(
  'FREQ=MONTHLY;INTERVAL=2;COUNT=10;BYDAY=1SU,-1SU',
  '19970907T090000',
  <<VEC
#   ==> (1997 9:00 AM EDT)September 7,28
#       (1997 9:00 AM EST)November 2,30
#       (1998 9:00 AM EST)January 4,25;March 1,29
#       (1998 9:00 AM EDT)May 3,31
VEC
  )

# Monthly on the second to last Monday of the month for 6 months:
#
#   DTSTART;TZID=US-Eastern:19970922T090000
#   RRULE:FREQ=MONTHLY;COUNT=6;BYDAY=-2MO
#
#   ==> (1997 9:00 AM EDT)September 22;October 20
#       (1997 9:00 AM EST)November 17;December 22
#       (1998 9:00 AM EST)January 19;February 16

Test(
  'FREQ=MONTHLY;COUNT=6;BYDAY=-2MO',
  '19970922T090000',
  <<VEC
#   ==> (1997 9:00 AM EDT)September 22;October 20
#       (1997 9:00 AM EST)November 17;December 22
#       (1998 9:00 AM EST)January 19;February 16
VEC
  )

# Monthly on the third to the last day of the month, forever:
#
#   DTSTART;TZID=US-Eastern:19970928T090000
#   RRULE:FREQ=MONTHLY;BYMONTHDAY=-3
#
#   ==> (1997 9:00 AM EDT)September 28
#       (1997 9:00 AM EST)October 29;November 28;December 29
#       (1998 9:00 AM EST)January 29;February 26
#   ...

Test(
  'FREQ=MONTHLY;BYMONTHDAY=-3;count=6',
  '19970928T090000',
  <<VEC
#   ==> (1997 9:00 AM EDT)September 28
#       (1997 9:00 AM EST)October 29;November 28;December 29
#       (1998 9:00 AM EST)January 29;February 26
VEC
  )

# Monthly on the 2nd and 15th of the month for 10 occurrences:
#
#   DTSTART;TZID=US-Eastern:19970902T090000
#   RRULE:FREQ=MONTHLY;COUNT=10;BYMONTHDAY=2,15
#
#   ==> (1997 9:00 AM EDT)September 2,15;October 2,15
#       (1997 9:00 AM EST)November 2,15;December 2,15
#       (1998 9:00 AM EST)January 2,15

Test(
  'FREQ=MONTHLY;COUNT=10;BYMONTHDAY=2,15',
  '19970902T090000',
  <<VEC
#   ==> (1997 9:00 AM EDT)September 2,15;October 2,15
#       (1997 9:00 AM EST)November 2,15;December 2,15
#       (1998 9:00 AM EST)January 2,15
VEC
  )

# Monthly on the first and last day of the month for 10 occurrences:
#
#   DTSTART;TZID=US-Eastern:19970930T090000
#   RRULE:FREQ=MONTHLY;COUNT=10;BYMONTHDAY=1,-1
#
#   ==> (1997 9:00 AM EDT)September 30;October 1
#       (1997 9:00 AM EST)October 31;November 1,30;December 1,31
#       (1998 9:00 AM EST)January 1,31;February 1

Test(
  'FREQ=MONTHLY;COUNT=10;BYMONTHDAY=1,-1',
  '19970930T090000',
  <<VEC
#   ==> (1997 9:00 AM EDT)September 30;October 1
#       (1997 9:00 AM EST)October 31;November 1,30;December 1,31
#       (1998 9:00 AM EST)January 1,31;February 1
VEC
  )

# Every 18 months on the 10th thru 15th of the month for 10
# occurrences:
#
#   DTSTART;TZID=US-Eastern:19970910T090000
#   RRULE:FREQ=MONTHLY;INTERVAL=18;COUNT=10;BYMONTHDAY=10,11,12,13,14,
#    15
#
#   ==> (1997 9:00 AM EDT)September 10,11,12,13,14,15
#       (1999 9:00 AM EST)March 10,11,12,13

Test(
  'FREQ=MONTHLY;INTERVAL=18;COUNT=10;BYMONTHDAY=10,11,12,13,14,15',
  '19970910T090000',
  <<VEC
#   ==> (1997 9:00 AM EDT)September 10,11,12,13,14,15
#       (1999 9:00 AM EST)March 10,11,12,13
VEC
  )

# Every Tuesday, every other month:
#
#   DTSTART;TZID=US-Eastern:19970902T090000
#   RRULE:FREQ=MONTHLY;INTERVAL=2;BYDAY=TU
#
#   ==> (1997 9:00 AM EDT)September 2,9,16,23,30
#       (1997 9:00 AM EST)November 4,11,18,25
#       (1998 9:00 AM EST)January 6,13,20,27;March 3,10,17,24,31
#   ...

Test(
  'FREQ=MONTHLY;INTERVAL=2;BYDAY=TU;count=18',
  '19970902T090000',
  <<VEC
#   ==> (1997 9:00 AM EDT)September 2,9,16,23,30
#       (1997 9:00 AM EST)November 4,11,18,25
#       (1998 9:00 AM EST)January 6,13,20,27;March 3,10,17,24,31
VEC
  )

# Yearly in June and July for 10 occurrences:
#
#   DTSTART;TZID=US-Eastern:19970610T090000
#   RRULE:FREQ=YEARLY;COUNT=10;BYMONTH=6,7
#   ==> (1997 9:00 AM EDT)June 10;July 10
#       (1998 9:00 AM EDT)June 10;July 10
#       (1999 9:00 AM EDT)June 10;July 10
#       (2000 9:00 AM EDT)June 10;July 10
#       (2001 9:00 AM EDT)June 10;July 10
#   Note: Since none of the BYDAY, BYMONTHDAY or BYYEARDAY components
#   are specified, the day is gotten from DTSTART

Test(
  'FREQ=YEARLY;COUNT=10;BYMONTH=6,7',
  '19970610T090000',
  <<VEC
#   ==> (1997 9:00 AM EDT)June 10;July 10
#       (1998 9:00 AM EDT)June 10;July 10
#       (1999 9:00 AM EDT)June 10;July 10
#       (2000 9:00 AM EDT)June 10;July 10
#       (2001 9:00 AM EDT)June 10;July 10
VEC
  )

# Every other year on January, February, and March for 10 occurrences:
#
#   DTSTART;TZID=US-Eastern:19970310T090000
#   RRULE:FREQ=YEARLY;INTERVAL=2;COUNT=10;BYMONTH=1,2,3
#
#   ==> (1997 9:00 AM EST)March 10
#       (1999 9:00 AM EST)January 10;February 10;March 10
#       (2001 9:00 AM EST)January 10;February 10;March 10
#       (2003 9:00 AM EST)January 10;February 10;March 10

Test(
  'FREQ=YEARLY;INTERVAL=2;COUNT=10;BYMONTH=1,2,3',
  '19970310T090000',
  <<VEC
#   ==> (1997 9:00 AM EST)March 10
#       (1999 9:00 AM EST)January 10;February 10;March 10
#       (2001 9:00 AM EST)January 10;February 10;March 10
#       (2003 9:00 AM EST)January 10;February 10;March 10
VEC
  )

# Every 3rd year on the 1st, 100th and 200th day for 10 occurrences:
#
#   DTSTART;TZID=US-Eastern:19970101T090000
#   RRULE:FREQ=YEARLY;INTERVAL=3;COUNT=10;BYYEARDAY=1,100,200
#
#   ==> (1997 9:00 AM EST)January 1
#       (1997 9:00 AM EDT)April 10;July 19
#       (2000 9:00 AM EST)January 1
#       (2000 9:00 AM EDT)April 9;July 18
#       (2003 9:00 AM EST)January 1
#       (2003 9:00 AM EDT)April 10;July 19
#       (2006 9:00 AM EST)January 1

Test(
  'FREQ=YEARLY;INTERVAL=3;COUNT=10;BYYEARDAY=1,100,200',
  '19970101T090000',
  <<VEC
#   ==> (1997 9:00 AM EST)January 1
#       (1997 9:00 AM EDT)April 10;July 19
#       (2000 9:00 AM EST)January 1
#       (2000 9:00 AM EDT)April 9;July 18
#       (2003 9:00 AM EST)January 1
#       (2003 9:00 AM EDT)April 10;July 19
#       (2006 9:00 AM EST)January 1
VEC
  )

# Every 20th Monday of the year, forever:
#   DTSTART;TZID=US-Eastern:19970519T090000
#   RRULE:FREQ=YEARLY;BYDAY=20MO
#
#   ==> (1997 9:00 AM EDT)May 19
#       (1998 9:00 AM EDT)May 18
#       (1999 9:00 AM EDT)May 17
#   ...

Test(
  'FREQ=YEARLY;BYDAY=20MO;count=3',
  '19970519T090000',
  <<VEC
#   ==> (1997 9:00 AM EDT)May 19
#       (1998 9:00 AM EDT)May 18
#       (1999 9:00 AM EDT)May 17
VEC
)

# Monday of week number 20 (where the default start of the week is
# Monday), forever:
#
#   DTSTART;TZID=US-Eastern:19970512T090000
#   RRULE:FREQ=YEARLY;BYWEEKNO=20;BYDAY=MO
#
#   ==> (1997 9:00 AM EDT)May 12
#       (1998 9:00 AM EDT)May 11
#       (1999 9:00 AM EDT)May 17
#   ...

# TODO

# Every Thursday in March, forever:
#
#   DTSTART;TZID=US-Eastern:19970313T090000
#   RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=TH
#
#   ==> (1997 9:00 AM EST)March 13,20,27
#       (1998 9:00 AM EST)March 5,12,19,26
#       (1999 9:00 AM EST)March 4,11,18,25
#   ...

Test(
  'FREQ=YEARLY;BYMONTH=3;BYDAY=TH;count=11',
  '19970313T090000',
  <<VEC
#   ==> (1997 9:00 AM EST)March 13,20,27
#       (1998 9:00 AM EST)March 5,12,19,26
#       (1999 9:00 AM EST)March 4,11,18,25
VEC
)

# Every Thursday, but only during June, July, and August, forever:
#
#   DTSTART;TZID=US-Eastern:19970605T090000
#   RRULE:FREQ=YEARLY;BYDAY=TH;BYMONTH=6,7,8
#
#   ==> (1997 9:00 AM EDT)June 5,12,19,26;July 3,10,17,24,31;
#                     August 7,14,21,28
#       (1998 9:00 AM EDT)June 4,11,18,25;July 2,9,16,23,30;
#                     August 6,13,20,27
#       (1999 9:00 AM EDT)June 3,10,17,24;July 1,8,15,22,29;
#                     August 5,12,19,26
#   ...

Test(
  'FREQ=YEARLY;BYDAY=TH;BYMONTH=6,7,8;count=39',
  '19970605T090000',
  <<VEC
#   ==> (1997 9:00 AM EDT)June 5,12,19,26;July 3,10,17,24,31;August 7,14,21,28
#       (1998 9:00 AM EDT)June 4,11,18,25;July 2,9,16,23,30;August 6,13,20,27
#       (1999 9:00 AM EDT)June 3,10,17,24;July 1,8,15,22,29;August 5,12,19,26
VEC
)

# Every Friday the 13th, forever:
#
#   DTSTART;TZID=US-Eastern:19970902T090000
#   EXDATE;TZID=US-Eastern:19970902T090000
#   RRULE:FREQ=MONTHLY;BYDAY=FR;BYMONTHDAY=13
#   ==> (1998 9:00 AM EST)February 13;March 13;November 13
#       (1999 9:00 AM EDT)August 13
#       (2000 9:00 AM EDT)October 13
#   ...

# FIXME - why is there an EXDATE here?

Test(
  'FREQ=MONTHLY;BYDAY=FR;BYMONTHDAY=13;count=5',
  '19970902T090000',
  <<VEC
#   ==> (1998 9:00 AM EST)February 13;March 13;November 13
#       (1999 9:00 AM EDT)August 13
#       (2000 9:00 AM EDT)October 13
VEC
)

# The first Saturday that follows the first Sunday of the month,
#  forever:
#
#   DTSTART;TZID=US-Eastern:19970913T090000
#   RRULE:FREQ=MONTHLY;BYDAY=SA;BYMONTHDAY=7,8,9,10,11,12,13
#
#   ==> (1997 9:00 AM EDT)September 13;October 11
#       (1997 9:00 AM EST)November 8;December 13
#       (1998 9:00 AM EST)January 10;February 7;March 7
#       (1998 9:00 AM EDT)April 11;May 9;June 13...
#   ...

Test(
  'FREQ=MONTHLY;BYDAY=SA;BYMONTHDAY=7,8,9,10,11,12,13;count=10',
  '19970913T090000',
  <<VEC
#   ==> (1997 9:00 AM EDT)September 13;October 11
#       (1997 9:00 AM EST)November 8;December 13
#       (1998 9:00 AM EST)January 10;February 7;March 7
#       (1998 9:00 AM EDT)April 11;May 9;June 13...
VEC
)

# Every four years, the first Tuesday after a Monday in November,
# forever (U.S. Presidential Election day):
#
#   DTSTART;TZID=US-Eastern:19961105T090000
#   RRULE:FREQ=YEARLY;INTERVAL=4;BYMONTH=11;BYDAY=TU;BYMONTHDAY=2,3,4,
#    5,6,7,8
#
#   ==> (1996 9:00 AM EST)November 5
#       (2000 9:00 AM EST)November 7
#       (2004 9:00 AM EST)November 2
#   ...

Test(
'FREQ=YEARLY;INTERVAL=4;BYMONTH=11;BYDAY=TU;BYMONTHDAY=2,3,4,5,6,7,8;count=3',
'19961105T090000',
<<VEC
#   ==> (1996 9:00 AM EST)November 5
#       (2000 9:00 AM EST)November 7
#       (2004 9:00 AM EST)November 2
VEC
)

# The 3rd instance into the month of one of Tuesday, Wednesday or
# Thursday, for the next 3 months:
#
#   DTSTART;TZID=US-Eastern:19970904T090000
#   RRULE:FREQ=MONTHLY;COUNT=3;BYDAY=TU,WE,TH;BYSETPOS=3
#
#   ==> (1997 9:00 AM EDT)September 4;October 7
#       (1997 9:00 AM EST)November 6

# TODO

# The 2nd to last weekday of the month:
#
#   DTSTART;TZID=US-Eastern:19970929T090000
#   RRULE:FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-2
#
#   ==> (1997 9:00 AM EDT)September 29
#       (1997 9:00 AM EST)October 30;November 27;December 30
#       (1998 9:00 AM EST)January 29;February 26;March 30
#   ...
#

# TODO

# Every 3 hours from 9:00 AM to 5:00 PM on a specific day:
#
#   DTSTART;TZID=US-Eastern:19970902T090000
#   RRULE:FREQ=HOURLY;INTERVAL=3;UNTIL=19970902T170000Z
#
#   ==> (September 2, 1997 EDT)09:00,12:00,15:00
#
# Every 15 minutes for 6 occurrences:
#
#   DTSTART;TZID=US-Eastern:19970902T090000
#   RRULE:FREQ=MINUTELY;INTERVAL=15;COUNT=6
#
#   ==> (September 2, 1997 EDT)09:00,09:15,09:30,09:45,10:00,10:15
#
# Every hour and a half for 4 occurrences:
#
#   DTSTART;TZID=US-Eastern:19970902T090000
#   RRULE:FREQ=MINUTELY;INTERVAL=90;COUNT=4
#
#   ==> (September 2, 1997 EDT)09:00,10:30;12:00;13:30
#
# Every 20 minutes from 9:00 AM to 4:40 PM every day:
#
#   DTSTART;TZID=US-Eastern:19970902T090000
#   RRULE:FREQ=DAILY;BYHOUR=9,10,11,12,13,14,15,16;BYMINUTE=0,20,40
#   or
#   RRULE:FREQ=MINUTELY;INTERVAL=20;BYHOUR=9,10,11,12,13,14,15,16
#
#   ==> (September 2, 1997 EDT)9:00,9:20,9:40,10:00,10:20,
#                              ... 16:00,16:20,16:40
#       (September 3, 1997 EDT)9:00,9:20,9:40,10:00,10:20,
#                             ...16:00,16:20,16:40
#   ...
#
# An example where the days generated makes a difference because of
# WKST:
#
#   DTSTART;TZID=US-Eastern:19970805T090000
#   RRULE:FREQ=WEEKLY;INTERVAL=2;COUNT=4;BYDAY=TU,SU;WKST=MO
#
#   ==> (1997 EDT)Aug 5,10,19,24
#
#   changing only WKST from MO to SU, yields different results...
#
#   DTSTART;TZID=US-Eastern:19970805T090000
#   RRULE:FREQ=WEEKLY;INTERVAL=2;COUNT=4;BYDAY=TU,SU;WKST=SU
#   ==> (1997 EDT)August 5,17,19,31
#
end

end

