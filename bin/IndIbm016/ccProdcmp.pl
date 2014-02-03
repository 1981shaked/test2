#!/usr/local/bin/perl 
#-d:ptkdb
#-----------------------------------------------------#
# I N I T   S E C T I O N : 
#-----------------------------------------------------#   
# Name   : ccProdCmp.pl 
# Purpose: Copmare Build products between:
#           1. different versions
#           2. same version different machines
#           3. main and backup areas.
# 
# General Flow:  1.                       
#                2. 
#                3. 
#                4. 
#                5. 
# Usage / Examples: 
#	ccProdcmp.pl -p cbl600V64 -v v60_0 -c v59_9  
#	ccProdcmp.pl -p cbl600V64 -v v60_0 -cf /tmp/kuku 
#	ccProdcmp.pl -p cbl600V64 -v v60_0 -cf /tmp/kiki 
#	ccProdcmp.pl -p cbl600V64 -v v60_0 -f /tmp/kuku
#	ccProdcmp.pl -P lel -v v60_0 -cf /tmp/kiki
#	ccProdcmp.pl -P lel -v v60_0 -vrt 64O2 -cf /tmp/kiki
#       ccProdcmp.pl -M bl -v v60_0 -vrt 32 -cf /tmp/kiki
#	ccProdcmp.pl -P lel -v v59_9 -f /tmp/kiki
#                                                                                                       
# Assumptions:  1.  script "show_str.pl" 
#               2.  proj dir under ~user
#                                             
# Dependencies (files and scripts):   
#               1.  "show_str.pl"                                     
#                                                                                                       
# Author:        Ishay Azoulay
# Supervisor:    Doron Kapitulnik
# Date:          01/2006  
######################################################################################################### 
#-----------------------------------------------------#
# M A I N   S E C T I O N 
#-----------------------------------------------------#
# 

use File::Basename;
use Cwd 'chdir';
use IO::Handle;
use Env qw (ARCH
            USER
            CCPROJECTHOME
            HOME
            CCMNGRHOME
            CCPRODTYPE
           );
use File::stat;
use Getopt::Long qw(:config no_ignore_case );
use File::Find;
File::Find::follow => 1;

if (! -e $CCPROJECTHOME){
    print "Please do set_proj before you use this script...\n";
}
if ($CCPRODTYPE eq "ENS") {
   $cclogin = basename($CCPROJECTHOME);
   if ($cclogin =~ /mb_/) {
     $cclogin =~ s/^mb_//g;
   }
   $cclogin = "~" . "$cclogin";
   $cclogin =~ s{^~([^/]*)}{$1 ? (getpwnam($1))[7]: ( $ENV{HOME} || $ENV{LOGDIR} )}ex;
}

my $command = join ' ',@ARGV;
my $machine_name = `uname -n`;
chomp ($machine_name);
my $tdate = (split /_/,&StampTime)[0];
my $outputdir =  "$HOME/log/ccProdcmp/$tdate";
my $printMethod="All";

&makedir("$HOME/log");
&makedir("$HOME/log/ccProdcmp");
&makedir("$outputdir");
 
my $projdir;
my $product_name;
my $module_name;
my $vrt;
my $project_name;
my $hold_proj;
my $ver;
my $sver; # source version
my $outfile;
my $compare_file;
my $help;
my $backup_area;
my $missing;
my @found_files;
my $prefix;
my $suffix;
my $mb_proj =  "$CCPROJECTHOME/proj";
my @projects = ();
my @sorted = ();
my @back = ();
my @onlya = ();
my @onlyb = ();
my @orig = ();
my @product_files = ();
my @module_files = ();
my @tmp = ();
my $size;
my $total_size;
my $total_missing;
my $total_bi_size;
my $total_bi_missing;
my $VRT_OK;
my $old_backup;
my $OLD_BK;

