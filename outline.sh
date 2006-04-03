egrep ' *((def)|(class)|(module)|(attr_[a-z]*))\>' lib/vpim/**/*.rb | perl -ne'm/lib\/vpim\/(.*\.rb):(.*)/; print sprintf("%-25s %s\n", $1, $2);'

