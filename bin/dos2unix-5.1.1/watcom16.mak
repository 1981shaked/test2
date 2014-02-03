!include version.mk

CC      = wcc
SRCDIR = .
DEFINES = -DMSDOS -DVER_REVISION="$(DOS2UNIX_VERSION)" -DVER_DATE="$(DOS2UNIX_DATE)"
CFLAGS  = $(DEFINES) -i=$(SRCDIR) -w4 -e25 -zq -od -d2 -bt=dos -ml

TARGET = dos

all: dos2unix.exe unix2dos.exe mac2unix.exe unix2mac.exe

cflags.cfg:
	@%create cflags.cfg
	@%append cflags.cfg $(CFLAGS)

dos2unix.exe: dos2unix.obj
	@%create dos2unix.lnk
	@%append dos2unix.lnk FIL dos2unix.obj
	wlink name dos2unix d all SYS $(TARGET) op m op st=32k op maxe=25 op q op symf @dos2unix.lnk
	del dos2unix.lnk

unix2dos.exe: unix2dos.obj
	@%create unix2dos.lnk
	@%append unix2dos.lnk FIL unix2dos.obj
	wlink name unix2dos d all SYS $(TARGET) op m op st=32k op maxe=25 op q op symf @unix2dos.lnk
	del unix2dos.lnk


dos2unix.obj :  $(SRCDIR)\dos2unix.c cflags.cfg
	$(CC) @cflags.cfg $(SRCDIR)\dos2unix.c

unix2dos.obj :  $(SRCDIR)\unix2dos.c cflags.cfg
	$(CC) @cflags.cfg $(SRCDIR)\unix2dos.c

mac2unix.exe : dos2unix.exe
	copy /v dos2unix.exe mac2unix.exe

unix2mac.exe : unix2dos.exe
	copy /v unix2dos.exe unix2mac.exe

strip
	wstrip dos2unix.exe
	wstrip unix2dos.exe
	wstrip mac2unix.exe
	wstrip unix2mac.exe

clean
	-del *.obj
	-del *.exe
