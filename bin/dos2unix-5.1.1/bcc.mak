!include version.mk

CC      = bcc
DEFINES = -DMSDOS -DVER_REVISION="$(DOS2UNIX_VERSION)" -DVER_DATE="$(DOS2UNIX_DATE)"
CFLAGS  = $(DEFINES) -Z -O -w -mc -1

all: dos2unix.exe unix2dos.exe mac2unix.exe unix2mac.exe

dos2unix.exe: dos2unix.obj
	bcc -mc dos2unix.obj noehc.lib

unix2dos.exe: unix2dos.obj
	bcc -mc unix2dos.obj noehc.lib

# remove noehc.lib if you are using Borland C version prior
# to 4.0. noeh?.lib, where ? stands for the memory model,
# removes the C++ exception handling from the startup-code
# which is included by default since Borland 4.0 and
# higher. Including noeh?.lib reduces the executable size
# significant, provided your source is C only.


#.c.obj:
#	$(CC) -c $(CFLAGS) $<

dos2unix.obj :  dos2unix.c
	$(CC) -c $(CFLAGS) -o$@ dos2unix.c

unix2dos.obj :  unix2dos.c
	$(CC) -c $(CFLAGS) -o$@ unix2dos.c

mac2unix.exe: dos2unix.exe
	copy /v dos2unix.exe mac2unix.exe

unix2mac.exe: unix2dos.exe
	copy /v unix2dos.exe unix2mac.exe


strip :
	tdstrip dos2unix.exe
	tdstrip unix2dos.exe
	tdstrip mac2unix.exe
	tdstrip unix2mac.exe

clean:
	del *.obj
	del *.exe

