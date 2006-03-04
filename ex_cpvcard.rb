ORIGINAL =<<'---'
BEGIN:VCARD
VERSION:3.0
FN:Jimmy Death
N:Death;Jimmy;;Dr.;
TEL:+416 123 1111
TEL;type=home,pref:+416 123 2222
TEL;type=work,fax:+416+123+3333
EMAIL;type=work:drdeath@work.com
EMAIL;type=pref:drdeath@home.net
END:VCARD
---

require 'vpim/vcard'
require 'vpim/maker/vcard'

original = Vpim::Vcard.decode(ORIGINAL).first

puts original

puts "\nJimmy prefers you to use his work email and home telephone.\n\n"

modified = Vpim::Maker::Vcard.make(original['FN']) do |card|
  card.copy(original) do |field|
    if field.name?('EMAIL')
      field = field.copy
      field.pref = field.type? 'work'
    end
    if field.name?('TEL')
      field = field.copy
      field.pref = field.type? 'home'
    end
    field
  end
end

puts modified


