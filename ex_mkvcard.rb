# $Id: ex_mkvcard.rb,v 1.5 2005/02/04 21:32:31 sam Exp $

require 'vpim/maker/vcard'

card = Vpim::Maker::Vcard.make('Jimmy Death') do |card|
  card.add_name do |name|
    name.family = 'Death'
    name.given = 'Jimmy'
    name.prefix = 'Dr.'
  end

  card.add_addr do |addr|
    addr.preferred = true
    addr.location = 'work'
    addr.street = '12 Last Row, 13th Section'
    addr.locality = 'City of Lost Children'
    addr.country = 'Cinema'
  end

  card.add_addr do |addr|
    addr.location = [ 'home', 'zoo' ]
    addr.delivery = [ 'snail', 'stork', 'camel' ]
    addr.street = '12 Last Row, 13th Section'
    addr.locality = 'City of Lost Children'
    addr.country = 'Cinema'
  end

  card.nickname = "The Good Doctor"

  card.birthday = Time.now
  card.birthday = Date.today

  card.add_photo do |photo|
    photo.link = 'http://example.com/image.png'
  end

  card.add_photo do |photo|
    photo.image = "File.open('drdeath.jpg').read # a fake string, real data is too large :-)"
    photo.type = 'jpeg'
  end

  card.add_tel('+416 123 1111')

  card.add_tel('+416 123 2222') { |t| t.location = 'home'; t.preferred = true }

  card.add_impp('joe') do |impp|
    impp.preferred = 'yes'
    impp.location = 'mobile'
  end

  card.add_x_aim('example') do |xaim|
    xaim.location = 'row12'
  end

  card.add_tel('+416+123+3333') do |tel|
    tel.location = 'work'
    tel.capability = 'fax'
  end

  card.add_email('drdeath@work.com') { |e| e.location = 'work' }

  card.add_email('drdeath@home.net') { |e| e.preferred = 'yes' }

end

puts card.to_s

