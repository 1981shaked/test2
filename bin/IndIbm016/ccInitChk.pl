#!/usr/local/bin/perl 
#-d:ptkdb
#====================================================
#==== Name       : ccInitChk.pl 
#==== Input file : init_files  at ~/bin (optional)
#==== Purpose    : check the init process in Unix 
#==== Usage      : ccInitChk.pl [-h] [-show] [-source]
#====                    [-env <ENV_VAR> [-i]]
#====                    [-patt <pattern> [-i]] 
#====                    [-cmp -v <sv> -f <file>] 
#====                    [-cf <file>] 
#==== Note:
#==== HP-UX : /etc/csh.login
#==== AIX   : /etc/csh.login
#==== SunOS : /local/site-init-files/csh.login
#==== 
#==== Author : Ishay Azoulay
#==== Date   : Jan/2007
#====================================================

#====add/remove here env vars you want always to check, space seperated only====
#====they will showup in the show parameter ====================================
our @ENVVAR = qw(
  ARCH USER CCPROJECTHOME HOME CCMNGRHOME CCPROJNAME SDKHOME CCPRODUCT CCPRODUCTVER
  CCMPA SDKRELEASE HARVESTHOME HARVESTDIR HARVESTSERVERDIR HAR_TWO_TASK HAR_REPORT_USER
  HAR_REPORT_PASS ORACLE_HOME BROKERNAME HARBROKERNAME HAR_WB_USER HAR_WB_PASSWD ORACLE_INSTANCE_NAME
  MODVER COMPVER CCVER
);

use Env @ENVVAR;
use IO::Handle;
use Getopt::Long qw(:config no_ignore_case );

#==== flash the spool ====
STDOUT->autoflush(1);
#==== catch control-c or interrupt ====
$SIG{INT} = \&HandlerSIGINT;
$SIG{HUP} = \&HandlerSIGHUP;

$oracle_home = "~oracle";
chomp $oracle_home;
$oracle_home =~ s{^~([^/]*)}{$1 ? (getpwnam($1))[7]: ( $ENV{HOME} || $ENV{LOGDIR} )}ex;
my $conf_file = "$HOME/bin/init_files";

#====================================================
#==== These are the config files in random order ====
#====================================================
my $line;
my $STEM_FILE;

if ((-e "$conf_file" and !-z "$conf_file") and (open (AA,"$conf_file"))) {
      print "\nSystem is $ARCH\n";
      print "Using config file $conf_file\n\n";
      while ($line = <AA>) {
      	#==== evaluate the variables from the file ====
      	next if $line =~ /^\s*#.*$/;
      	next if $line =~ /^(\s)*$/;
      	next if $line =~ /^$/;
      	chomp $line;
      	if ($line =~ /STEM/) {
      		($STEM_FILE) = (split /\s+/,$line)[1];
      		$line = $STEM_FILE;
      	}
      	$line =~ s{^~([^/]*)}{$1 ? (getpwnam($1))[7]: ( $ENV{HOME} || $ENV{LOGDIR} )}ex;
      	$line =~ s/(\$\w+)/$1/eeg;
        push @files,"$line";
      }
} else { 
	warn "$conf_file does not exist..Please create one...\n";
	exit;
}

my %TARGET_ENV = ();
my %SOURCE_ENV = ();
my %SOURCE_ENV = %ENV;
my $TRGVER;# = "v62_0";
my $LOCAL_SRCVER = $COMPVER ? $COMPVER : $CCVER; 
my $file; # = "$HOME/Personal/ishay/file_env_$SRCVER";
my $SRCVER=$LOCAL_SRCVER;
my $SRCVER_NO_UNDSCORE;
my $SRCVERNUM;
my $TRGVER_NO_UNDSCORE;
my $TRGVERNUM;

my $ignore_case;
my $default_send_to = "ishaya@amdocs.com";
my $ignore_case;
my $mailrc = "$HOME/.mailrc";
my $send_to;
my $help;
my $env_var;
my $pattern;
my $Mail;
my $log_file;
my @skipped = ();
my $Show;
my $ver;
my $compare_file;
my $cmp;
my $source;
my %KEEP = ();
my @ORDER = ();


$opt_status = GetOptions( 'h:s'      => \$help,
                          'source:s' => \$source,
                          'v=s'      => \$ver,
                          'env=s'    => \$env_var,
                          'patt=s'   => \$pattern,
                          'cmp:s'    => \$cmp,
                          'cf=s'     => \$log_file,
                          'f=s'      => \$compare_file,
                          'i:s'      => \$ignore_case,
                          'show:s'   => \$Show,
                           );
&check_param;

if (defined $env_var) {
	&find_var;
} elsif (defined $pattern) {
	&find_pattern;
} elsif (defined $cmp) {
    &compare_env;#
} 
&exit_close;

