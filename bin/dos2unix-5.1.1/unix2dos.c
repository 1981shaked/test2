/*
 *  Name: unix2dos
 *  Documentation:
 *    Convert lf ('\x0a') characters in a file to cr lf ('\x0d' '\x0a')
 *    combinations.
 *
 *  The dos2unix package is distributed under FreeBSD style license.
 *  See also http://www.freebsd.org/copyright/freebsd-license.html
 *  --------
 * 
 *  Copyright (C) 2009-2010 Erwin Waterlander
 *  Copyright (C) 1994-1995 Benjamin Lin.
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice in the documentation and/or other materials provided with
 *     the distribution.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY
 *  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 *  PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE
 *  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 *  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 *  OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 *  BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 *  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 *  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 *  IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  == 1.0 == 1989.10.04 == John Birchfield (jb@koko.csustan.edu)
 *  == 1.1 == 1994.12.20 == Benjamin Lin (blin@socs.uts.edu.au)
 *     Cleaned up for Borland C/C++ 4.02
 *  == 1.2 == 1995.03.09 == Benjamin Lin (blin@socs.uts.edu.au)
 *     Fixed minor typo error
 *  == 1.3 == 1995.03.16 == Benjamin Lin (blin@socs.uts.edu.au)
 *     Modified to more conform to UNIX style.
 *  == 2.0 == 1995.03.19 == Benjamin Lin (blin@socs.uts.edu.au)
 *     Rewritten from scratch.
 *  == 2.2 == 1995.03.30 == Benjamin Lin (blin@socs.uts.edu.au)
 *     Conversion from SunOS charset implemented.
 *
 *  See ChangeLog.txt for complete version history.
 *
 */


#define VER_AUTHOR   "Erwin Waterlander"

/* #define DEBUG */

#if defined(DJGPP) || defined(__TURBOC__) /* DJGPP */
#  include <dir.h>
#else
#  include <libgen.h>
#endif
#ifndef __TURBOC__
#include <unistd.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <utime.h>
#ifdef __TURBOC__
#define __FLAT__
#endif
#include <sys/stat.h>
#ifdef ENABLE_NLS
#include <locale.h>
#endif
#include "unix2dos.h"

#if defined(WIN32) /* MINGW32 */
#define MSDOS
#endif

#if  defined(__TURBOC__) || defined(DJGPP) || defined(__MINGW32__)
/* Some compilers have no mkstemp().
 * Use mktemp() instead.
 * BORLANDC, DJGPP, MINGW32 */
#define NO_MKSTEMP 1
#endif

#ifdef MSDOS
/* Some compilers have no fchmod().
 * BORLANDC, DJGPP, MINGW32, OPENWATCOM */
#define NO_FCHMOD 1
#endif

#if defined(MSDOS) || defined(__OS2__)
/* Systems without soft links use 'stat' instead of 'lstat'. */
#define STAT stat
#else
#define STAT lstat
#endif

#if defined(MSDOS) || defined(__OS2__)
/* On some systems rename() will always fail if target file already exists. */
#define NEED_REMOVE 1
#endif

#if defined(MSDOS) || defined(__OS2__) /* DJGPP, MINGW32 and OS/2 */
/* required for setmode() and O_BINARY */
#include <fcntl.h>
#include <io.h>
#endif


#if defined(MSDOS) || defined(__OS2__)
  #define R_CNTRL   "rb"
  #define W_CNTRL   "wb"
#else
  #define R_CNTRL   "r"
  #define W_CNTRL   "w"
#endif

#define BINARY_FILE 0x1
#define NO_REGFILE  0x2

typedef struct
{
  int NewFile;                          /* is in new file mode? */
  int Quiet;                            /* is in quiet mode? */
  int KeepDate;                         /* should keep date stamp? */
  int ConvMode;                         /* 0: ascii, 1: 7bit, 2: iso, 3: mac */  
  int NewLine;                          /* if TRUE, then additional newline */
  int Force;                            /* if TRUE, force conversion of all files. */
  int status;
  int stdio_mode;                       /* if TRUE, stdio mode */
} CFlag;

