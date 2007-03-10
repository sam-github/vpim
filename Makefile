# Makefile

SHELL:=/bin/sh

.PHONY: default doc test other

do:
	ruby -I lib -w -rpp test/test_ical.rb --name=test_duration

default: test

bday:
	@ruby18 -I . vcf-to-ics.rb < _all.vcf | tee _bday.ics

doc-upload:
	cd doc; scp -r . sam@rubyforge.org:/var/www/gforge-projects/vpim/

RDFLAGS = -w2

#--diagram
# --main doc/foo.html

TEST=test/test_all.rb

dcal:
	sh -c "./ics-dump.rb ~/Library/Calendars/Play.ics"
	sh -c "./ics-dump.rb ~/Library/Calendars/Events.ics"

test:
	/usr/local/bin/ruby18 -w -I lib $(TEST)
	for e in ex_*.rb; do /usr/local/bin/ruby18 -w -I lib $$e; done >/dev/null
	#/usr/bin/ruby -w -I lib $(TEST)
	#/opt/local/bin/ruby -w -I lib $(TEST)

test_new:
	for r in /opt/local/bin/ruby /usr/local/bin/ruby18; do $$r -w $(TEST); done

test_old:
	for r in /usr/bin/ruby; do $$r -w $(TEST); done


changes:
	cvs-changelog -r -f changes.cvs

other:
	ruby -w -I . ab-query.rb --me
	ruby -w -I . mutt_ab_query.rb --file=_vcards -d Sam
	ruby -w -I . mbox2vcard.rb _mbox

outline:
	zsh ./outline.sh > outline.txt

.PHONY: tags
tags:
	/opt/local/bin/ctags -R --extra=+f lib #rss
	RUBYLIB=/Users/sam/p/ruby/ruby/lib /usr/local/bin/rdoc18 -f tags lib
	mv tags tags.ctags
	sort tags.ctags tags.rdoc > tags

ri:
	rdoc18 -f ri lib

open:
	open doc/index.html

SAMPLES := \
 samples/ab-query.rb \
 samples/cmd-itip.rb \
 samples/ex_get_vcard_photo.rb \
 samples/ex_cpvcard.rb \
 samples/ex_mkvcard.rb \
 samples/ex_mkv21vcard.rb \
 samples/ex_mkyourown.rb \
 samples/ics-dump.rb \
 samples/ics-to-rss.rb \
 samples/mutt-aliases-to-vcf.rb \
 samples/reminder.rb \
 samples/rrule.rb \
 samples/tabbed-file-to-vcf.rb \
 samples/vcf-dump.rb \
 samples/vcf-lines.rb \
 samples/vcf-to-mutt.rb \
 samples/vcf-to-ics.rb \

.PHONY: doc
doc:
	rm -rf doc/
	rdoc18 $(RDFLAGS) -x lib/vpim/agent lib/vpim CHANGES COPYING README samples/README.mutt
	for s in $(SAMPLES); do cp $$s doc/`basename $$s .rb`.txt; done
	cp etc/rfc24*.txt doc/
	chmod u=rw doc/*.txt
	chmod go=r doc/*.txt
	mkdir -p $(HOME)/Sites/vpim
	cp -r doc/* $(HOME)/Sites/vpim/
	open doc/index.html
	ruby -I lib -w -rpp ex_ics_api.rb > ex_ics_api.out

.PHONY: doc-vcf
doc-vcf:
	rdoc lib/vpim/vcard.rb lib/vpim/maker/vcard.rb
	open doc/index.html

V=0.$(shell ruby -rsvn -e"puts Svn.info['Revision']")
P=vpim-$V
R=releases/$P

release: stamp doc pkg gem

install:
	for r in /usr/bin/ruby /opt/local/bin/ruby ruby18; do (cd $R; $$r install.rb config; sudo $$r install.rb install); done

stamp:
	svn up
	@echo "Stamp version:" $V
	ruby stamp.rb > lib/vpim/version.rb

gem:
	mkdir -p releases
	ruby18 vpim.gemspec
	mv vpim-$V.gem releases/

pkg:
	rm -rf $R/*
	mkdir -p releases
	mkdir -p $R
	mkdir -p $R/lib
	mkdir -p $R/lib/vpim/maker
	mkdir -p $R/lib/vpim/property
	mkdir -p $R/samples
	mkdir -p $R/test
	mkdir -p $R/etc
	cp COPYING README CHANGES install.rb $R/
	cp lib/*.rb                $R/lib/
	cp lib/vpim/*.rb           $R/lib/vpim/
	cp lib/vpim/maker/*.rb     $R/lib/vpim/maker/
	cp lib/vpim/property/*.rb  $R/lib/vpim/property/
	cp etc/rfc2425.txt         $R/etc
	cp etc/rfc2426.txt         $R/etc
	cp etc/rfc2445.txt         $R/etc
	cp etc/rrule.txt           $R/etc
	cp samples/README.mutt     $R/samples
	cp $(SAMPLES)              $R/samples
	cp samples/osx-wrappers.rb $R/samples
	cp test/test_*.rb          $R/test
	# no docs: cp -r  doc      $R/
	cd releases && tar -zcf $P.tgz $P

# vim:noexpandtab:tabstop=2:
