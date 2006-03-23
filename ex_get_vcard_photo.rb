#!/usr/bin/ruby -w

require 'vpim/vcard'

vcf = open(ARGV[0] || 'data/vcf/Sam Roberts.vcf')

card = Vpim::Vcard.decode(vcf).first

photo = card['PHOTO']

file = '_photo.'

if card.field('PHOTO')['TYPE']
  file += card.field('PHOTO')['TYPE'].first
else
  # AddressBook.app exports TIFF, but doesn't set the type. Argh.
  file += 'tiff'
end

open(file, 'w').write photo