/******************************************************************
 *
 * int regfile(char *path)
 *
 * test if *path points to a regular file.
 *
 * returns 0 on success, -1 when it fails.
 *
 ******************************************************************/
int regfile(char *path)
{
   struct stat buf;

   if ((STAT(path, &buf) == 0) && S_ISREG(buf.st_mode))
      return(0);
   else
      return(-1);
}

void PrintUsage(void)
{
  fprintf(stderr, _("\
unix2dos %s (%s)\n\
Usage: unix2dos [-fhkLlqV] [-c convmode] [-o file ...] [-n infile outfile ...]\n\
 -c --convmode    conversion mode\n\
   convmode       ascii, 7bit, iso, mac, default to ascii\n\
 -f --force       force conversion of all files\n\
 -h --help        give this help\n\
 -k --keepdate    keep output file date\n\
 -L --license     display software license\n\
 -l --newline     add additional newline\n\
 -n --newfile     write to new file\n\
   infile         original file in new file mode\n\
   outfile        output file in new file mode\n\
 -o --oldfile     write to old file\n\
   file ...       files to convert in old file mode\n\
 -q --quiet       quiet mode, suppress all warnings\n\
                  always on in stdio mode\n\
 -V --version     display version number\n"), VER_REVISION, VER_DATE);
}

void PrintLicense(void)
{
  fprintf(stderr, "%s", _("\
Copyright (C) 2009-2010 Erwin Waterlander\n\
Copyright (C) 1994-1995 Benjamin Lin\n\
All rights reserved.\n\n\
\
Redistribution and use in source and binary forms, with or without\n\
modification, are permitted provided that the following conditions\n\
are met:\n\
1. Redistributions of source code must retain the above copyright\n\
   notice, this list of conditions and the following disclaimer.\n\
2. Redistributions in binary form must reproduce the above copyright\n\
   notice in the documentation and/or other materials provided with\n\
   the distribution.\n\n\
\
THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY\n\
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE\n\
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR\n\
PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE\n\
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR\n\
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT\n\
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR\n\
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,\n\
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE\n\
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN\n\
IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.\n\
"));
}

void PrintVersion(void)
{
  fprintf(stderr, "unix2dos %s (%s)\n", VER_REVISION, VER_DATE);
#ifdef ENABLE_NLS
  fprintf(stderr, "%s", _("With native language support.\n"));
#else
  fprintf(stderr, "%s", "Without native language support.\n");
#endif
#ifdef DEBUG
  fprintf(stderr, "VER_AUTHOR: %s\n", VER_AUTHOR);
#endif
}

#ifdef ENABLE_NLS
void PrintLocaledir(char *localedir)
{
  fprintf(stderr, "LOCALEDIR: %s\n", localedir);
}
#endif

/* opens file of name ipFN in read only mode
 * RetVal: NULL if failure
 *         file stream otherwise
 */
FILE* OpenInFile(char *ipFN)
{
  return (fopen(ipFN, R_CNTRL));
}


/* opens file of name ipFN in write only mode
 * RetVal: NULL if failure
 *         file stream otherwise
 */
FILE* OpenOutFile(int fd)
{
  return (fdopen(fd, W_CNTRL));
}


void AddDOSNewLine(FILE* ipOutF, CFlag *ipFlag, int CurChar, int PrevChar)
{
  if (ipFlag->NewLine) {  /* add additional CR-LF? */
    /* Don't add line ending if it is a DOS line ending. Only in case of Unix line ending. */
    if ((CurChar == '\x0a') && (PrevChar != '\x0d')) {
      putc('\x0d', ipOutF);
      putc('\x0a', ipOutF);
    }
  }
}

/* converts stream ipInF to DOS format text and write to stream ipOutF
 * RetVal: 0  if success
 *         -1  otherwise
 */