#=== getoptions =====
my $opt_status = GetOptions( 'P=s'     => \$product_name,   # product
                             'M=s'     => \$module_name,    # module
                             'p=s'     => \$project_name,   # project
                             'vrt=s'   => \$vrt,            # variant
                             'v=s'     => \$sver,           # source version
                             'cf=s'    => \$outfile,        # create file
                             'c=s'     => \$cver,
                             'f=s'     => \$compare_file,
                             'bi:s'    => \$bi,
                             'h'       => \$help,
                             'bk:s'    => \$backup_area,
                             'obk:s'   => \$old_backup
                           );
if ($opt_status eq "") {
   usage();
}
if (defined ($help)) {
	usage();
}
if ( defined $sver ){
   $ver_unscore = $sver;
   $sver =~ s/_//g;
   $sver =~ s/^\v//g;
} else {
	usage();
}
if (defined $bi) {
	$bi = "true";
}
if (defined $vrt) {
	$VRT_OK = "true";
}

if (not defined $product_name ){
    if (not defined $module_name ){
        if (not defined $project_name ){
            usage();
        }
    }
}

if (defined $outfile) {
	open (CF,">$outfile") or die "Cant open file for output $outfile\n";
}

if (defined $cver) {
	$cver =~ s/_//g; # version to compare to
	$cver =~ s/^\v//g;
}

if (defined $compare_file) {
	unless ( -e $compare_file ) {
		print "The file $compare_file doesnt exist. Quitting ...\n";
		exit;
	}
}
if (defined $old_backup) {
	$OLD_BK = "true";
}
if (defined $backup_area and defined $old_backup) {
	print "Parameters -bk and -obk are exclusive, only one of them...\n";
	exit 9;
}
if (defined $backup_area or defined $old_backup) {
	$sarea = ""; # 
} else {
	$sarea="";
}

if (defined $backup_area or defined $old_backup) {
	$carea = "true";
	$prefix = "back_";
} 

if (not defined $outfile){
   if (not defined $cver){
     if (not defined $compare_file) {
       if (not defined $carea){
          usage();
       }
     }
   }
}

$timestamp = &StampTime;
&open_log;

#=================================
#========== create file ==========
#=================================

if (defined $outfile) {
	if (defined $product_name){
	   &print2file ("Script run on Machine: $machine_name Product: $product_name Created $timestamp param: $command\n");
	   #&print2file ("Product : $product_name   Created on $timestamp\n");
	   &handle_product();
	} elsif (defined $module_name ){
	   &print2file ("Script run on Machine: $machine_name Module: $module_name Created on $timestamp param: $command\n");
	   #&print2file ("Module : $module_name   Created on $timestamp\n");
	   &handle_module($module_name);
	} elsif (defined $project_name ){
	   &print2file ("Script run on Machine: $machine_name Project: $project_name Created on $timestamp param: $command\n");
	   #&print2file ("Project : $project_name   Created on $timestamp\n");
	   $project_name = $sarea . $project_name;
	   &handle_project($project_name);
	   &print2file(@found_files); 
	}
	close LOG_FILE;
	close CF;
	print "Done..\n";
	exit;
}

