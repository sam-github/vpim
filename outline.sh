#!/bin/zsh

egrep '^ *((def)|(class)|(module)|(include)|(attr_[a-z]*))\>' lib/vpim/**/*.rb | perl -ne'm/lib\/vpim\/(.*\.rb):(.*)/; print sprintf("%-25s %s\n", $1, $2);' | grep -v plist

