#!/usr/local/bin/perl 
#-d:ptkdb
use Getopt::Long;
use XML::Simple;
use Env qw (ARCH HOME WL_HOME HOST ORACLE_LIB JAVA_HOME );
push (@INC, "$HOME/bin");
require general_cc_func;
my $scriptname=(split /\//,$0)[-1];
my $logscriptname=(split/\./,$scriptname)[0];
my $ts=`timestamp`;
my $checked_dirs;
chomp $ts;
$opt_status = GetOptions(                                                 
	'h'          => \$help,
	'up'         => \$update,
	'cr'         => \$create,
	'opt'         => \$optimize,
	'p:s'        => \$product,
	'v:s'        => \$version,
	'sdk'        => \$checksdk,
	'proj'       => \$checkprod,
	'sca'        => \$checksca,
	'fd'         => \$filedetail,
	'mr:s'       => \$MappingRule,
	'sc:s'       => \$searchclass,
	'test'       => \$test,
	'xml'        => \$xml,
);
&check_param;
&main;
sub main{
	my @jar_list=();
	my $new_classes,$old_classes;
	if ($searchclass){
		($old_classes)=&get_classes_from_file("$script_files_location/$classes_file");
		&search_class($old_classes);
		exit;
	}elsif ($filedetail){
		($old_classes)=&get_classes_from_file("$script_files_location/$classes_file");
		&get_filetracking_from_file($old_classes);
		exit;
	}elsif ($create){
		@jar_list=&get_jar_list;
		($new_classes)=create_class_hash(@jar_list);
		&create_classes_files($new_classes);
		exit;
	}elsif ($update){
		@jar_list=&get_jar_list;
		($new_classes)=create_class_hash(@jar_list);
		($old_classes)=&get_classes_from_file("$script_files_location/$classes_file");
		$update_classes=&compare_hashes($new_classes,$old_classes);
		&create_classes_files($update_classes);
		exit;
	}elsif ($optimize){
		($old_classes)=&get_classes_from_file("$script_files_location/$classes_file");
		&create_optimize_file($old_classes);
	}
}
sub check_param {
  &Usage("product and version are mandatory flags") if ((!$product)||(!$version));
  &Usage("product or version do not exist") if (!-d "$HOME/product/$product/v$version");
  &Usage("-cr and -up cannot be used together") if ((defined $update) && (defined $create));
  $classes_file="${product}_${version}_ccClassMap_classes_file";
	$script_files_location="$HOME/log/$logscriptname";
	system ("mkdir -p $HOME/log/$logscriptname") if (!-d "$HOME/log/$logscriptname");
  if (defined $MappingRule){
 	$configfilename="ccConfigFile.xml";
	$configfile="$HOME/bin/$configfilename";
	&Usage("$configfile does not exist") if (!-e "$configfile");
	$checked_dirs="$MappingRule(MappingRule);";
  &load_xml_data;
  }else{
  	$generaldir="${ORACLE_LIB};${JAVA_HOME};${WL_HOME}";
  	$checked_dirs="\${ORACLE_LIB};\${JAVA_HOME};\${WL_HOME};";
  }
}			
sub load_xml_data{
	$xml_config = XMLin("$configfile",ForceArray => [scriptname,MappingRule],Variables => { HOME => $HOME , ORACLE_LIB => $ORACLE_LIB , WL_HOME => $WL_HOME , JAVA_HOME => JAVA_HOME} );
	&Usage("Rule $MappingRule does not exist ") if (!$xml_config->{scriptname}{$scriptname}->{MappingRule}{$MappingRule});
	$generaljar = $xml_config->{scriptname}{$scriptname}->{MappingRule}{$MappingRule}->{GENERALJAR};
	$generaldir = $xml_config->{scriptname}{$scriptname}->{MappingRule}{$MappingRule}->{GENERALDIR};
}
sub get_jar_list{
	@dir_path,@modules,@projs,@bbs,$dir,$search_dir,$genjar,@jars,@jar_list=();
	my $bbversion="v".(substr($version,0,-1))."_".(substr($version,-1));
	if ($checksca){
		$checked_dirs=$checked_dirs."sca;";
		@modules=module_list($product,$version);
		foreach $module(@modules){
			@projs=proj_list($module,$version);
			foreach $proj(@projs){
				@bbs=bb_list($proj);
				foreach $bb(@bbs){
			 		push (@dir_path,"$HOME/bb/$bb/$bbversion");
				}
			}
		}
	}
	if ($checkprod){
		$checked_dirs=$checked_dirs."proj;";
		@modules=module_list($product,$version);
		foreach $module(@modules){
			@projs=proj_list($module,$version);
			foreach $proj(@projs){
					push (@dir_path,"$HOME/proj/$proj");
			}
		}	
	}
	if ($checksdk){
		$checked_dirs=$checked_dirs."sdk;";
		if (-f "$HOME/data/cc_local.dat.v${version}.${product}"){
			open (CCLOCALDAT, "$HOME/data/cc_local.dat.v${version}.${product}");
		}elsif (-f "$HOME/data/cc_local.dat.v${version}"){
			open (CCLOCALDAT, "$HOME/data/cc_local.dat.v${version}");
		}elsif (-f "$HOME/data/cc_local.dat"){
			open (CCLOCALDAT, "$HOME/data/cc_local.dat");
		}else{
			Usage("couldnt find cc_local.dat file for SDKRELEASE");
		}
		@cclocaldat=<CCLOCALDAT>;
		close CCLOCALDAT;
		chomp (@cclocaldat);
		foreach $line(@cclocaldat){
			if ((split/=/,$line)[0] eq "SDKRELEASE"){
				$sdkrelease=(split/=/,$line)[1];
				last;
			}
		}
		push (@dir_path,"$HOME/SDKRoot/$sdkrelease");
	}
	foreach $dir(split /;/,$generaldir){
		push (@dir_path,"$dir");
	}
	foreach $search_dir(@dir_path){
		if (-d $search_dir ){
			@jars=`find ${search_dir}/* -type f -name '*.jar'`;
			chomp (@jars);
			push (@jar_list,@jars);
		}else{
			# print "could not search in $search_dir\n";
		}
	}
	foreach $genjar(split /;/,$generaljar){
		push (@jar_list,"$genjar");
	}
	return @jar_list;
}
sub create_class_hash{
	my $ts=`timestamp`;
	chomp $ts;
	my %classes =();
	my %classes_status =();
	my @jar_list=@_;
	my @class_list,@class_full_path=();
	my $jar,$line,$class_name,$class_path,$uniq,$timestamp,$status;
	my $i=0;
	foreach $jar(@jar_list){
		next if (!-e "$jar");
		$i++;
		print "serach in $jar\n" if ($test);
		@class_list=();
		@class_list=`jar tvf $jar`;
		chomp @class_list;
		foreach $line(@class_list){
			@class_full_path=(split /\//,(split /\s+/,$line)[-1]);
			$class_name=pop(@class_full_path);
			$class_path=$jar."/".(join ("/",@class_full_path));
			if ($class_name =~ /.*\.class/){
				$classes{ $class_name }{ $class_path }{ $ts } = "exist";
			}
		}
	}
	$checked_dirs=$checked_dirs.":".$ts.":".$i;
	$classes{ "FileTracking\.class" }{ $checked_dirs }{$ts} = "exist"; 
	return (\%classes);
}
sub create_classes_files{
	my ($classes)=(@_);
	my $class_name,$class_path,$jar_name,$class_date,$timestamp;
	system "mkdir -p $script_files_location" if (!-d $script_files_location);
	if ($update){
		open (CLASSES_FILES,">>","$script_files_location/$classes_file");
	}else{
		open (CLASSES_FILES,">","$script_files_location/$classes_file");
	}
	for $class_name ( sort keys %$classes ){
		for $class_path (	sort keys %{$classes->{$class_name}} ){
			for $timestamp (	sort keys %{$classes->{$class_name}->{$class_path}} ){
				print CLASSES_FILES "$class_name $class_path $timestamp $classes->{$class_name}->{$class_path}->{$timestamp}\n";
			}
		}
	}
	
	close CLASSES_FILES;
}
sub get_classes_from_file{
	my $classes_file=(@_[0]);
	my @current_classes=();
	my %classes =();
	my $class_name,$class_path,$ts,$status;
	open (CLASSES_FILES,"<$classes_file") ;
	@current_classes=<CLASSES_FILES>;
	chomp (@current_classes);
	close(CLASSES_FILES);
	foreach $line (@current_classes){
		($class_name,$class_path,$ts,$status)=((split/\s+/,$line)[0],(split/\s+/,$line)[1],(split/\s+/,$line)[2],(split/\s+/,$line)[3]);
		$classes{ $class_name }{ $class_path }{ $ts } = "$status";
	}
	return (\%classes);
}
sub compare_hashes{
	my ($new_classes,$old_classes)=(@_[0],@_[1]);
	my %new_lines;
	my $ts=`timestamp`;
	chomp $ts;
	my $class_name,$class_path,$timestamp;
	my $new_line,$old_line;
	for $class_name ( sort keys %$new_classes ){
		if ($old_classes->{$class_name}){
			for $class_path (	sort keys %{$new_classes->{$class_name}} ){
				if ($old_classes->{$class_name}->{$class_path}){
					for $timestamp (	sort hashValueDescendingNum keys %{$old_classes->{$class_name}->{$class_path}} ){
						if 	($old_classes->{$class_name}->{$class_path}->{$timestamp} eq "delete" ){
							$new_lines{ $class_name }{ $class_path }{ $ts } = "exist";
							last;
						}
					}
				}else{
						$new_lines{ $class_name }{ $class_path }{ $ts } = "exist";
				}
			}
		}else{
			for $class_path (	sort keys %{$new_classes->{$class_name}} ){
				$new_lines{ $class_name }{ $class_path }{ $ts } = "exist";
			}
		}
	}
	for $class_name ( sort keys %$old_classes ){
		next if ($class_name eq "FileTracking.class");
		if ($new_classes->{$class_name}){
			for $class_path (	sort keys %{$old_classes->{$class_name}} ){
				if ($new_classes->{$class_name}->{$class_path}){
					for $timestamp (	sort hashValueDescendingNum keys %{$old_classes->{$class_name}->{$class_path}} ){
						if 	($new_classes->{$class_name}->{$class_path}->{$timestamp} eq "exist" ){
							$new_lines{ $class_name }{ $class_path }{ $ts } = "delete";
							last;
						}
					}
				}else{
					$new_lines{ $class_name }{ $class_path }{ $ts } = "delete";
				}
			}
		}else{
			for $class_path (	sort keys %{$old_classes->{$class_name}} ){
				$new_lines{ $class_name }{ $class_path }{ $ts } = "delete";
			}
		}
	}
	return (\%new_lines);
}
sub search_class{
	my ($classes)=(@_);
	my $class_name,$class_path,$timestamp;
	if ($classes->{$searchclass}){
		print "$searchclass -->\n";
		for $class_path (	sort keys %{$classes->{$searchclass}} ){
			print "\tjar : ".(split /\.jar/,$class_path)[0].".jar\n";
			print "\tpath: ".(split /\.jar/,$class_path)[1]." -->\n";
			for $timestamp (	sort keys %{$classes->{$searchclass}->{$class_path}} ){
				print "\t\t$timestamp $classes->{$searchclass}->{$class_path}->{$timestamp}\n";
			}
		}
	}else{
		print "$searchclass was not found\n";
	}
}
sub get_filetracking_from_file{
	my ($classes)=(@_);
	my $class_name,$class_path,$timestamp;
	my $searchclass="FileTracking.class";
	if ($classes->{$searchclass}){
		print "$searchclass -->\n";
		for $class_path (	sort keys %{$classes->{$searchclass}} ){
					print "----------------------------------\n";
					print "area        : ".(split/:/,$class_path)[0]."\n";
					print "date        : ".(split/:/,$class_path)[-2]."\n";
					print "num of jars : ".(split/:/,$class_path)[-1]."\n";
					print "----------------------------------\n";
		}
	}else{
		print "FileTracking.class was not found\n";
	}
}
sub hashValueDescendingNum {
   $grades{$b} <=> $grades{$a};
}
sub create_optimize_file{
	my ($classes)=(@_[0]);
	my $optimize_file="$product_$version_optimize_file";
	my $class_name,$class_path,$timestamp;
	my $line;
	for $class_name ( sort keys %$classes ){
		if ($classes->{$class_name}){
			for $class_path (	sort keys %{$classes->{$class_name}} ){
			}
		}
	}
}
sub Usage { 
	my ($errormassege)=@_;
	print "\nName    : $scriptname v 1.0
          
Usage : 
for creating/updating a file : $scriptname [-h] -p <product> -v <version> [-cr|-up] -sdk -proj -sca
for searching a class : $scriptname -sc <classname> -p <product> -v <version>
for getting the file detail : $scriptname -fd -p <product> -v <version>

To create or update mapping file : 
-p    : product name <mandatory>
-v    : version ( pattern *** e.g 800 ) <mandatory>
-sdk  : mapping sdk area
-proj : mapping proj area 
-sca  : mapping source area
-mr   : maping rule from ccConfigFile.xml (defult are \${ORACLE_LIB} \${JAVA_HOME} \${WL_HOME} )

-cr 	: to create a new map file
-up 	: to update a map file

To search for a file
-sc : the name of the class to search at the map file <mandatory>

To get the map file history
-fd   : output the MappingFile detail\n
         your error : $errormassege\n\n"; 
         exit;
}		
