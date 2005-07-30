# Makefile

SHELL:=/bin/sh

.PHONY: default doc test other

default: test

do:
	@ruby18 -I . vcf-to-ics.rb < _all.vcf | tee _bday.ics

doc-upload:
	cd doc; scp -r . sam@rubyforge.org:/var/www/gforge-projects/vpim/

RDFLAGS = -w2

#--diagram
# --main doc/foo.html

TEST=test_all.rb

dcal:
	sh -c "./ical-dump.rb ~/Library/Calendars/Play.ics"
	sh -c "./ical-dump.rb ~/Library/Calendars/Events.ics"

test:
	/usr/local/bin/ruby18 -w -I . $(TEST)
	#/usr/bin/ruby -w -I . $(TEST)
	#/opt/local/bin/ruby -w -I . $(TEST)

changes:
	cvs-changelog -r -f changes.cvs

other:
	ruby -w -I . ab-query.rb --me
	ruby -w -I . mutt_ab_query.rb --file=_vcards -d Sam
	ruby -w -I . mbox2vcard.rb _mbox

.PHONY: tags
tags:
	exctags -R vpim #rss
	RUBYLIB=/Users/sam/p/ruby/ruby/lib rdoc18 -f tags vpim #rss
	mv tags tags.ctags
	sort tags.ctags tags.rdoc > tags

ri:
	rdoc18 -f ri vpim

open:
	open doc/index.html

SAMPLES := \
 ab-query.rb \
 cmd-itip.rb \
 ex_get_vcard_photo.rb \
 ex_mkvcard.rb \
 ical-dump.rb \
 ics-to-rss.rb\
 mutt-aliases-to-vcf.rb \
 reminder.rb \
 rrule.rb \
 tabbed-file-to-vcf.rb \
 vcard-dump.rb \
 vcf-to-mutt.rb \
 vcf-to-ics.rb \


doc:
	rm -rf doc/
	rdoc18 $(RDFLAGS) vpim CHANGES COPYING README README.mutt
	for s in $(SAMPLES); do cp $$s doc/`basename $$s .rb`.txt; done
	cp etc/rfc24*.txt doc/
	chmod u=rw doc/*.txt
	chmod go=r doc/*.txt
	mkdir -p $HOME/Sites/vpim
	cp -r doc/* $HOME/Sites/vpim/
	open doc/index.html

V=0.15
P=vpim-$V
R=releases/$P

release: stamp doc pkg

install:
	for r in /usr/bin/ruby /opt/local/bin/ruby ruby18; do (cd $R; $$r install.rb config; sudo $$r install.rb install); done

stamp:
	ruby -pi~ -e '$$_.gsub!(/0\.\d+(bis|[a-z])?/, "$V")' vpim/vpim.rb

pkg:
	rm -rf $R/*
	mkdir -p releases
	mkdir -p $R
	mkdir -p $R/lib
	mkdir -p $R/lib/vpim/maker
	mkdir -p $R/samples
	mkdir -p $R/etc
	cp COPYING README CHANGES install.rb $R/
	cp vpim/*.rb           $R/lib/vpim/
	cp vpim/maker/*.rb     $R/lib/vpim/maker/
	cp etc/rfc2425.txt     $R/etc
	cp etc/rfc2426.txt     $R/etc
	cp etc/rfc2445.txt     $R/etc
	cp etc/rrule.txt       $R/etc
	cp README.mutt         $R/samples
	cp $(SAMPLES)          $R/samples
	cp osx-wrappers.rb     $R/samples
	cp test_*.rb           $R/samples
	# no docs: cp -r  doc             $R/
	cd releases && tar -zcf $P.tgz $P