#============================================
#====== comparison between backup areas =====
#============================================
if (defined $carea) { # comparison between backup areas 
	if (defined $project_name) {
		&check_proj_backup($project_name);	# single project
	} elsif (defined $product_name) {       # projects of product
		unless ($VRT_OK) {
		  @projects = `$HOME/bin/show_str.pl -P $product_name -v $ver_unscore | cut -d: -f4 | sort | uniq`;
	    } else {
	      @projects = `$HOME/bin/show_str.pl -P $product_name -t $vrt -v $ver_unscore | cut -d: -f4 | sort | uniq`;
	    }
		chomp @projects;
		foreach $project_name (@projects) {
			&check_proj_backup($project_name);
		}
		print "\nTotal checked files: $total_size  Total missing: $total_missing \n";
		print LOG_FILE "\nTotal checked files: ",$total_size," Total missing: ",$total_missing,"\n";
		if ($bi) {
            print "\nTotal bi checked files: $total_bi_size  Total bi missing: $total_bi_missing \n";
			print LOG_FILE "Total bi checked files: ",$total_bi_size," Total bi missing: ",$total_bi_missing,"\n";
		}
	} elsif (defined $module_name) {       # projects of module
		 unless ($VRT_OK) {
		  @projects = `$HOME/bin/show_str.pl -M $module_name -v $ver_unscore | cut -d: -f4 | sort | uniq`;
		} else {
		  @projects = `$HOME/bin/show_str.pl -M $module_name -t $vrt -v $ver_unscore | cut -d: -f4 | sort | uniq`;
		}
		 chomp @projects;
		 foreach $project_name (@projects) {
		 	&check_proj_backup($project_name);
		 }
		 print "\nTotal checked files: $total_size  Total missing: $total_missing \n";
		 print LOG_FILE "\nTotal checked file: ",$total_size," Total missing: ",$total_missing,"\n";
		 if ($bi) {
		 	print "\nTotal bi checked files: $total_bi_size  Total bi missing: $total_bi_missing \n";
			print LOG_FILE "Total bi checked file: ",$total_bi_size," Total bi missing: ",$total_bi_missing,"\n";
		 }

	} else {
		print "Missing an element, project or module or product\n";
		exit 9;
	}
	close LOG_FILE;
	print "Done..\n";
	exit;
}
#comparisons between backup areas
#### end comparisons between backup areas

#=================================
#==== list to compare against ====
#=================================
if ( defined $compare_file ) { # we have a list to compare against 
	open (CMP,"$compare_file") or die "Cant open $compare_file $!\n";
	@cmp_file = <CMP>;
	chomp @cmp_file;
	shift @cmp_file; # eliminate first line
	close CMP;
	if (defined $project_name) {               # one project
		&check_proj_cmp($project_name);	
	} elsif (defined $product_name) {          # all product projects
		unless ($VRT_OK) {
		 @projects = `$HOME/bin/show_str.pl -P $product_name -v $ver_unscore | cut -d: -f4 | sort | uniq`;
		} else {
		 @projects = `$HOME/bin/show_str.pl -P $product_name -t $vrt -v $ver_unscore | cut -d: -f4 | sort | uniq`; 
		}
		chomp @projects;
		foreach $project_name (@projects) {
			#&check_proj_cmp($project_name);
			&handle_project($project_name);
			@product_files = (@product_files,@found_files);
		}
		chomp @product_files;
		@onlya = &simple_compare(\@cmp_file,\@product_files);
		@sorted = sort @onlya;
		@onlya = @sorted;
		$size = scalar @cmp_file;
		$missing = scalar @onlya;
		&print_chk_result(\@onlya,"Imported file $compare_file","Current projects of $product_name $ver_unscore",$size,$missing);
		if ($bi) {
			@onlyb = &simple_compare(\@product_files,\@cmp_file);
			@sorted = sort @onlyb;
			@onlyb = @sorted;
			$size = scalar @product_files;
			$missing = scalar @onlyb;
			&print_chk_result(\@onlyb,"Current projects of $product_name $ver_unscore","Imported file $compare_file",$size,$missing);
		}
	} elsif (defined $module_name) {             # all module projects
		unless ($VRT_OK) {
		 @projects = `$HOME/bin/show_str.pl -M $module_name -v $ver_unscore | cut -d: -f4 | sort | uniq`;
		} else {
		 @projects = `$HOME/bin/show_str.pl -M $module_name -t $vrt -v $ver_unscore | cut -d: -f4 | sort | uniq`;
		}
		chomp @projects;
		foreach $project_name (@projects) {
		 	#&check_proj_cmp($project_name);
		 	&handle_project($project_name);
		 	@module_files = (@module_files,@found_files);
		}
		chomp @module_files;
		@onlya = &simple_compare(\@cmp_file,\@module_files);
		@sorted = sort @onlya;
		@onlya = @sorted;
		$size = scalar @cmp_file;
		$missing = scalar @onlya;
		&print_chk_result(\@onlya,"Imported file $compare_file","Current projects of $module_name $ver_unscore",$size,$missing);
		if ($bi) {
			@onlyb = &simple_compare(\@module_files,\@cmp_file);
			@sorted = sort @onlyb;
			@onlyb = @sorted;
			$size = scalar @module_files;
			$missing = scalar @onlyb;
			&print_chk_result(\@onlyb,"Current projects of $module_name $ver_unscore","Imported file $compare_file",$size,$missing);
		}
		 
	} else {
		print "Missing an element, project or module or product\n";
		exit 9;
	}
	print "Done..\n";
	close LOG_FILE;
	exit;
	
}