exit;

#=======================
#===  sub compare env ==
#=======================
sub compare_env {
  my ($key);
  
  &get_env_file($compare_file);
  #$TRGVER_NO_UNDSCORE = $TRGVER;
  #$TRGVER_NO_UNDSCORE =~ s/\_//g;
  #$TRGVERNUM = $TRGVER_NO_UNDSCORE;
  #$TRGVERNUM =~ s/\v//g;
  
  &process_ver($TRGVER,"trg");  
  &process_ver($SRCVER,"src");

  
  &clean_ver("src");
  &clean_ver("trg");
  print "\nComparing current env $SRCVER to $TRGVER in file $compare_file\n";
  print "================================================================================\n";
  foreach $key (sort keys %{{%TARGET_ENV,%SOURCE_ENV}}) {
  #========= source ============
   if ($SOURCE_ENV{$key} ne $TARGET_ENV{$key} ) {
     print "SOURCE:$key $SOURCE_ENV{$key}\n";
     print "-\n";
     print "TARGET:$key $TARGET_ENV{$key}\n";
     print "-----------------------------\n";
   } 
  }

}
#========================
#==== clean_ver      ====
#========================
sub clean_ver {
  my ($dummy) = @_;
  my ($key,$value);
  
  if ($dummy eq "src") {
    while (($key,$value) = each %SOURCE_ENV) {
      if ($value =~ /ABP\d\d\d/) {
        $value =~ s/ABP\d\d\d//g;
      }
      if ($value =~ /$SRCVER/) {
        $value =~ s/$SRCVER//g;
      }
      if ($value =~ /$SRCVER_NO_UNDSCORE/) {
        $value =~ s/$SRCVER_NO_UNDSCORE//g;
      }
      if ($value =~ /$SRCVERNUM/) {
        $value =~ s/$SRCVERNUM//g;
      }
      if ($value =~ /v\d\d\d/) {
        $value =~ s/v\d\d\d//g;
      }
      if ($value =~ /v\d\d_\d/) {
        $value =~ s/v\d\d_\d//g;
      }
      if ($value =~ /\d\d\d/) {
        $value =~ s/\d\d\d//g;
      }
      

      $SOURCE_ENV{$key} = $value;
    }
  } elsif ($dummy eq "trg") {
    while (($key,$value) = each %TARGET_ENV) {
      if ($value =~ /ABP\d\d\d/) {
        $value =~ s/ABP\d\d\d//g;
      }
      if ($value =~ /$TRGVER/) {
        $value =~ s/$TRGVER//g;
      }
      if ($value =~ /$TRGVER_NO_UNDSCORE/) {
        $value =~ s/$TRGVER_NO_UNDSCORE//g;
      }
      if ($value =~ /$TRGVERNUM/) {
        $value =~ s/$TRGVERNUM//g;
      }
      if ($value =~ /v\d\d\d/) {
        $value =~ s/v\d\d\d//g;
      }
      if ($value =~ /v\d\d_\d/) {
        $value =~ s/v\d\d_\d//g;
      }
      if ($value =~ /\d\d\d/) {
        $value =~ s/\d\d\d//g;
      }

      $TARGET_ENV{$key} = $value;
     }
  } else {
      print "trg or src param only\n";
  }
}
#======================
#==== process_ver  ====
#======================
sub process_ver {
  my ($ver,$dummy) = @_;
  if ($dummy eq "src"){
     $SRCVER_NO_UNDSCORE = $LOCAL_SRCVER;
     $SRCVER_NO_UNDSCORE =~ s/\_//g;
     $SRCVERNUM = $SRCVER_NO_UNDSCORE;
     $SRCVERNUM =~ s/\v//g;
  } elsif ($dummy eq "trg") {
     $TRGVER_NO_UNDSCORE = $TRGVER;
     $TRGVER_NO_UNDSCORE =~ s/\_//g;
     $TRGVERNUM = $TRGVER_NO_UNDSCORE;
     $TRGVERNUM =~ s/\v//g;
  } else {
     print "wrong param src or trg ony..\n";
  }
}