int ConvertUnixToDos(FILE* ipInF, FILE* ipOutF, CFlag *ipFlag)
{
    int RetVal = 0;
    int TempChar;
    int PreviousChar = 0;

    ipFlag->status = 0;

    /* LF    -> CR-LF */
    /* CR-LF -> CR-LF, in case the input file is a DOS text file */
    /* \x0a = Newline/Line Feed (LF) */
    /* \x0d = Carriage Return (CR) */

    switch (ipFlag->ConvMode)
    {
      case 0: /* ascii */
        while ((TempChar = getc(ipInF)) != EOF) {  /* get character */
          if ((ipFlag->Force == 0) &&
              (TempChar < 32) &&
              (TempChar != '\x0a') &&  /* Not an LF */
              (TempChar != '\x0d') &&  /* Not a CR */
              (TempChar != '\x09')) {  /* Not a TAB */
            RetVal = -1;
            ipFlag->status |= BINARY_FILE ;
            break;
          }
          if (TempChar == '\x0a')
	  {
            putc('\x0d', ipOutF); /* got LF, put CR */
	  } else {
             if (TempChar == '\x0d') /* got CR */
	     {
               if ((TempChar = getc(ipInF)) == EOF) /* get next char */
                 TempChar = '\x0d';  /* Read error, or end of file. */
	       else
	       {
                 putc('\x0d', ipOutF); /* put CR */
                 PreviousChar = '\x0d';
	       }
	     }
	  }
          if (putc(U2DAsciiTable[TempChar], ipOutF) == EOF)
          {
              RetVal = -1;
              if (!ipFlag->Quiet)
                fprintf(stderr, "%s", _("unix2dos: can not write to output file\n"));
              break;
          } else {
            AddDOSNewLine( ipOutF, ipFlag, TempChar, PreviousChar);
          }
          PreviousChar = TempChar;
        }
        break;
      case 1: /* 7bit */
        while ((TempChar = getc(ipInF)) != EOF) {
          if ((ipFlag->Force == 0) &&
              (TempChar < 32) &&
              (TempChar != '\x0a') &&  /* Not an LF */
              (TempChar != '\x0d') &&  /* Not a CR */
              (TempChar != '\x09')) {  /* Not a TAB */
            RetVal = -1;
            ipFlag->status |= BINARY_FILE ;
            break;
          }
          if (TempChar == '\x0a')
	  {
            putc('\x0d', ipOutF); /* got LF, put CR */
	  } else {
             if (TempChar == '\x0d') /* got CR */
	     {
               if ((TempChar = getc(ipInF)) == EOF) /* get next char */
                 TempChar = '\x0d';  /* Read error, or end of file. */
	       else
	       {
                 putc('\x0d', ipOutF); /* put CR */
                 PreviousChar = '\x0d';
	       }
	     }
	  }
          if (putc(U2D7BitTable[TempChar], ipOutF) == EOF)
          {
              RetVal = -1;
              if (!ipFlag->Quiet)
                fprintf(stderr, "%s", _("unix2dos: can not write to output file\n"));
              break;
          } else {
            AddDOSNewLine( ipOutF, ipFlag, TempChar, PreviousChar);
          }
          PreviousChar = TempChar;
        }
        break;
      case 2: /* iso */
        while ((TempChar = getc(ipInF)) != EOF) {
          if ((ipFlag->Force == 0) &&
              (TempChar < 32) &&
              (TempChar != '\x0a') &&  /* Not an LF */
              (TempChar != '\x0d') &&  /* Not a CR */
              (TempChar != '\x09')) {  /* Not a TAB */
            RetVal = -1;
            ipFlag->status |= BINARY_FILE ;
            break;
          }
          if (TempChar == '\x0a')
	  {
            putc('\x0d', ipOutF); /* got LF, put CR */
	  } else {
             if (TempChar == '\x0d') /* got CR */
	     {
               if ((TempChar = getc(ipInF)) == EOF) /* get next char */
                 TempChar = '\x0d';  /* Read error, or end of file. */
	       else
	       {
                 putc('\x0d', ipOutF); /* put CR */
                 PreviousChar = '\x0d';
	       }
	     }
	  }
          if (putc(U2DIsoTable[TempChar], ipOutF) == EOF)
          {
              RetVal = -1;
              if (!ipFlag->Quiet)
                fprintf(stderr, "%s", _("unix2dos: can not write to output file\n"));
              break;
          } else {
            AddDOSNewLine( ipOutF, ipFlag, TempChar, PreviousChar);
          }
          PreviousChar = TempChar;
        }
        break;
      case 3: /* Mac */
        while ((TempChar = getc(ipInF)) != EOF) {
          if ((ipFlag->Force == 0) &&
              (TempChar < 32) &&
              (TempChar != '\x0a') &&  /* Not an LF */
              (TempChar != '\x0d') &&  /* Not a CR */
              (TempChar != '\x09')) {  /* Not a TAB */
            RetVal = -1;
            ipFlag->status |= BINARY_FILE ;
            break;
          }
          if ((TempChar != '\x0a')) /* Not an LF */
            {
              if(putc(U2DAsciiTable[TempChar], ipOutF) == EOF){
                RetVal = -1;
                if (!ipFlag->Quiet)
                  fprintf(stderr, "%s", _("unix2dos: can not write to output file\n"));
                break;
              }
              PreviousChar = TempChar;
            }
          else{
            /* TempChar is an LF */
            /* Don't touch this delimiter if it's a CR,LF pair. */
            if ( PreviousChar == '\x0d' ) {
              if (putc('\x0a', ipOutF) == EOF)  /* CR,LF pair. Put LF */
                {
                  RetVal = -1;
                  if (!ipFlag->Quiet)
                    fprintf(stderr, "%s", _("unix2dos: can not write to output file\n"));
                  break;
                }
              PreviousChar = TempChar;
              continue;
            }
            PreviousChar = TempChar;
            if (putc('\x0d', ipOutF) == EOF) /* Unix line end (LF). Put CR */
              {
                RetVal = -1;
                if (!ipFlag->Quiet)
                  fprintf(stderr, "%s", _("unix2dos: can not write to output file\n"));
                break;
              }
            if (ipFlag->NewLine) {  /* add additional CR? */
              putc('\x0d', ipOutF);
            }
          }
        }
        break;
      default: /* unknown convmode */
      ;
#ifdef DEBUG
      fprintf(stderr, _("unix2dos: program error, invalid conversion mode %d\n"),ipFlag->ConvMode);
      exit(1);
#endif
    }
    return RetVal;
}

