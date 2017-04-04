SHELL := /bin/bash

PERCENT := %

-include names.makefile
VERSION ?= 1.0.0

.PHONY: all
all: $(NAMES:%=debian/%.deb) $(NAMES:%=debian/%-dev.deb)

.PHONY:
bintray: bintray.json

.PHONY:
clean:
	rm -fr bintray debian

.PHONY: none
none:

# Run CMake
.aws-sdk-cpp.cmake: .git/modules/aws-sdk-cpp/HEAD
	git -C aws-sdk-cpp clean -dfx
	cd aws-sdk-cpp && cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_TESTING=OFF -DMINIMIZE_SIZE=ON
	@> $@

.PHONY: .travis.yml
.travis.yml: .travis.yml.in
	cp $< $@
	echo 'deploy:' >> $@
	for name in $(NAMES) $(NAMES:%=%-dev); do \
		echo '  -' >> $@;                     \
		echo '    <<: *DEPLOY_DEFAULT' >> $@; \
		echo "    file: bintray/$$name.json" >> $@; \
	done

# Run make
names.makefile: .aws-sdk-cpp.cmake
	+$(MAKE) $(MAKEFLAGS) -C aws-sdk-cpp
	echo "NAMES := $$(basename -a -s .so aws-sdk-cpp/*/lib*.so | tr '\n' ' ')" > $@

bintray.json: bintray.json.erb
	VERSION=$(VERSION) erb $< > $@

# Oddly required for dpkg-shlibdeps
debian/control:
	@mkdir -p $(@D)
	> $@

debian/%/DEBIAN/postinst:
	echo '[ "$1" != configure ] || ldconfig' > $@

debian/%/DEBIAN/postrm:
	echo '[ "$1" != remove ] || ldconfig'

# Helps dpkg-shlibdeps
debian/%/DEBIAN/symbols:
	@mkdir -p $(@D)
	echo $*.so $* '(= $(VERSION))' > $@
#	dpkg-gensymbols -d -q -p$* -v1 -O$@ -Pdebian/$*

debian/.%-dev:
	@mkdir -p debian/$*/usr
	cp -r aws-sdk-cpp/$(*:lib%=%)/include debian/$*/usr
	@> $@

.SECONDEXPANSION:

debian/%.so: aws-sdk-cpp/$$(patsubst lib$$(PERCENT),$$(PERCENT),$$(*F))/$$(*F).so
	@mkdir -p $(@D)
	cp $< $@

SYMBOLS := $(NAMES:%=debian/%/DEBIAN/symbols)
debian/%/DEBIAN/control: debian/$$*/usr/lib/$$*.so debian/control $$(SYMBOLS)
	echo Architecture: $$(dpkg --print-architecture) > $@
	echo Depends: $$(dpkg-shlibdeps -O -xlibstdc++6 --warnings=0  $< | sed s/shlibs:Depends=//) >> $@
	echo Description: 'AWS C++ SDK' >> $@
	echo Maintainer: 'Lucid Software <ops@lucidchart.com>' >> $@
	echo Package: $* >> $@
	echo Version: $(VERSION) >> $@

debian/%.deb: debian/%/DEBIAN/control debian/$$*/usr/lib/$$*.so
	dpkg-deb -b debian/$* $@

debian/%-dev/DEBIAN/control: debian/$$*/usr/lib/$$*.so debian/control $$(SYMBOLS)
	@mkdir -p $(@D)
	echo Architecture: $$(dpkg --print-architecture) > $@
	echo Depends: '$* (= $(VERSION)), ' $$(dpkg-shlibdeps -O -xlibstdc++6 --warnings=0  $< | sed -e s/shlibs:Depends=// -e 's/\([^ ^,]\+\)\([^,]*\)/\1-dev\2/g' -e s/libpulse0-dev/libpulse-dev/ -e 's/libssl\S\+/libssl-dev/') >> $@
	echo Description: 'AWS C++ SDK headers' >> $@
	echo Maintainer: 'Lucid Software <ops@lucidchart.com>' >> $@
	echo Package: $*-dev >> $@
	echo Version: $(VERSION) >> $@

debian/%-dev.deb: debian/$$*-dev/DEBIAN/control $$(shell find aws-sdk-cpp/$$(patsubst lib$$(PERCENT),$$(PERCENT),$$*)/include -type f -name '*.h')
	@mkdir -p debian/$*-dev/usr/include
	rsync -r --include='*/' --include='*.h' --exclude='*' aws-sdk-cpp/$(*:lib%=%)/include/ debian/$*-dev/usr/include/
	dpkg-deb -b debian/$*-dev $@