#if ( defined $compare_file ) { # we have a list to compare against 
#==== end list to compare ====

#======================================     
#==== we have to compare versions  ====
#======================================     
if (defined $cver ) { # we have to compare versions 
	if (defined $project_name) {   # single project 
	 	if ($project_name =~ m/^.*(\d{3}).*$/) {
			unless ($1 eq $sver) {
				print "Mishmash $project_name not equales $sver...Please fix\n";
				exit 9;
			}
		} else {
			print "Wrong project name please check....\n";
			exit 9;
		}
		&check_proj_ver($project_name);	
	} elsif (defined $product_name) { # projects of product
		unless ($VRT_OK) {
		@projects = `$HOME/bin/show_str.pl -P $product_name -v $ver_unscore | cut -d: -f4 | sort | uniq`;
		} else {
		 @projects = `$HOME/bin/show_str.pl -P $product_name -t $vrt -v $ver_unscore | cut -d: -f4 | sort | uniq`;
		}
		chomp @projects;
		foreach $project_name (@projects) {
			&check_proj_ver($project_name);
		}
		print "\nTotal checked files: $total_size  Total missing: $total_missing \n";
		print LOG_FILE "\nTotal checked files: ",$total_size," Total missing: ",$total_missing,"\n";
		if ($bi) {
            print "\nTotal bi checked files: $total_bi_size  Total bi missing: $total_bi_missing \n";
			print LOG_FILE "Total bi checked files: ",$total_bi_size," Total bi missing: ",$total_bi_missing,"\n";
		}

	} elsif (defined $module_name) {    # projects of module
		 unless ($VRT_OK) {
		  @projects = `$HOME/bin/show_str.pl -M $module_name -v $ver_unscore | cut -d: -f4 | sort | uniq`;
		 } else {
		  @projects = `$HOME/bin/show_str.pl -M $module_name -t $vrt -v $ver_unscore | cut -d: -f4 | sort | uniq`;
		 }
		 chomp @projects;
		 foreach $project_name (@projects) {
		 	&check_proj_ver($project_name);
		 }
		 print "\nTotal checked files: $total_size  Total missing: $total_missing \n";
		 print LOG_FILE "\nTotal checked files: ",$total_size," Total missing: ",$total_missing,"\n";
		 if ($bi) {
            print "\nTotal bi checked files: $total_bi_size  Total bi missing: $total_bi_missing \n";
			print LOG_FILE "Total bi checked files: ",$total_bi_size," Total bi missing: ",$total_bi_missing,"\n";
		 }

	} else {
		print "Missing an element, project or module or product\n";
		exit 9;
	}
	print "Done..\n";
	close LOG_FILE;
	exit;
}
### End we have to compare versions  ##########
#-----------------------------------------------------#
# F U N C T I O N S   S E C T I O N 
#-----------------------------------------------------#

#======================
#=== open logfile  ====
#======================
# opens the log file
#
sub open_log {
	my $fname;
	
	$fname = basename($0);
	$log_file = "$outputdir/$fname" . "\." . $ver_unscore . "\." . "$timestamp";
	open (LOG_FILE,">$log_file") || die "cannot open file $log_file: $!";
	#print "Opened log_file..$log_file\n";
	
}