#======================
#==== get_env_file ====
#======================
sub get_env_file {
  my ($file) = @_;
  my (@a) = ();
  my ($b,$c,$d,$e,$dummy);
  
  if (!-e "$file" or -z "$file") {
    print "$file does not exist or is empty...\n";
    return;
  }
  open (FILE,"$file") or die "$file $!\n";
  @a=<FILE>;
  chomp (@a);
  $e = shift @a;
  ($dummy,$TRGVER) = split (/=/,$e);
  close FILE;
  foreach $b (@a) {
    ($c,$d) = split (/=/,$b,2);
    $TARGET_ENV{$c} = $d;
  }
}
#=======================
#===  sub check param ==
#=======================
sub check_param {
	# check if no param entered
	if (   !defined $env_var &&         !defined $help &&        !defined $pattern
	    && !defined $compare_file &&    !defined $ignore_case && !defined $Show
	    && !defined $log_file &&        !defined $cmp         && !defined $source) {
		&Usage;
		&exit_close;
	}
	#check if help is needed
	if (defined($help)) {
		&Usage;
		&exit_close;	
	}
	if ( (defined $env_var && defined $pattern) or
	      (defined $env_var && defined $cmp) or 
	      (defined $cmp && defined $pattern) ) {
	      	print "One param allowed..\n";
	      	&exit_close;
	}

	if (defined $source) {
		print "Files which may be sourced...\n";
		print "=============================\n";
		unless ($STEM_FILE) {
			print "No stem_file in init_files...please check..\n";
		} else {
			&find_source("$STEM_FILE");
		}
		print "=============================\n";
		foreach (@ORDER) {
		  print "$_\n";
		}
		&exit_close;
	}
	#=== print ENV VARS and Files ====
	if (defined $Show) {
		print "========================================\n";
        print "Partial Env Vars and their contents ====\n";
        print "========================================\n";
        for (@ENVVAR) {
	      printf ("%-25s =  %-30s\n",$_,$$_);
        }

		print "================================\n";
		print "$0 searches in these files..\n";
		print "================================\n";
		for (@files) {
			print "$_\n";
		}
		&exit_close;
	}
	#-------------------
    #---- check ver ----
    #-------------------
    if ( defined $ver ){
      unless ($ver =~ m/v\d\d\_\d/) {
         print "The right syntax is v[0-9][0-9]_[0-9]\n";
         exit 9;
      }
      $SRCVER = $LOCAL_SRCVER;
      ($SRCVER_NO_UNDSCORE = $SRCVER) =~ s/_//g;
      ($SRCVERNUM = $SRCVER_NO_UNDSCORE) =~ s/^\v//g;
      print "SRCVER= $SRCVER SRCVER_NO_UNDSCORE $SRCVER_NO_UNDSCORE\n";
      if ($SRCVER ne $LOCAL_SRCVER) {
        print "Mishmash Please check set_prod...\n";
        exit 9;
      }
    }
    #---------------------------------
	#---- create file for compare ----
	#---------------------------------
	if (defined $log_file) {
	  &create_env_file($log_file);
	  exit 9;
	}
    #---------------------------------
	#---- compare current to file ----
	#---------------------------------
	if (defined $compare_file) {
      if (!-e $compare_file or -z $compare_file) {
        print "$compare_file not exist or empty.. please check..\n";
        exit 9;
      }
    }
	if (defined $cmp && !defined $compare_file) {
	   print "enter -cmp  -f <file>\n";
	   exit 9;
	} 
	#check if Module or Product are missing or are both 
	if ((!defined $env_var && !defined $pattern && !defined $cmp ) || (defined $env_var && defined $pattern && defined $cmp)) {
		print "\n Please enter either EnvVAr or pattern or cmp\n\n";
		&exit_close;
	}
	
	#check if you want ignore case
	unless (defined $ignore_case) {
		$ignore_case = "false";
	} else {
		$ignore_case = "true";
	}
	
	#check optional mail, default send to cc team
	if (defined $Mail){
		&check_mail($Mail,$mailrc);
	} else {
		$send_to = $default_send_to;
	}
}


#=========================
#==== create env file ====
#=========================
#saves the %ENV into a file
sub create_env_file {
  my ($my_file) =  @_;

  open (FILE,">$my_file") or die "Cant open $file $!\n";
  print FILE "VERSION=$SRCVER\n";
  foreach $key (keys(%ENV)) {
    #print "$key $ENV{$key}\n";
    print FILE "$key=$ENV{$key}\n";
  }
  close FILE;
}


#======================
#===  find pattern ====
#======================
sub find_pattern {
    my @enve = ();
    my @res = ();
    my $file;
    my $value;
    my $found;
    my @all = ();
    
    
	foreach $file (@files) {
		$found = '';
		@res = ();
		unless (-e "$file") {
			push @skipped,"$file";
			next;
		}
		if (open (F,"$file") ) {
			my @contents = <F>;
			chomp @contents;
			if ($ignore_case eq "true") {
				@res = grep /\b$pattern\b/i , @contents;
			} else {
				@res = grep /\b$pattern\b/ , @contents;
			}
			if (@res) {
				$found = "true";
			}
		}
		close F;
		if ($found) {
	        #&print_log ("====> $file\n");
	        push @all,$file;
		}
	}
	unless (@all) {
		print "\nPattern $pattern not found..\n";
	} else {
    	print "====================================\n";
		print "Located $pattern in these files...  \n";
		print "====================================\n";
		for (@all) {
			&print_log ("====> $_\n");
		}
	}
}

