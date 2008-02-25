#!/usr/bin/env ruby

$-w = true

$:.unshift File.dirname($0)

require 'rmail'
require 'vpim/vcard'
require 'find'
require 'ftools'

Field = Rfc2425::DirectoryInfo::Field

addrs = RMail::Address::List.new

module RMail
  class Address
  end
end

ARGV.each { |mbox|
  File.open(File.expand_path(mbox)) { |file|
    puts "Reading: #{file.path}..."

    RMail::Mailbox::MBoxReader.new(file).each_message { |input|
      message = RMail::Parser.read(input)
      header = message.header
      addrs.concat(header.from)
      addrs.concat(header.recipients)
      addrs.concat(header.reply_to)
    }
  }
}

addrs = addrs.uniq

puts "Unique addrs: #{addrs.size}"

ROOT = 'cards/'
NEW  = ROOT + 'new/'
GOOD = ROOT + 'good/'
BAD  = ROOT + 'bad/'
LOST = ROOT + 'lost/'

begin
  File.mkpath NEW
  File.mkpath GOOD
  File.mkpath BAD
  File.mkpath LOST
rescue Errno::EEXIST
end

addrs.each { |a|
  # Skip garbage domains
  next if a.domain =~ /yahoo\.com/
  next if a.domain =~ /email\.com/

  # Eliminate duplicates
  file = a.domain.downcase + ':' + a.local.downcase + '.vcf'

  # Some local-parts have a '/' in them, translate it.
  file.tr!('/', '!')

  found = false

  Find.find(ROOT) { |f| found = true if File.basename(f).downcase == file }

  if found
    next
  end

  # Create a vCard
  card = Rfc2425::Vcard.create

  card << Field.encode('email', a.addrspec, 'type' => "internet" )
  card << Field.encode('url', "http://" + a.domain )
  card << Field.encode('fn', a.name )
  card << Field.encode('note', "list:#{ARGV[0]};auto-delete" )

  # Write the card
  puts "http://#{a.domain.ljust(25)} --> #{a.format}"

  begin
    File.open(NEW + file, File::CREAT|File::EXCL|File::WRONLY) { |f|
      f.write card.to_s
    }
  end
}