#ifdef __TURBOC__
char *dirname(char *path)
{
  char *ptr;

  if (( path == NULL) || (((ptr=strrchr(path,'/')) == NULL) && ((ptr=strrchr(path,'\\')) == NULL)) )
    return ".";
  else
  {
    *ptr = '\0';
    return(path);
  }
}
#endif

#ifdef NO_MKSTEMP
FILE* MakeTempFileFrom(const char *OutFN, char **fname_ret)
#else
static int MakeTempFileFrom(const char *OutFN, char **fname_ret)
#endif
{
  char *cpy = strdup(OutFN);
  char *dir = NULL;
  size_t fname_len = 0;
  char  *fname_str = NULL;
#ifdef NO_MKSTEMP
  char *name;
  FILE *fd = NULL;
#else
  int fd = -1;
#endif
  
  *fname_ret = NULL;

  if (!cpy)
    goto make_failed;
  
  dir = dirname(cpy);
  
  fname_len = strlen(dir) + strlen("/u2dtmpXXXXXX") + sizeof (char);
  if (!(fname_str = malloc(fname_len)))
    goto make_failed;
  sprintf(fname_str, "%s%s", dir, "/u2dtmpXXXXXX");
  *fname_ret = fname_str;

  free(cpy);

#ifdef NO_MKSTEMP
  name = mktemp(fname_str);
  *fname_ret = name;
  if ((fd = fopen(fname_str, W_CNTRL)) == NULL)
    goto make_failed;
#else
  if ((fd = mkstemp(fname_str)) == -1)
    goto make_failed;
#endif
  
  return (fd);
  
 make_failed:
  free(*fname_ret);
  *fname_ret = NULL;
#ifdef NO_MKSTEMP
  return (NULL);
#else
  return (-1);
#endif
}

/* convert file ipInFN to DOS format text and write to file ipOutFN
 * RetVal: 0 if success
 *         -1 otherwise
 */