#======================
#===  find env var ====
#======================
sub find_var {
    my @enve = ();
    my @res = ();
    my $file;
    my $value;
    my $found;
    my @all = ();
    
    
	if ($env_var) {
		if ($ENV{$env_var}) {
			&print_log ("\n\$$env_var = $ENV{$env_var}\n");
		} else {
			&print_log ("\nENV: \$$env_var  is NOT SET\n");
		}
	}
	
	foreach $file (@files) {
		@res = ();
		$found = '';
		unless (-e "$file") {
			push @skipped,"$file";
			next;
		}
		if (open (F,"$file") ) {
			my @contents = <F>;
			chomp @contents;
			if ($ignore_case eq "true") {
				#@res = grep /\b$env_var\b/i , @contents;
				@res = grep /\bsetenv\b\s+\b$env_var\b/i , @contents;
			} else  {
				@res = grep /\bsetenv\b\s+\b$env_var\b/ , @contents;
			}
			if (@res) {
				$found = "true";
			}
		}
		close F;
		if ($found) {
			#&print_log ("====> $file\n");
			push @all,$file;
		}
	}
	unless (@all) {
		print "setenv $env_var not found..\n";
	} else {
    	print "====================================\n";
    	print "Located $env_var in these files...  \n";
    	print "====================================\n";
    	for (@all) {
    		&print_log ("====> $_\n");
    	}
	}
}

#======================
#===  find source  ====
#======================
sub find_source {
    my ($file) = @_;
    my ($line,$indx,$ff);
    my @f = ();
    my @content = ();
    
    if (!-s "$file") {
       print "$file does not exist or empty ...\n";
       return;
    }
    $KEEP{$file}++;
    push @ORDER,$file unless grep {/$file/} @ORDER;
    open (KK,"$file") or warn "Could not open $file $!\n";
	#print "$file\n";
	#print "-------------\n";
    
    @content = <KK>;
    close KK;
    chomp @content;
    foreach (@content) {
      #==== ignore comments, empty lines and aliases ====
      next if /^\s*#/;
      next if /^$/;
      next if /^\s*alias\s+.*$/;
      if ( /source/) {
        $line = $_;
        @f = (split /\s+/,$line);
        for ($indx=0;$indx <= $#f;$indx++) {
          if ($f[$indx] =~ /source/) {
             $ff = $f[$indx+1];
             $ff =~ s/\{//g;
             $ff =~ s/\}//g;
             #==== evaluate variables ====
             $ff =~ s/(\$\w+)/$1/eeg;
             #==== deal with tilde ====
             $ff =~ s{^~([^/]*)}{$1 ? (getpwnam($1))[7]: ( $ENV{HOME} || $ENV{LOGDIR} )}ex;
             #print "source $ff\n";
             &find_source("$ff");
          }
        }
      }
    }    
}
#=================================
#===  Signal handler for SIGINT ==
#=================================
sub HandlerSIGINT {
        close LG;
        die "***Caught Interrupt\n";
}

#==================================
#==  Signal handler for SIGHUP ====
#==================================
sub HandlerSIGHUP {
        close LG;
        die "***Caught Hangup\n";
}

#==============
#=== usage ====
#==============
sub Usage {
	print "
	This script checks in the init files for the existanse of
	an ENVIRONMENT VARIABLE or a certain pattern.
	Init files are in a file: init_files under \$HOME/bin.
	
	-h    	Help
	-env  	<environment variable>
	-show	prints the config files
	-source prints the possible source files 
	-patt 	<pattern> 
	-i  	ignore case
	-cf 	<file>
	-cmp    compare current env to file
	-f      <file>
		
	invocation:
        $0      [-h] [-show] [-source]
                [-env <ENV_VAR> [-i]]
                [-patt <pattern> [-i]] 
                [-cmp -v <sv> -f <file>] 
                [-cf <file>] 
	example: $0 -show
	example: $0 -source
	example: $0 -patt CCCORETYPE  
	example: $0 -patt cccortype -i
	example: $0 -env CCCORTYPE
	example: $0 -cf  ~/tmp/env_620
	example: $0 -cmp -v v60_0 -f ~/tmp/env_620
	\n";
}

#==============
#=== exit  ====
#==============
sub exit_close {
	
	print "Done\!\n";
	close LG;
	exit 9;
}
#======================
#=== print log     ====
#======================
sub print_log {
	my ($msg) = @_;
	if (defined $log_file) {
		print LG "$msg";
	}
	print "$msg"; 
}