#===================
#  sub makedir =====
#===================
# if directory does not exists create it
#
sub makedir {
  my $directory = (shift or "");
  return if -d $directory;
  print "Creating directory $directory\n";
  mkdir $directory, 0755 or die "Problem creating directory $directory: $!\n";
}

#========================
#=== creat_file ==========
#========================
sub creat_file {
# print to log file   
   &print2file(@found_files);
}
#==========================
#=== handle_product =======
#==========================
# given product extracts projects by show_str.pl 
# 
sub dummy {
	my @list_of_modules = ();
	
	@list_of_modules=`$HOME/bin/show_str.pl -P $product_name -v $ver_unscore | cut -d: -f2 | sort | uniq`;
	chomp @list_of_modules;
	foreach $module_name (@list_of_modules){  
	   &handle_module($module_name);
	}
}

#==========================
#=== handle_product =======
#==========================
# given product extracts projects by show_str.pl 
# 
sub handle_product {

	unless ($VRT_OK) {
		@projects = `$HOME/bin/show_str.pl -P $product_name -v $ver_unscore | cut -d: -f4 | sort | uniq`;
	} else {
	    @projects = `$HOME/bin/show_str.pl -P $product_name -t $vrt -v $ver_unscore | cut -d: -f4 | sort | uniq`;
	}
	chomp @projects;
	foreach $project_name (@projects){  
	   &handle_project($project_name);
	   &print2file(@found_files);	    
	}
}

#=========================
#=== handle_module =======
#=========================
#given module extracts project by show_str.pl
# param module
sub handle_module {
	  my ($module_name) = shift;
	  my @list_of_projects = ();
	  
	  unless ($VRT_OK) {
	   @list_of_projects = `$HOME/bin/show_str.pl -M $module_name -v $ver_unscore | cut -d: -f4 | sort | uniq`;
	  } else {
	   @list_of_projects = `$HOME/bin/show_str.pl -M $module_name -t $vrt -v $ver_unscore | cut -d: -f4 | sort | uniq`; 
	  }
	  chomp @list_of_projects;
	  foreach $project_name (@list_of_projects){
		#&print2file("project $project_name $timestamp\n");
	    &handle_project($project_name);
		&print2file(@found_files);	    
	  }
}
#==========================
#=== print_chk_result  ====
#==========================
#print the check results
#params arrary,str1,str2,str3
sub  print_chk_result {
	my ($A,$str1,$str2,$str3,$str4) = @_;
	
	print "==============================================\n";
	print LOG_FILE "==============================================\n";
	if ((scalar @$A) > 0) {
		print "files in $str1 but not in $str2 ; Checked files: $str3 ; Missing: $str4 files\n";
		print LOG_FILE "files in $str1 but not in $str2 ; Checked files: $str3 ; Missing: $str4 files\n";
		for (@$A) {
			print "$_\n";
			print LOG_FILE "$_\n";
		}
	} else {
		print "files in $str1 but not in $str2 ; Checked Files: $str3 ; Missing: $str4 files\n";
		print LOG_FILE "files in $str1 but not in $str2 ; Checked Files: $str3 ; Missing: $str4 files\n";
	}
}

#==========================
#=== check_proj_cmp    ====
#==========================
# invoke handle_project get result
# compares between file and orig and vise versa
# print the results
#param: project
#
sub check_proj_cmp {
	my ($proj) = @_;

	&handle_project($proj);
	@orig = @found_files;
	chomp @orig;
	@onlya = &simple_compare(\@cmp_file,\@orig);
	$size = scalar @cmp_file;
	$missing = scalar @onlya;
	&print_chk_result(\@onlya,$compare_file,$proj,$size,$missing);
	if ($bi) {
		@onlyb = &simple_compare(\@orig,\@cmp_file);
		$size = scalar @orig;
		$missing = scalar @onlyb;
		&print_chk_result(\@onlyb,$proj,$compare_file,$size,$missing);
	}
}

