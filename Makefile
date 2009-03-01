# Makefile

SHELL:=/bin/sh

RUBY=/usr/bin/ruby

.PHONY: default doc test other

do: agent-upload

reminder:
	ruby -I lib samples/reminder.rb

default: test

bday:
	@ruby18 -I . vcf-to-ics.rb < _all.vcf | tee _bday.ics

doc-upload:
	cd doc; scp -r . sam@rubyforge.org:/var/www/gforge-projects/vpim/

agent-upload:
	rsync -v --archive --compress --cvs-exclude --exclude=.svn/ --del lib octet:webapps/agent/

RDFLAGS = -w2

#--diagram
# --main doc/foo.html

TEST=test/test_all.rb

dcal:
	sh -c "./ics-dump.rb ~/Library/Calendars/Play.ics"
	sh -c "./ics-dump.rb ~/Library/Calendars/Events.ics"

test:
	$(RUBY) $(TEST)
	for e in ex_*.rb; do $(RUBY) -w -I lib $$e; done >/dev/null
	#/usr/bin/ruby -w -I lib $(TEST)
	#/opt/local/bin/ruby -w -I lib $(TEST)

test_new:
	for r in /opt/local/bin/ruby /usr/local/bin/ruby18; do $$r -w $(TEST); done

test_old:
	for r in /usr/bin/ruby; do $$r -w $(TEST); done

.PHONY: coverage
coverage:
	rcov -Ilib -x "^/" test/test_all.rb
	open coverage/index.html

other:
	ruby -w -I . ab-query.rb --me
	ruby -w -I . mutt_ab_query.rb --file=_vcards -d Sam
	ruby -w -I . mbox2vcard.rb _mbox

outline:
	zsh ./outline.sh > outline.txt

.PHONY: tags
tags:
	/sw/bin/ctags -R --extra=+f lib test
	#RUBYLIB=/Users/sam/p/ruby/ruby/lib /usr/local/bin/rdoc18 -f tags lib
	#mv tags tags.ctags
	#sort tags.ctags tags.rdoc > tags

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
	rdoc $(RDFLAGS) -x lib/vpim/agent lib/vpim CHANGES COPYING README samples/README.mutt
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
	mkdir -p bin
	cp -v samples/reminder.rb bin/reminder
	cp -v samples/rrule.rb bin/rrule
	chmod +x bin/*
	ruby vpim.gemspec
	mv vpim*.gem releases/

geminstall:
	gem install -V 

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
	cp COPYING README CHANGES setup.rb $R/
	cp lib/*.rb                $R/lib/
	cp lib/vpim/*.rb           $R/lib/vpim/
	cp lib/vpim/maker/*.rb     $R/lib/vpim/maker/
	cp lib/vpim/property/*.rb  $R/lib/vpim/property/
	cp samples/README.mutt     $R/samples
	cp $(SAMPLES)              $R/samples
	cp samples/osx-wrappers.rb $R/samples
	cp test/test_*.rb          $R/test
	# no docs: cp -r  doc      $R/
	cd releases && tar -zcf $P.tgz $P

vagent:
	mkdir -p vAgent.app/Contents/Resources/lib/vpim/agent
	mkdir -p vAgent.app/Contents/Resources/lib/vpim/maker
	mkdir -p vAgent.app/Contents/Resources/lib/vpim/property
	tar -cf- `find lib -name "*.rb"` | (cd vAgent.app/Contents/Resources; tar -xvf-)
	cp vagent.rb               vAgent.app/Contents/Resources/script
	rm -f releases/vAgent.app.zip
	find vAgent.app -type f | egrep -v ".svn|CVS" | zip releases/vAgent.app.zip -@


# It's easier to just copy the resources I want into the target .app structure.
#
#VpimAgent.app: vpimd
#	rm -rf "$@"
#	/usr/local/bin/platypus -BR -a $< -t 'Ruby' -o 'TextWindow' -u 'Sam Roberts' -i '/usr/bin/ruby' -V $V -s '????' -I 'org.sam.vpimagent' -f '/Users/sam/p/ruby/vpim/root/branch/stable/lib' '/Users/sam/p/ruby/vpim/root/branch/stable/vpimd' $@



# vim:noexpandtab:tabstop=2:sw=2:
