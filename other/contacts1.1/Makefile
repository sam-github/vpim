# contact's makefile

version=1.1

# paths
bin=/usr/bin
man=/usr/share/man/man1
pkgres=build_pkg/pkgres
dist=build_pkg/dstroot
packagemaker=/Developer/Applications/Utilities/PackageMaker.app/Contents/MacOS/PackageMaker

BUILDOPS=-buildstyle Deployment

.PHONY: clean all dstroot pkgres contacts test install uninstall

all: contacts

contacts:
	xcodebuild $(BUILDOPS) -target contacts

test:
	xcodebuild $(BUILDOPS) -target test && ./build/test

clean: cleanpkg
	rm -rf build
	rm -rf build_dmg
	
cleanpkg:
	test -e build_pkg && sudo rm -rf build_pkg; :

install:
	cp build/contacts $(bin)
	cp contacts.1 $(man)

uninstall:
	rm $(bin)/contacts
	rm $(man)/contacts.1

dstroot: all
	sudo rm -rf $(dist)
	mkdir -p $(dist)/$(man)
	mkdir -p $(dist)/$(bin) 
	cp contacts.1 $(dist)/$(man)
	cp build/contacts $(dist)/$(bin)
	chmod a+x $(dist)/$(bin)/contacts
	/bin/chmod 775 $(dist)
	sudo /usr/sbin/chown -R root:wheel $(dist)
	sudo /usr/bin/chgrp admin $(dist) $(dist)/$(bin)/contacts $(dist)/$(man)/contacts.1

pkgres:
	mkdir -p $(pkgres)
	cp "GPL License.rtf" $(pkgres)/"License.rtf"
	cp "README" $(pkgres)/"ReadMe.txt"
	cp pkg_resources/preupgrade $(pkgres)

package: dstroot pkgres
	$(packagemaker) -build \
          -p $(shell pwd)/build/contacts$(version).pkg \
          -f $(shell pwd)/$(dist) \
          -r $(shell pwd)/$(pkgres) \
          -i pkg_resources/Info.plist \
          -d pkg_resources/Description.plist; echo 
	@echo Created package build/contacts$(version).pkg

sourcedist:
	cvs -d /home/cvsroot export -D now contacts
	mv contacts contacts$(version)
	tar cfz build/contacts$(version).tgz contacts$(version)
	trash contacts$(version)
	@echo Created source tarball build/contacts$(version).tgz

build/contacts_man.pdf: contacts.1
	mkdir -p build/man/man1
	cp contacts.1 build/man/man1
	man -M $(shell pwd)/build/man -t contacts | pstopdf -i -o build/contacts_man.pdf
	

diskimage: package sourcedist build/contacts_man.pdf
	rm -f build/contacts1.1.dmg
	rm -rf build_dmg
	mkdir -p "build_dmg/source code"
	cp README build_dmg/ReadMe.txt
	cp "GPL License.rtf" build_dmg
	cp build/contacts$(version).tgz "build_dmg/source code"
	cp build/contacts_man.pdf "build_dmg/contacts man page.pdf"
	cp -R build/contacts$(version).pkg build_dmg
	hdiutil create -srcfolder build_dmg -volname contacts build/contacts$(version).dmg
	@echo Created disk image build/contacts$(version).dmg