#==========================
#=== check_proj_ver    ====
#==========================
#compare versions and print results
#param: project
#
sub check_proj_ver {
	my ($proj_orig) = @_;
    my $proj_ver;

    $proj_ver = $proj_orig;
	&handle_project($proj_orig);
	@orig = @found_files;
	chomp @orig;
	$proj_ver =~ s/$sver/$cver/g;	
	&handle_project($proj_ver);
	@back = @found_files;
	chomp @back;
	@onlya = &simple_compare(\@orig,\@back);
	$size = scalar @orig;
	$missing = scalar @onlya;
	$total_size += $size;
	$total_missing += $missing;
	&print_chk_result(\@onlya,$proj_orig,$proj_ver,$size,$missing);	
	if ($bi) {
		@onlyb = &simple_compare(\@back,\@orig);
		$size = scalar @back;
		$total_bi_size += $size;
		$missing = scalar @onlyb;
		$total_bi_missing += $missing;
		&print_chk_result(\@onlyb,$proj_ver,$proj_orig,$size,$missing);
	}
}

#==========================
#=== check_proj_backup ====
#==========================
#compare ver to backup and vise versa
#print the results and gather totals
#param: project
#
sub check_proj_backup {
	my ($proj_orig) = @_;
	my $proj;
	my $back_proj;

	$proj = "$proj_orig";
	unless (-d "$mb_proj/$proj") {
		print "No such project $proj\n";
		print LOG_FILE "No such project $proj\n";
		exit;
	}
	$back_proj =  "back_${proj_orig}";
	#unless (-d "$cclogin/$back_proj") {
	#	print "No such project $back_proj\n";
	#	print LOG_FILE "No such project $back_proj\n";
	#	exit;
	#}
	&handle_project($proj);
	@orig = @found_files;
	chomp @orig;
	&handle_project($back_proj);
	@back = @found_files;
	chomp @back;
	@onlya = &simple_compare(\@orig,\@back);
	$size = scalar @orig;
	$total_size += $size;
	$missing = scalar @onlya;
	$total_missing += $missing;	
	&print_chk_result(\@onlya,$proj,"$back_proj->$hold_proj",$size,$missing);
	if ($bi) {
		@onlyb = &simple_compare(\@back,\@orig);
		$size = scalar @back;
		$total_bi_size += $size;
		$missing = scalar @onlyb;
		$total_bi_missing += $missing;		
		&print_chk_result(\@onlyb,"$back_proj->$hold_proj",$proj,$size,$missing);
	}
}