int ConvertUnixToDosNewFile(char *ipInFN, char *ipOutFN, CFlag *ipFlag)
{
  int RetVal = 0;
  FILE *InF = NULL;
  FILE *TempF = NULL;
  char *TempPath;
  struct stat StatBuf;
  struct utimbuf UTimeBuf;
#ifndef NO_FCHMOD
  mode_t mask;
#endif
#ifdef NO_MKSTEMP
  FILE* fd;
#else
  int fd;
#endif

  if ((ipFlag->Force == 0) && regfile(ipInFN))
  {
    ipFlag->status |= NO_REGFILE ;
    return -1;
  }
  else
    ipFlag->status = 0 ;

  /* retrieve ipInFN file date stamp */
  if (stat(ipInFN, &StatBuf))
    RetVal = -1;

#ifdef NO_MKSTEMP
  if((fd = MakeTempFileFrom(ipOutFN, &TempPath))==NULL) {
#else
  if((fd = MakeTempFileFrom (ipOutFN, &TempPath)) < 0) {
#endif
    perror(_("unix2dos: Failed to open temporary output file"));
    RetVal = -1;
  }

#ifdef DEBUG
  fprintf(stderr, _("unix2dos: using %s as temporary file\n"), TempPath);
#endif

  /* can open in file? */
  if ((!RetVal) && ((InF=OpenInFile(ipInFN)) == NULL))
    RetVal = -1;

  /* can open output file? */
#ifdef NO_MKSTEMP
  if ((!RetVal) && (InF) && ((TempF=fd) == NULL))
#else
  if ((!RetVal) && (InF) && ((TempF=OpenOutFile(fd)) == NULL))
#endif
  {
    fclose (InF);
    InF = NULL;
    RetVal = -1;
  }

#ifndef NO_FCHMOD
  /* preserve original mode as modified by umask */
  mask = umask(0);
  umask(mask);
  if (!RetVal && fchmod(fd, StatBuf.st_mode & ~mask))
    RetVal = -1;
#endif

  /* conversion sucessful? */
  if ((!RetVal) && (ConvertUnixToDos(InF, TempF, ipFlag)))
    RetVal = -1;

   /* can close in file? */
  if ((InF) && (fclose(InF) == EOF))
    RetVal = -1;

  /* can close output file? */
  if ((TempF) && (fclose(TempF) == EOF))
    RetVal = -1;

#ifdef NO_MKSTEMP
  if(fd!=NULL)
    fclose(fd);
#else
  if(fd>=0)
    close(fd);
#endif

  if ((!RetVal) && (ipFlag->KeepDate))
  {
    UTimeBuf.actime = StatBuf.st_atime;
    UTimeBuf.modtime = StatBuf.st_mtime;
    /* can change output file time to in file time? */
    if (utime(TempPath, &UTimeBuf) == -1)
      RetVal = -1;
  }

  /* any error? */
  if ((RetVal) && (unlink(TempPath)))
    RetVal = -1;

  /* can rename temporary file to output file? */
  if (!RetVal)
  {
#ifdef NEED_REMOVE
    remove(ipOutFN);
#endif
    if ((rename(TempPath, ipOutFN) == -1) && (!ipFlag->Quiet))
    {
      fprintf(stderr, _("unix2dos: problems renaming '%s' to '%s'\n"), TempPath, ipOutFN);
      fprintf(stderr, _("          output file remains in '%s'\n"), TempPath);
      RetVal = -1;
    }
  }
  free(TempPath);
  return RetVal;
}


/* convert file ipInFN to DOS format text
 * RetVal: 0 if success
 *         -1 otherwise
 */
int ConvertUnixToDosOldFile(char* ipInFN, CFlag *ipFlag)
{
  int RetVal = 0;
  FILE *InF = NULL;
  FILE *TempF = NULL;
  char *TempPath;
  struct stat StatBuf;
  struct utimbuf UTimeBuf;
#ifndef NO_FCHMOD
  mode_t mode = S_IRUSR | S_IWUSR;
#endif
#ifdef NO_MKSTEMP
  FILE* fd;
#else
  int fd;
#endif

  if ((ipFlag->Force == 0) && regfile(ipInFN))
  {
    ipFlag->status |= NO_REGFILE ;
    return -1;
  }
  else
    ipFlag->status = 0 ;

  /* retrieve ipInFN file date stamp */
  if (stat(ipInFN, &StatBuf))
    RetVal = -1;
#ifndef NO_FCHMOD
  else
    mode = StatBuf.st_mode;
#endif

#ifdef NO_MKSTEMP
  if((fd = MakeTempFileFrom(ipInFN, &TempPath))==NULL) {
#else
  if((fd = MakeTempFileFrom(ipInFN, &TempPath)) < 0) {
#endif
    perror(_("unix2dos: Failed to open temporary output file"));
    RetVal = -1;
  }

#ifndef NO_FCHMOD
  if (!RetVal && fchmod (fd, mode) && fchmod (fd, S_IRUSR | S_IWUSR))
    RetVal = -1;
#endif

#ifdef DEBUG
  fprintf(stderr, _("unix2dos: using %s as temporary file\n"), TempPath);
#endif

  /* can open in file? */
  if ((!RetVal) && ((InF=OpenInFile(ipInFN)) == NULL))
    RetVal = -1;

  /* can open output file? */
#ifdef NO_MKSTEMP
  if ((!RetVal) && (InF) && ((TempF=fd) == NULL))
#else
  if ((!RetVal) && (InF) && ((TempF=OpenOutFile(fd)) == NULL))
#endif
  {
    fclose (InF);
    InF = NULL;
    RetVal = -1;
  }

  /* conversion sucessful? */
  if ((!RetVal) && (ConvertUnixToDos(InF, TempF, ipFlag)))
    RetVal = -1;

   /* can close in file? */
  if ((InF) && (fclose(InF) == EOF))
    RetVal = -1;

  /* can close output file? */
  if ((TempF) && (fclose(TempF) == EOF))
    RetVal = -1;

#ifdef NO_MKSTEMP
  if(fd!=NULL)
    fclose(fd);
#else
  if(fd>=0)
    close(fd);
#endif

  if ((!RetVal) && (ipFlag->KeepDate))
  {
    UTimeBuf.actime = StatBuf.st_atime;
    UTimeBuf.modtime = StatBuf.st_mtime;
    /* can change output file time to in file time? */
    if (utime(TempPath, &UTimeBuf) == -1)
      RetVal = -1;
  }

  /* any error? */
  if ((RetVal) && (unlink(TempPath)))
    RetVal = -1;

#ifdef NEED_REMOVE
  if (!RetVal)
    remove(ipInFN);
#endif
  /* can rename output file to in file? */
  if ((!RetVal) && (rename(TempPath, ipInFN) == -1))
  {
    if (!ipFlag->Quiet)
    {
      fprintf(stderr, _("unix2dos: problems renaming '%s' to '%s'\n"), TempPath, ipInFN);
      fprintf(stderr, _("          output file remains in '%s'\n"), TempPath);
    }
    RetVal = -1;
  }
  free(TempPath);
  return RetVal;
}


/* convert stdin to DOS format text and write to stdout
 * RetVal: 0 if success
 *         -1 otherwise
 */
int ConvertUnixToDosStdio(CFlag *ipFlag)
{
    ipFlag->NewFile = 1;
    ipFlag->Quiet = 1;
    ipFlag->KeepDate = 0;
    ipFlag->Force = 1;

#ifdef WIN32

    /* stdin and stdout are by default text streams. We need
     * to set them to binary mode. Otherwise an LF will
     * automatically be converted to CR-LF on DOS/Windows.
     * Erwin */

    /* 'setmode' was deprecated by MicroSoft
     * since Visual C++ 2005. Use '_setmode' instead. */

    _setmode(fileno(stdout), O_BINARY);
    _setmode(fileno(stdin), O_BINARY);
    return (ConvertUnixToDos(stdin, stdout, ipFlag));
#elif defined(MSDOS) || defined(__OS2__)
    setmode(fileno(stdout), O_BINARY);
    setmode(fileno(stdin), O_BINARY);
    return (ConvertUnixToDos(stdin, stdout, ipFlag));
#else
    return (ConvertUnixToDos(stdin, stdout, ipFlag));
#endif
}


int main (int argc, char *argv[])
{
  /* variable declarations */
  int ArgIdx;
  int CanSwitchFileMode;
  int ShouldExit;
  int RetVal = 0;
  CFlag *pFlag;
  char *ptr;
#ifdef ENABLE_NLS
  char localedir[1024];

   ptr = getenv("DOS2UNIX_LOCALEDIR");
   if (ptr == NULL)
      strcpy(localedir,LOCALEDIR);
   else
   {
      if (strlen(ptr) < sizeof(localedir))
         strcpy(localedir,ptr);
      else
      {
         fprintf(stderr, "%s", _("unix2dos: error: Value of environment variable UNIX2DOS_LOCALEDIR is too long.\n"));
         strcpy(localedir,LOCALEDIR);
      }
   }

   setlocale (LC_ALL, "");
   bindtextdomain (PACKAGE, localedir);
   textdomain (PACKAGE);
#endif


  /* variable initialisations */
  ArgIdx = 0;
  CanSwitchFileMode = 1;
  ShouldExit = 0;
  pFlag = (CFlag*)malloc(sizeof(CFlag));  
  pFlag->NewFile = 0;
  pFlag->Quiet = 0;
  pFlag->KeepDate = 0;
  pFlag->ConvMode = 0;
  pFlag->NewLine = 0;
  pFlag->Force = 0;
  pFlag->status = 0;
  pFlag->stdio_mode = 1;

  if ( ((ptr=strrchr(argv[0],'/')) == NULL) && ((ptr=strrchr(argv[0],'\\')) == NULL) )
    ptr = argv[0];
  else
    ptr++;

  if ((strcmpi("unix2mac", ptr) == 0) || (strcmpi("unix2mac.exe", ptr) == 0))
    pFlag->ConvMode = 3;

  while ((++ArgIdx < argc) && (!ShouldExit))
  {
    /* is it an option? */
    if (argv[ArgIdx][0] == '-')
    {
      /* an option */
      if ((strcmp(argv[ArgIdx],"-h") == 0) || (strcmp(argv[ArgIdx],"--help") == 0))
      {
        PrintUsage();
        return(0);
      }
      else if ((strcmp(argv[ArgIdx],"-k") == 0) || (strcmp(argv[ArgIdx],"--keepdate") == 0))
        pFlag->KeepDate = 1;
      else if ((strcmp(argv[ArgIdx],"-f") == 0) || (strcmp(argv[ArgIdx],"--force") == 0))
        pFlag->Force = 1;
      else if ((strcmp(argv[ArgIdx],"-q") == 0) || (strcmp(argv[ArgIdx],"--quiet") == 0))
        pFlag->Quiet = 1;
      else if ((strcmp(argv[ArgIdx],"-l") == 0) || (strcmp(argv[ArgIdx],"--newline") == 0))
        pFlag->NewLine = 1;
      else if ((strcmp(argv[ArgIdx],"-V") == 0) || (strcmp(argv[ArgIdx],"--version") == 0))
      {
        PrintVersion();
#ifdef ENABLE_NLS
        PrintLocaledir(localedir);
#endif
        return(0);
      }
      else if ((strcmp(argv[ArgIdx],"-L") == 0) || (strcmp(argv[ArgIdx],"--license") == 0))
      {
        PrintLicense();
        return(0);
      }
      else if ((strcmp(argv[ArgIdx],"-c") == 0) || (strcmp(argv[ArgIdx],"--convmode") == 0))
      {
        if (++ArgIdx < argc)
        {
          if (strcmpi(argv[ArgIdx],"ascii") == 0)
            pFlag->ConvMode = 0;
          else if (strcmpi(argv[ArgIdx], "7bit") == 0)
            pFlag->ConvMode = 1;
          else if (strcmpi(argv[ArgIdx], "iso") == 0)
            pFlag->ConvMode = 2;
          else if (strcmpi(argv[ArgIdx], "mac") == 0)
            pFlag->ConvMode = 3;
          else
          {
            if (!pFlag->Quiet)
              fprintf(stderr, _("unix2dos: invalid %s conversion mode specified\n"),argv[ArgIdx]);
            ShouldExit = 1;
          }
        }
        else
        {
          ArgIdx--;
          if (!pFlag->Quiet)
            fprintf(stderr,_("unix2dos: option '%s' requires an argument\n"),argv[ArgIdx]);
          ShouldExit = 1;
        }
      }

      else if ((strcmp(argv[ArgIdx],"-o") == 0) || (strcmp(argv[ArgIdx],"--oldfile") == 0))
      {
        /* last convert not paired */
        if (!CanSwitchFileMode)
        {
          if (!pFlag->Quiet)
            fprintf(stderr, _("unix2dos: target of file %s not specified in new file mode\n"), argv[ArgIdx-1]);
          ShouldExit = 1;
        }
        pFlag->NewFile = 0;
      }

      else if ((strcmp(argv[ArgIdx],"-n") == 0) || (strcmp(argv[ArgIdx],"--newfile") == 0))
      {
        /* last convert not paired */
        if (!CanSwitchFileMode)
        {
          if (!pFlag->Quiet)
            fprintf(stderr, _("unix2dos: target of file %s not specified in new file mode\n"), argv[ArgIdx-1]);
          ShouldExit = 1;
        }
        pFlag->NewFile = 1;
      }
      else { /* wrong option */
        PrintUsage();
        return(0);
      }
    }
    else
    {
      pFlag->stdio_mode = 0;
      /* not an option */
      if (pFlag->NewFile)
      {
        if (CanSwitchFileMode)
          CanSwitchFileMode = 0;
        else
        {
          RetVal = ConvertUnixToDosNewFile(argv[ArgIdx-1], argv[ArgIdx], pFlag);
          if (pFlag->status & NO_REGFILE)
          {
            if (!pFlag->Quiet)
              fprintf(stderr, _("unix2dos: Skipping %s, not a regular file.\n"), argv[ArgIdx-1]);
          } else if (pFlag->status & BINARY_FILE)
          {
            if (!pFlag->Quiet)
              fprintf(stderr, _("unix2dos: Skipping binary file %s\n"), argv[ArgIdx-1]);
          } else {
            if (!pFlag->Quiet)
            {
              if (pFlag->ConvMode == 3)
                fprintf(stderr, _("unix2dos: converting file %s to file %s in MAC format ...\n"), argv[ArgIdx-1], argv[ArgIdx]);
              else
                fprintf(stderr, _("unix2dos: converting file %s to file %s in DOS format ...\n"), argv[ArgIdx-1], argv[ArgIdx]);
            }
            if (RetVal)
            {
              if (!pFlag->Quiet)
                fprintf(stderr, _("unix2dos: problems converting file %s to file %s\n"), argv[ArgIdx-1], argv[ArgIdx]);
              ShouldExit = 1;
            }
          }
          CanSwitchFileMode = 1;
        }
      }
      else
      {
        RetVal = ConvertUnixToDosOldFile(argv[ArgIdx], pFlag);
        if (pFlag->status & NO_REGFILE)
        {
          if (!pFlag->Quiet)
            fprintf(stderr, _("unix2dos: Skipping %s, not a regular file.\n"), argv[ArgIdx]);
        } else if (pFlag->status & BINARY_FILE)
        {
          if (!pFlag->Quiet)
            fprintf(stderr, _("unix2dos: Skipping binary file %s\n"), argv[ArgIdx]);
        } else {
          if (!pFlag->Quiet)
          {
            if (pFlag->ConvMode == 3)
              fprintf(stderr, _("unix2dos: converting file %s to MAC format ...\n"), argv[ArgIdx]);
            else
              fprintf(stderr, _("unix2dos: converting file %s to DOS format ...\n"), argv[ArgIdx]);
          }
          if (RetVal)
          {
            if (!pFlag->Quiet)
              fprintf(stderr, _("unix2dos: problems converting file %s\n"), argv[ArgIdx]);
            ShouldExit = 1;
          }
        }
      }
    }
  }

  /* no file argument, use stdin and stdout */
  if (pFlag->stdio_mode)
  {
    exit(ConvertUnixToDosStdio(pFlag));
  }


  if ((!pFlag->Quiet) && (!CanSwitchFileMode))
  {
    fprintf(stderr, _("unix2dos: target of file %s not specified in new file mode\n"), argv[ArgIdx-1]);
    ShouldExit = 1;
  }
  free(pFlag);
  return (ShouldExit);
}

