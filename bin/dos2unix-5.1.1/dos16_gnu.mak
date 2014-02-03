
# Author: Erwin Waterlander
# Copyright (C) 2009 Erwin Waterlander
# This file is distributed under the same license as the dos2unix package.

prefix=c:/dos16
ENABLE_NLS=

ifdef ENABLE_NLS
LDFLAGS_EXTRA = -lintl -liconv
endif

all:
	c:/bc4/bin/make -f bcc.mak

install:
	$(MAKE) install EXE=.exe ENABLE_NLS=$(ENABLE_NLS) LDFLAGS_EXTRA="$(LDFLAGS_EXTRA)" prefix=$(prefix) LINK="cp -f" docsubdir=dos2unix

uninstall:
	$(MAKE) uninstall EXE=.exe prefix=$(prefix) docsubdir=dos2unix

clean:
	$(MAKE) clean EXE=.exe ENABLE_NLS=$(ENABLE_NLS) prefix=$(prefix)

dist:
	$(MAKE) dist-zip EXE=.exe prefix=$(prefix) VERSIONSUFFIX="-dos16" ZIPOBJ_EXTRA="${ZIPOBJ_EXTRA}" ENABLE_NLS=$(ENABLE_NLS) docsubdir=dos2unix

strip:
	c:/bc4/bin/make -f bcc.mak strip