#==========================
#=== simple compare =======
#==========================
#compares two arrays: member in a not in b
# those in b not in a
# returns array result
#param: ref array1, ref array2
#
sub simple_compare {
   my ($A,$B) = @_;
   my %seen = ();
   my @only = ();
   my $item;
   my %src = ();
   my %trg = ();
   my @src_proj = ();
   my @trg_proj = ();
   my @uniq = ();
   my %visited = ();
   my $i;
   my $src_prefix;
   my $trg_prefix;
   my %proj_map = ();
   my $prj1;
   my $file1;
   my $key1;
   my @tst = ();
    
   #%src = map {(split)[1] => (split)[0]} @$A;
   #%trg = map {(split)[1] => (split)[0]} @$B;
   
   %src = map {$_ => (split)[0]} @$A;
   %trg = map {$_ => (split)[0]} @$B;
   
   @src_proj = sort (values %src);
   @trg_proj = sort (values %trg);
  
   %visited = ();
   @uniq = grep { ! $visited{$_} ++ } @src_proj;
   @src_proj = @uniq;
   
   %visited = ();
   @uniq = ();
   @uniq = grep { ! $visited{$_} ++ } @trg_proj;
   @trg_proj = @uniq;
   
   unless (scalar @src_proj == scalar @trg_proj) {
   	 print "Num of projects not equal\n";
   	 print "Please check...\n";
   }
   
   foreach  $i (0..$#src_proj) {
   	  ($src_prefix) = (split (/\d+V/,$src_proj[$i]))[0];
   	  ($trg_prefix) = (split (/\d+V/,$trg_proj[$i]))[0];
   	  if ($src_prefix ne $trg_prefix ){
             unless ($CCPRODTYPE eq "ENS") {
   	        print "Proj dont match...please check..\n";
             }
   	     $proj_map{$src_proj[$i]} = $trg_proj[$i]; 
   	  } else {
   	     $proj_map{$src_proj[$i]} = $trg_proj[$i]; 
   	  }
   }
   


   # build lookup table
   %seen = map { $_ => 1 } keys %trg;
   # find those in A that aren't in B
   foreach $item (sort keys %src) {
      @tst = split /\s+/, $item;
      if (scalar @tst == 2) {
          ($prj1,$file1) = split /\s+/, $item;
          $key1 = "$proj_map{$prj1}" . " " . "$file1";
          #push @only,"$src{$item} $item" unless ($seen{$item});
          push @only,"$item" unless ($seen{$key1});
      } elsif (scalar @tst > 2) {
          ($prj1,$file1) = split /\s+\.\//, $item;
          $file1 = "\.\/" . "$file1";
          $key1 = "$proj_map{$prj1}" . " " . "$file1";
          push @only,"$item" unless ($seen{$key1});
      }
   }
   return @only;
}  

#==========================
#=== handle_project =======
#==========================
#looks in the proj dir for the dir by
#following the link, then chdir to it and 
#invoks the find proc.
#param: project name
sub handle_project {
	my ($project_name) = shift;
	my $proj_name;
	my $proj_point;
	my $dir;
	my $proj_ver;
    my $project_name1;

    if ($CCPRODTYPE eq "ENS") {
        $project_name1 = $project_name;        
        if ($project_name =~ /^back_.*$/) {	
            $project_name =~ s/back_//g;
            $proj_dir = "$cclogin/proj";
        } else {
            $proj_dir = "$CCPROJECTHOME/proj";
        }
    } else {
       $proj_dir = "$CCPROJECTHOME/proj";
    }
     
	#print LOG_FILE "$proj_name $timestamp $ver_unscore\n";
	$proj_name = "$proj_dir/$project_name";
	unless (-d "$proj_dir/$project_name") {
                print "==============================================\n";
		print "No such project $project_name\n";
                print LOG_FILE "==============================================\n";
		print LOG_FILE "No such project $project_name\n";
                return;
		#exit;
	}
	do {
	    $proj_point = readlink "$proj_name";
     	if (-l "$proj_dir/$proj_point"){
         	$proj_name = "$proj_dir/$proj_point";
     	} elsif (-d $proj_point) {
     	}
  	} until -d $proj_point;
    
    #### check old backup ####
	if ($OLD_BK and $project_name1 =~ /^back_.*$/) {
		($num) = (split /\./,$proj_point)[1];
		if ($num == 1) {
			$suffix = 2;
		} elsif ($num == 2) {
			$suffix = 1;
		} else {
			print "Illegal suffix $num, should be either 1 or 2 ...\n";
			exit 
		}
		chop $proj_point;
		$proj_point = $proj_point . $suffix;
		unless (-d $proj_point) {
		    #print "Cecking in other FS..\n";
		    $proj_name = "$cclogin/proj" . "/" . basename("$proj_point");
		    do {
	                $proj_point = readlink "$proj_name";
     	                if (-l "$proj_dir/$proj_point"){
         	            $proj_name = "$proj_dir/$proj_point";
     	                 } elsif (-d $proj_point) {
     	                 }
  	            } until -d $proj_point;
		} else {
		      print "Dir $proj_point not exists...Please check..\n";
		      #exit 9;
		}
	}

  	chdir "$proj_point";
	@found_files=();
	$hold_proj = basename("$proj_point");

	find (\&wanted, ".");
}

#==================
#=== wanted   =====
#==================
#this is the wanted sub for the File::Find module
#returns all type file under proj
#param: proj dir
sub wanted {
	my ($dev,$ino,$mode,$nlink,$uid,$gid);
	   (($dev,$ino,$mode,$nlink,$uid,$gid) = lstat($_)) &&
		-f _ 
		&&
		#(/^.*\.o\z/s || /^.*\.sl\z/s || /^.*\.so\z/s || /^.*\.a\z/s || /^.*\.exec\z/s) &&
		#print "$File::Find::dir $File::Find::name\n";
		#print "$File::Find::dir $_\n";
		push @found_files,"$hold_proj $File::Find::name\n";
		#push @found_files,"$File::Find::name\n";
		#push @found_files,"$_\n";
		return;
}

#==========================
#===  print2file    =======
#==========================
sub print2file {
  print CF @_;
}

#=========================
#== get the time stamp ===
#=========================
#create timestamp
sub StampTime {
        my (@ltime) = localtime time;
        my ($yyyy, $mon, $day, $hh, $mm, $ss);
        ($yyyy, $mon, $day, $hh, $mm, $ss) = @ltime[5,4,3,2,1,0];
        $yyyy += 1900;
        $mon++;
        #sprintf "%d/%02d/%04d %02d:%02d:%02d", $day, $mon, $yyyy, $hh, $mm, $ss;
        sprintf "%04d%02d%02d_%02d%02d%02d", $yyyy, $mon, $day, $hh, $mm, $ss;
}


#==========================
#=== sub usage   ==========
#==========================

sub usage {
	  print "\nUSAGE:\n";
	  print "{-P <Product> | -M <module> | -p <project> } -v <version> [-vrt <variant>] { -c <compare 2 version> | -bk | -cf <output compare file> | -f <compare to file> } [-bi] [-obk] [-bk] \n";

	  print "-h   - prints this message\n";
	  print "-P   - Product <product>.\n";
	  print "-M   - Module  <module>.\n";
	  print "-p   - project <proj>.\n";
	  print "-bi  - Check bi-directional all in prj1 not in prj2, all in prj2 not in prj1 \n";
	  print "-v   - Version <ver>.\n";
	  print "-vrt - Variant <variant>.\n";
	  print "-c   - compare to Version <ver>.\n";
	  print "-bk  - Compare to current backup area default: existing back_<proj> area .\n";
	  print "-obk - Compare to old backup back_<proj>.1 <-> back_<proj>.2 .\n";
	  print "-cf  - Create export file <file name> - to compare to using -f.\n";
	  print "-f   - Compare existing products to export file <file name>.\n";
          print "\nEnsemble users: please setenv CCPRODTYPE to \"ENS\"\n\n";
	  
	  print "Example: Export:        ccProdcmp.pl -P lel -v v60_0 -cf ~/tmp/kuku\n";
	  print "Example: with variant   ccProdcmp.pl -P lel -v v60_0 -vrt 64OG -cf /tmp/kiki\n";
	  print "Example: Import:        ccProdcmp.pl -P lel -v v60_0 -f  ~/tmp/kiki\n";
          print "Example: with variant   ccProdcmp.pl -M bl -v v60_0 -vrt 32 -cf /tmp/kiki\n";
	  print "Example: Ver compare:   ccProdcmp.pl -P lel -v v60_0 -c v61_0 \n";
	  print "Example: Ver compare:   ccProdcmp.pl -M bl -v v60_0 -c v61_0 -bi\n";
	  print "Example: Bck compare:   ccProdcmp.pl -P lel -v v60_0 -bk -bi\n";
	  print "Example: obk compare:   ccProdcmp.pl -P lel -v v60_0 -obk \n";
	  print "Example: Proj compare:  ccProdcmp.pl -p cet940V64OG -v v94_0 -c v95_0 -bi  \n";
	  exit;
}
