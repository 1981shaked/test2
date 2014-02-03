#!/usr/local/bin/perl 
#-d:ptkdb
use Getopt::Long;
use File::Find;
use File::stat;
use Time::localtime;
use XML::Simple;
use Data::Dumper;
use Env qw (ARCH
CCPRODTYPE
	    HOME
	    HOST);
my @errormodule=();
my $scriptname=(split /\//,$0)[-1];
my ($config,$opt_status,$variant,$help,$dname,$LogDir,$install,$dtype,$dversion,$release,$core_product,$ccprojecthome,$ccprodtype,$ccprod,$account_release,$mandatoryproduct,@errorphrase,@warnphrase)=();
my (@projbbs,@modulebbs,$mandatory,$Mandatory_Products_Result,$umb_id,$levelproj,$mapbb,$buildlevel,$entityname,$version,$bbversion,$leveldetail,$product,$buildtimestamp,$buildnumber,$checked_moudle,$lastproductbuildts,@modulelist)=();
my (%logs_location,%month_in_the_year,%modulelevel,%moduletime);
$opt_status = GetOptions( 'h'          => \$help,
													'cf:s'       => \$configfile,
													'cfl:s'      => \$configfilelocation,
                          'log:s'      => \$LogDir,
                          'mbb:s' 	   => \$mapbb,
                          'manlog:s'	 => \$manloglocation,
                          'type:s'	   => \$dtype,
                          'entity:s'	 => \$dname,
                          'v:s'	       => \$dversion,
                          'var:s'	     => \$variant,
                          'umb:s'	     => \$umb_id,
                          'html'	     => \$html,
                          'install'	   => \$install,
                          'test'       => \$test,
                          'testinit'   => \$testinit,
                          'testman'    => \$testman,
                          );
                         
&check_param;
&initialization;
&define_create_main_log_dir;
$Build_Product_Status="Finished";
&full_check;
&write_error_warning_logs;
&write_tmp_log_files;

######### basic function ####################
sub check_param {
	my @validvalues=();
	@validvalues = qw (BB,PROJECT,MODULE,PROD);
	&Usage(" You wanted help " )  if ($help);
	&Install if ($install);
	&Usage("you need to define -type -entity and -v ") if ( !defined $dtype || !defined $dname || !defined $dversion );
	$configfile=("ccConfigFile.xml") if (!defined $configfile);
	$configfilelocation=("$HOME/bin") if (!defined $configfilelocation);
	$manloglocation = ("$HOME/log/ccManProdRep.ksh") if ( !defined $manloglocation);
  &Usage (" You have to defined -type [ @validvalues ] ") if (!defined $dtype);
  &Usage (" type can be @validvalues") if (!grep /$dtype/,@validvalues);
  &Usage (" You have to defined -name [ entity name e.g lel for Prod Inf for Module etc..] ") if (!defined $dname);
  &Usage (" You have to defined -v [ entity version [ e.g. 600 ] ") if (!defined $dversion);
}
sub initialization {
	my ($tmpversion,$tmpversion1,$tmpproj,$lastlog,$product_build_log_dir,$date_string);
	my ($leveldetail,@tmpdetail,@generaldetail,)=();
    if ($dtype eq "PROD"){
     	$buildlevel="Prod";
    }elsif($dtype eq "MODULE"){
    	$buildlevel="Module";
    }elsif($dtype eq "PROJECT"){
    	$buildlevel="Proj";
    }else{
    	$buildlevel="BB";
    }
     $entityname=$dname;
     $version=$dversion;
     
     $bbversion="v".(substr($version,0,-1))."_".(substr($version,-1));    
     ############### get detail from      
     $leveldetail=(`show_str.pl -P $entityname -v $bbversion`)[0] if ($buildlevel eq "Prod");
     $leveldetail=(`show_str.pl -M $entityname -v $bbversion`)[0] if ($buildlevel eq "Module");
     $leveldetail=(`show_str.pl -p $entityname -v $bbversion`)[0] if ($buildlevel eq "Proj");
     $leveldetail=(`show_str.pl -b $entityname -v $bbversion`)[0] if ($buildlevel eq "BB");
     &Usage("show_str.pl did not work for $entityname $bbversion, probably problem with the version / product name  ") if (!$leveldetail);
     @modulebbs=`show_str.pl -M $entityname -v $bbversion | cut -d ":" -f5` if ($buildlevel eq "Module"); 
     @projbbs=`show_str.pl -p ${entityname} -v $bbversion | cut -d ":" -f5` if ($buildlevel eq "Proj");
     chomp @projbbs;
     chomp @modulebbs;
     chomp $leveldetail;
     $levelproj = (split /:/,$leveldetail)[3];
     $product=(split /:/,$leveldetail)[0];          
     print "Using deteail build level : $buildlevel, entity name :  $entityname, version : $version , product : $product, proj : $levelproj \n" if ($test);
     ############# variable from config file ############################
     &Usage ("config file $configfilelocation/$configfile does not exist") if (!-e "$configfilelocation/$configfile");
     $config = XMLin("$configfilelocation/$configfile",ForceArray => [scriptname,product,version]);
     $core_product = $config->{scriptname}{$scriptname}->{product}{$product}->{version}{$version}->{VERSIONCONFIG}->{CORE_PRODUCT};
     $ccprojecthome = $config->{scriptname}{$scriptname}->{product}{$product}->{version}{$version}->{VERSIONCONFIG}->{CCPROJECTHOME};
     $ccprodtype = $config->{scriptname}{$scriptname}->{product}{$product}->{version}{$version}->{VERSIONCONFIG}->{CCPRODTYPE};
     $ccprod = $config->{scriptname}{$scriptname}->{product}{$product}->{version}{$version}->{VERSIONCONFIG}->{CCPROD};
     $account_release = $config->{scriptname}{$scriptname}->{product}{$product}->{version}{$version}->{VERSIONCONFIG}->{ACCOUNT_RELEASE};
     $mandatory = $config->{scriptname}{$scriptname}->{product}{$product}->{version}{$version}->{VERSIONCONFIG}->{MANDATORYPRODUCT};
     @errorphrase = (split /\,/,$config->{scriptname}{$scriptname}->{product}{$product}->{version}{$version}->{VERSIONCONFIG}->{ERRORPHRASE});
     @warnphrase = (split /\,/,$config->{scriptname}{$scriptname}->{product}{$product}->{version}{$version}->{VERSIONCONFIG}->{WARNPHRASE});
     $variant=$config->{scriptname}{$scriptname}->{product}{$product}->{version}{$version}->{VERSIONCONFIG}->{VARIANT};
     $sdkhome=$config->{scriptname}{$scriptname}->{product}{$product}->{version}{$version}->{VERSIONCONFIG}->{SDKHOME};
     $sdkrelease=$config->{scriptname}{$scriptname}->{product}{$product}->{version}{$version}->{VERSIONCONFIG}->{SDKRELEASE};
     if (($test) or ($testinit)) { 
     		print "core_product : $core_product\n";
     		print "ccprojecthome : $ccprojecthome\n";
     		print "ccprodtype : $ccprodtype\n";
     		print "ccprod : $ccprod\n";
     		print "account_release : $account_release\n";
     		print "mandatory : $mandatory\n";
     		print "errorphrase : @errorphrase\n";
     		print "warnphrase : @warnphrase\n";
     		print "variant : $variant\n";
     		print "sdkhome : $sdkhome\n";
     		print "sdkrelease : $sdkrelease\n";
     		exit if $testinit;
     }
     &Usage("please check the config file, the mandatory fields are : core_product, ccprojecthome, ccprodtype, ccprod, account_release, mandatory, errorphrase, warnphrase, variant") if ((!defined $core_product) or (!defined $ccprojecthome) or (!defined $ccprodtype) or (!defined $ccprod) or (!defined $account_release) or (!defined $mandatory) or (!defined @errorphrase) or (!defined @warnphrase) or (!defined $variant));
     
     
	   #############################################################
     &define_basic_hashes;
     &Usage("the current CCPRODTYPE ( $ccprodtype )defenition is not configured in the script ( define_basic_hashes sub) please configure it ") if (!$logs_location{$ccprodtype});
     $buildnumber = &get_build_number;
     print "Build number = $buildnumber\n";
     $release=$account_release;
     print "level proj : $levelproj, variant :$variant, product : $product\n" if ($test);
     $entity_build_log_dir="$HOME/log.product/log.$entityname/log.v$version" if ($buildlevel eq "Prod");
     $entity_build_log_dir="$HOME/log.module/log.$entityname/log.v$version" if ($buildlevel eq "Module"); 
     $entity_build_log_dir="$logs_location{$ccprodtype}/log.$entityname" if ($buildlevel eq "Proj");
     $entity_build_log_dir="$logs_location{$ccprodtype}/log.$levelproj/log.$entityname" if ($buildlevel eq "BB");
     $product_build_log_dir="$HOME/log.product/log.$product/log.v$version";
   	 $entitylastlog = &get_last_log_for_build_timestamp($entity_build_log_dir,$buildlevel);
   	 $buildtimestamp=(split /\./,$entitylastlog)[-1];
   	 $productlastlog = &get_last_log_for_build_timestamp($product_build_log_dir,"Prod");
   	 $lastproductbuildts=(split /\./,$productlastlog)[-1];
   	 print "Last build timestamp for $entityname is : $buildtimestamp\n" if ($test);
   	 print "Last build timestamp for product $product is $lastproductbuildts\n" if ($test);
     if ($buildlevel eq "Prod") {
     	$checked_moudle = ("all");
     }else {
     	$checked_moudle = (split /:/,$leveldetail)[1];
     }
     @modulelist=&get_detail_from_modbo("list");
     &send_CheckProductXML_log if($html)
}
sub Usage { 
	my ($errormassege)=@_;
	
	print "\nName    : BuildStatus.pl v 1.5
          
Usage : 
CCMSS_BuildStatus.pl [-h]

mandatory : 
-type : define the build level [BB/PROJECT/MODULE/PROD]
-v : define the version ( WITHOUT the v e.g 600 )
-entity : define the build entity name ( e.g lel for prod level, cm for module level)

not mandatory : 
-cf : config file name <not mandatory default is ccConfigFile.xml> 
-cfl : config file location <not mandatory default is $HOME/bin>
-log : $scriptname logs location <not mandatory, default is $HOME/CCMSS/product/ver/var/timestamp/BuildInfo>
-umb : umb_id_number to be wrriten in the UMB CCMSS GUI 
-mbb : used for the name of the BB that is creating the par file <not mandatory, default is clfyCore>
-install : first installation of the script, checks environment variable, external command and create directories < not mandatory > 
-manlog : mandatory product script log location <not mandatory, default is $HOME/log/ccManProdRep.ksh>
-html : run \"CheckProductXML.pl -pd <product> -v <version> -vrt <variant> -ts <last build time stamp> -SM\"
-test : when using test, the script will provide extra detail ( for testing issues )

$scriptname  [-type <BB|PROJECT|MODULE|PROD> -v <version> -entity <entity name>] <-man> <-umb num> <-install> 
 e.g. : 
 $scriptname -type BB -v 980 -entity cac9nrtapi 
 $scriptname -type PROJECT -v 980 -entity ccm980V64OG
 $scriptname -type MODULE -v 980 -entity cm -man
 $scriptname -type PROD -v 970 -entity lel -umb 47 
 

         your error : $errormassege\n\n"; 
         exit;
}
sub Install {
	my @envvariable=("ARCH","HOME","HOST");
	my @commands=("show_str\.pl","ps","buildCounter","uname","grep","mkdir","ccManProdRep\.ksh");
	my @crontab=();
	&define_basic_hashes;
	my ($env,$command,$line)=();
	print "Checking environment variable needed\n";
	foreach $env (@envvariable){
		system ("echo $env");
		print "ERROR : $env need to be set\n" if ($? eq 1);
	}
	print "Checking external command needed \n";
		foreach $command (@commands){
		system ("which $command");
		print "$command was not found in the path\n" if ($? eq 1);
	}
	if (! -e "$HOME/CCMSS" ){
		print "Creating script directories\n";
		system("mkdir -p $HOME/CCMSS/log");
		system("mkdir -p $HOME/CCMSS/bin");
		print "Script directories were created successfully $HOME/CCMSS\n" if ($? eq 0 );
	}
	if ( -e "$HOME/.aliases" ) {
		open (ALIASES,">>$HOME/.aliases");
		@aliases = <ALIASES>;
		if (!grep /.*cdccmss.*/,@aliases) {
			push @aliases,"alias cdccmss 'cd ~/CCMSS/\$CCPROD/\$CCPRODVER/\$CCVARIANT; ls -lart'\n" ;
		}
		foreach $line (@aliases){
			print ALIASES "$line";
		}
		close (ALIASES);
		print "aliases file was update with cdccmss alias ( cd to ~CCMSS/\$CCPROD/\$CCPRODVER/\$CCVARIANT)\n";
	}else {
		print "ERROR : could not locate .aliases at $HOME/ to update it\n";
	}  
  print "Build logs location is $logs_location_for_installation{ $CCPRODTYPE }\n" if defined $logs_location_for_installation{ $CCPRODTYPE };
  if (!defined $logs_location_for_installation{ $CCPRODTYPE }) { 
  	 print "ERROR : please define logs location in CCMSS_BuildStatus.pl according to CCPRODTYPE mention in ccConfigFile.xml and $CCPRODTYPE ( in define_basic_hashes sub ) \n" ;
  	 print "$ccprodtype is not defined in the script, current definition are : \n"; 
  	while ( my ($key, $value) = each(%logs_location_for_installation) ) {
        print "$key => $value\n";
    }
  }
  if (! -e "$HOME/bin/ccConfigFile.xml") {
  	print "ccConfigFile.xml does not exist under $HOME/bin/ccConfigFile.xml, please place it there or define this file location when running the script\n";
  }
	exit;
}
sub define_basic_hashes {
	my (@tmpmodule,@tmpmodbomodule,@modbomodule)=();
	my ($modbo)=();
	%logs_location_for_installation = (
  'EN7'   => "$HOME/version/product/Audit/proj",
  'EN7.5' => "$HOME/vversionproduct/Audit/proj",
  'EN6'   => "$HOME",
  'CRM'   => "$HOME/vversion/product/Audit/proj",
  'CRM7'  => "$HOME/vversion/product/Audit/proj",
  'AMSS'  => "$HOME/vversion/product/Audit/proj",
	);
	%logs_location = (
  'EN7'   => "$HOME/v$version/$product/Audit/proj",
  'EN7.5' => "$HOME/v$version/$product/Audit/proj",
  'EN6'   => "$HOME",
  'CRM'   => "$HOME/v$version/$product/Audit/proj",
  'CRM7'  => "$HOME/v$version/$product/Audit/proj",
  'AMSS'  => "$HOME/v$version/$product/Audit/proj",
	);
	%month_in_the_year = (
  'Jan' => "01",
  'Feb' => "02",
  'Mar' => "03",
  'Apr' => "04",
  'May' => "05",
  'Jun' => "06",
  'Jul' => "07",
  'Aug' => "08",
  'Sep' => "09",
  'Oct' => "10",
  'Nov' => "11",
  'Dec' => "12",
	);
}
######### service function ##################
sub full_check { 
local (@need_to_check_module_list,@proj_list)=();
local ($module,$pname)=();
&initialize_general;
@need_to_check_module_list = &get_need_to_check_module_list;
print "need_to_check_module_list : @need_to_check_module_list\n" if ($test);
print "Build_Product_Status : $Build_Product_Status\n" if ($test);
&write_general_Build_Info;
&write_module_Info_log;
foreach $module (@need_to_check_module_list){
	@proj_list = &get_proj_list($module);
	foreach $pname (@proj_list){
		print " proj : $pname\n" if ($test);
		$pname .= "V${variant}" unless $pname =~ /V/;
		&initialize_proj;
		&check_all_bb_per_project($pname);
		&initialize_module;
	}
	&write_module_success_rate_report($module) if ($module eq $checked_moudle || $checked_moudle eq "all" );
	&initialize_product;
	&write_general_Build_Info;
	&write_module_Info_log;
}
&write_product_success_rate_report;
&write_general_Build_Info;
}
sub get_need_to_check_module_list{
	return @modulelist if ($buildlevel eq "Module");
	return @modulelist if ($buildlevel eq "Proj");
	return @modulelist if ($buildlevel eq "BB");
	return @modulelist if ($buildlevel eq "Topic");
	return @modulelist if ($buildlevel eq "Prod");
#	return &get_finish_module if ($buildlevel eq "Prod" );
}
sub get_finish_module{
	my (@running_modules,@finished_moudle)=();
	%moduletime=();
	my $module_end_time;
	foreach $module (@modulelist){
		undef $module_end_time;
		$module_start_time=&get_time_from_log ("$HOME/log.module/log.$module/log.v$version/build_module.log.V${variant}.$lastproductbuildts","Module","start");
		$module_end_time=&get_time_from_log ("$HOME/log.module/log.$module/log.v$version/build_module.log.V${variant}.$lastproductbuildts","Module","finish");
		chomp $module_start_time;
		chomp $module_end_time;
		last if ($module_end_time eq "still running");
		last if ($module_end_time =~ /cannot open log/);
		push @finished_moudle,$module if ( $module_end_time =~ /\d+_\d+/);
		$moduletime{$module}=["$modulelevel{$module}","$module_start_time","$module_end_time"];
	}
	return @finished_moudle;
}
sub get_detail_from_modbo{
	my @tmpmodule=();
	my @modbomodule=();
	print "using modbo file $HOME/product/$product/v$version/config/${product}_v${version}_modbo.dat\n" if ($test);
	open (MODBO, "$HOME/product/$product/v$version/config/${product}_v${version}_modbo.dat") || die "cannot locate modbo file under $HOME/$product/v$version/config/${product}_v${version}_modbo.dat";
	@tmpmodule=<MODBO>;
	chomp (@tmpmodule);
	close (MODBO);
	foreach $modbo(@tmpmodule){
			@tmpmodbomodule=split /\s+/, $modbo;
			push (@modbomodule,$tmpmodbomodule[1]);
	}
	return @modbomodule;
}
sub get_running_module_from_processes{
	my @running_modules=();
	@process_running_modules=`ps -ef | grep hbuild_module | grep $version | grep -v "grep"`;
	chomp @process_running_modules;
	return "" if (!@process_running_modules);
	foreach $tmprunning_module(@process_running_modules){
			@tmp1running_module = split /-n/,$tmprunning_module;
			@running_current_module = split /\s+/,$tmp1running_module[1];
			push (@running_modules,$running_current_module[1]);
		}
		return @running_modules;
}
sub get_hbuild_running_process { 
	my (@running_process,@hbuild_running)=();
	@hbuild_running=`ps -ef | grep hbuild_bb | grep -v "grep"|grep -v "CCMSS"` if ($buildlevel eq "BB");
	@hbuild_running=`ps -ef | grep hbuild_proj | grep $entity | grep $version |grep -v "grep"|grep -v "CCMSS"` if ($buildlevel eq "Proj");
	@hbuild_running=`ps -ef | grep hbuild_module | grep $entity |grep $version| grep -v "grep"|grep -v "CCMSS"` if ($buildlevel eq "Module");
	@hbuild_running=`ps -ef | grep hbuild_product |grep $entity | grep $version| grep -v "grep"|grep -v "CCMSS"` if ($buildlevel eq "Prod");
	return "not running" if (!@hbuild_running);
	return "running" if (@hbuild_running);
}
sub get_proj_list { 
	my ($module)=@_;
	my (@tmpprojs,@projs,$tmpproj)=();
	open (PROJS, "$ccprojecthome/module/$module/v$version/config/module_profile") || warn "cannot locate module_profile file under $ccprojecthome/module/$module/v$version/config/module_profile";
	@tmpprojs=<PROJS>;
	chomp (@tmpprojs);
	foreach $tmpproj (@tmpprojs){
		next if $tmpproj=~/PROJnames/;
		next if $tmpproj=~/Base/;
		push (@projs, ((split ' ',$tmpproj)[0])."V".$variant);
	} 
	return @projs;
}
sub define_create_main_log_dir{
	$LogDir = "$HOME/CCMSS/$product/v${version}/$variant/$buildtimestamp" if ( !defined ($LogDir));
	system ("rm -rf $LogDir") if (-e "$LogDir");
	system("mkdir -p $LogDir/BuildInfo");
	print "could not open $LogDir/BuildInfo\n" if ( $? ne 0 );
	exit if ( $? ne 0 );
	system("mkdir -p $LogDir/Reports");
	print "could not open $LogDir/Reports\n" if ( $? ne 0 );
	exit if ( $? ne 0 );
	open (MODBO, "$HOME/product/$product/v$version/config/${product}_v${version}_modbo.dat") || die "cannot locate modbo file under $HOME/$product/v$version/config/${product}_v${version}_modbo.dat";
	@tmpmodule=<MODBO>;
	close (MODBO);
	chomp (@tmpmodule);
		foreach $modbo(@tmpmodule){
			@tmpmodbomodule=split /\s+/, $modbo;
			$modulelevel{$tmpmodbomodule[1]}="$tmpmodbomodule[0]";
	}
}
sub check_all_bb_per_project {
	@proj_profile=();
	open(PROJ_PROFILE,"$ccprojecthome/proj/$pname/proj_profile" ) || die "Cant open $ccprojecthome/proj/$pname/proj_profile";
	@proj_profile=<PROJ_PROFILE>;
	chomp @proj_profile;
	close(PROJ_PROFILE);
	foreach (@proj_profile) {
		next if ( ( /BBNames/i ) || ( /SubProjects/i ) ) ;
		($bb_name,$bb_ver) = (split(/\s+/,$_))[0,1] ;
		$totalerrors =  $totalerrors + &get_error_warnings_from_logs($bb_name,$pname,"error",$module);
		$totalwarning = $totalwarning + &get_error_warnings_from_logs($bb_name,$pname,"warning",$module);
		$bb_failure_status = 0 ; 
		@dynamic_topics = () ;
		@static_topics = () ;
		&get_bb_profile ;
		@Beans_ARR = () ;
		@exe_failure = () ;
		@sl_failure = () ;
		@jars_failure = () ;
		@java_failure = () ;
		@pars_failure = ();
		@maps_failure = ();
		@objects_failure = () ;
		@objects_with_zero_size = () ;
		@GDD_errors = () ;
		@par_errors = () ;
		@DEP_errors = () ;
		@TIMEOUT_errors = () ;
		@ANT_errors = () ;
		@PERL_errors = () ;
		@sonar_failure = () ;
		@GDD_COPY2DEB_errors = () ;
		@GDD_OLDINDEB_errors = () ;
		&check_Beans ;
		if ($ccprodtype eq "EN6") {
			foreach (@Beans_ARR) {
				$proj_total_exes += 2 ;
				if (! -f "$proj_area/bin/${_}Bean.jar") {
   				$proj_total_err += 1 ;
				}
				if (! -f "$proj_area/bin/${_}BeanSec.jar" ) {
    			$proj_total_err += 1 ;
				}
				$bb_failure_status = 1 if ($proj_total_err > 0 ) ;
			}
		}
		else {
			foreach (@Beans_ARR) {
				$proj_total_exes += 4 ;
				if (! -f "$proj_area/ejb/WLS/${_}Bean.jar") {
	  			$proj_total_err += 1 ;
 				}
				if (! -f "$proj_area/ejb/WLS/${_}BeanSec.jar" ) {
  				$proj_total_err += 1 ;
 				}
				if (! -f "$proj_area/ejb/WAS/${_}Bean.jar") {
    			$proj_total_err += 1 ;
 				}
 				if (! -f "$proj_area/ejb/WAS/${_}BeanSec.jar" ) {
    			$proj_total_err += 1 ;
  			}
				$bb_failure_status = 1 if ($proj_total_err > 0 ) ;
			}
		}
		&check_according_to_main_list ;
		&check_shared_library ;
		&check_jars;
		&check_java_compilation_error;
		&check_par_creation if (defined $mapbb);
		&check_objects_compilation_error ;
		&check_sonar_failure ;
		&check_objects_with_zero_size ;
		&check_gdd_failure ;
		&check_dep_failure ;
		&check_timeout_failure;
		&check_ant_failure;
		print "working on BB name : $bb_name, proj name :$pname,  module name :$module bb_failure_status :  $bb_failure_status\n" if ($test);
		if ($bb_failure_status eq 1 ){
			push (@errormodule,$module) if (!grep/$module/,@errormodule);
			print "errormodule : @errormodule\n" if ($test);
		}
	}
}
sub get_Build_Product_End_Time {
	my ($build_log_dir,$log_file,$date_string,$endtimestamp)=();
	my (@hbuild_bb_running_process,@endtimestamp)=();
	return ("still running") if ($Build_Product_Status eq "Running");
	$build_log_dir="$logs_location{$ccprodtype}/log.$levelproj/log.$entityname" if ( $buildlevel eq "BB");
	$build_log_dir="$logs_location{$ccprodtype}/log.$entityname" if ( $buildlevel eq "Proj");
	$build_log_dir="$HOME/log.module/log.$entityname/log.v$version" if ( $buildlevel eq "Module");
	$build_log_dir="$HOME/log.product/log.$entityname/log.v$version" if ( $buildlevel eq "Prod");
	$log_file = &get_log_file_for_time;
	print "$build_log_dir/$log_file\n" if ($test);
	$date_string = ctime(stat("$build_log_dir/$log_file")->mtime);
  @endtimestamp = split /\s+/, $date_string;
  chomp  @endtimestamp;
  $endtimestamp=&get_time_stamp($endtimestamp[4],$endtimestamp[1],$endtimestamp[2],$endtimestamp[3]);
  return $endtimestamp;
}	
sub get_time_from_log {
	my ($log_name_file,$level,$type)=@_;
	my ($year,$logtime,$day,$month,$endtimestamp);
	my (@end_time_from_log)=();
	open (LOGDIR, "<$log_name_file") || return " cannot open log file at $log_name_file\n"; 
	@lines=<LOGDIR>;
	@end_time_from_log = (grep /BUILD MODULE.*FINISHED/,@lines) if (($level eq "Module") && ($type eq "finish"));
	@end_time_from_log = (grep /BUILD PRODUCT.*FINISHED/,@lines) if (($level eq "Prod") && ($type eq "finish"));
	@end_time_from_log = (grep /BUILD MODULE.*STARTED/,@lines) if (($level eq "Module") && ($type eq "start"));;
	@end_time_from_log = (grep /BUILD PRODUCT.*STARTED/,@lines) if (($level eq "Prod") && ($type eq "start"));;
	chomp @end_time_from_log;
	return ("still running") if (!defined @end_time_from_log);
  @tmpendtimestamp=split /\s+/,$end_time_from_log[-1];
    foreach $phrase (@tmpendtimestamp){
  	$year = $phrase if ($phrase =~ /^[0-9]{4}$/);
  	$logtime = $phrase if ($phrase =~ /\d\d:\d\d:\d\d/);
  	$day = $phrase if ($phrase =~ /^[0-9]{1,2}$/);
  	$month = $phrase if (defined $month_in_the_year{$phrase});
  }
  $endtimestamp=&get_time_stamp($year,$month,$day,$logtime);
  return $endtimestamp;
}
sub get_Mandatory_Products_Result {
	my ($Build_Product_End_Time)=@_;
	my @line;
	return "N/A" if ($mandatory ne "Y");
	return "Product Still running" if ($Build_Product_End_Time eq "product still running");
	print "checking ccManProdRep.ksh\n" if ($test);
	$mandatory_log_file=&get_last_log($manloglocation,"mandatory");
	return "N/A" if (! -f "$manloglocation/$mandatory_log_file");
	print "mandatory log is $manloglocation/$mandatory_log_file \n" if (($test) or ($testman));
	open (MANLOG,"<$manloglocation/$mandatory_log_file") || warn "can't find ${mandatory_log_file}" ;
	@line=<MANLOG>;
	close (MANLOG);
	return "Passed" if (grep /Build passed/,@line);
	return "Failed" if (!grep /Build passed/,@line);
}
sub get_error_warnings_from_logs {
	my ($bb,$proj,$type,$module)=@_;
	my (@lines,@errors,@warning,@modulebb,@projbb)=();
	my $logfile;
	if($buildlevel eq "BB"){
			$logfile = "hbuild.log.$lastproductbuildts" if (-e "$logs_location{$ccprodtype}/log.$proj/log.$bb/hbuild.log.$lastproductbuildts");
			$logfile = "build.$buildtimestamp" if (-e "$logs_location{$ccprodtype}/log.$proj/log.$bb/build.$buildtimestamp");
	}else{
			$logfile = "hbuild.log.$lastproductbuildts" if (-e "$logs_location{$ccprodtype}/log.$proj/log.$bb/hbuild.log.$lastproductbuildts");
			$logfile = "hbuild.log.$buildtimestamp" if (-e "$logs_location{$ccprodtype}/log.$proj/log.$bb/hbuild.log.$buildtimestamp");
	}
	open (BBLOG,"<$logs_location{$ccprodtype}/log.$proj/log.$bb/$logfile") || warn "cannot open $logs_location{$ccprodtype}/log.$proj/log.$bb/$logfile";
	@lines=<BBLOG>;
	close (BBLOG);
	foreach $error (@errorphrase){
		@errors=((grep /$error/,@lines),@errors);
	}
	foreach $warning (@warnphrase){
		@warning=((grep /$warning/,@lines),@warning);
	} 
	push @errorlog,"##################Module is : $module\tProject is : $pname\tBB is : $bb_name############################\n" if ((@errors) && ($type eq "error")) ;
	push @errorlog,@errors if ((@errors) && ($type eq "error")) ;
	push @errorlog,"############################################################################################\n\n" if ((@errors) && ($type eq "error")) ;
	push @warninglog,"##########Module is : $module\tProject is : $pname\tBB is : $bb_name########################\n" if ((@warning) && ($type eq "warning"));
	push @warninglog,@warning if ((@warning) && ($type eq "warning"));
	push @errorlog,"############################################################################################\n\n" if ((@errors) && ($type eq "error")) ;
	return scalar(@errors) if ($type eq "error");
	return scalar(@warning) if ($type eq "warning");
	
}
sub check_excluded {

	my ($exclude_file) = @_ ;

	my $pname_no_Variant ;

	open(EXCLUDE,"$excl_exe_file") || die "Can't open $excl_exe_file" ;
	chomp($excl_exe_file) ;

	($pname_no_Variant) = (split(/V/,$pname))[0] ;

	if ( grep(/${pname_no_Variant}.*\@${exclude_file}/,<EXCLUDE>) && ($exclude_file)) {
  	close(EXCLUDE) ;
		return (1) ;
	} 
	else {
  	close(EXCLUDE) ;
    return (0) ;
	}

}
sub get_build_number{
	my ($buildnumber,$tmpbuildnumber);
	$tmpbuildnumber=`buildCounter Daily $version 0 $product`;
	chomp($tmpbuildnumber);
	$tmpbuildnumber =~ /\d+/;
	$buildnumber=$&;
	return $buildnumber;
}
sub get_bb_profile {
$src_area = "$ENV{HOME}/bb/${bb_name}/${bb_ver}" ;
open(BB_PROFILE,"${src_area}/bb_profile") || warn "Cant open ${src_area}/bb_profile" ;
@bb_profile = <BB_PROFILE> ;
chomp @bb_profile;
close (BB_PROFILE);
	foreach ( @bb_profile ) {
		chomp;
  	if ( /topics = \w+/ ) {
      @topics = split(/topics = /,$_) ;
      shift(@topics) ;
      @static_topics = split(/\s+/,join(//,@topics)) ;
  } elsif ( /dynamics = \w+/ ) {
      @topics1 = split(/dynamics = /,$_) ;
      shift(@topics1) ;
      @dynamic_topics = split(/\s+/,join(//,@topics1)) ;
 		}
	}
}
sub get_log_file_for_time {
	my $logfile;
	if($buildlevel eq "BB"){
			$logfile = "hbuild.log.$lastproductbuildts" if (-e "$logs_location{$ccprodtype}/log.$levelproj/log.$entityname/hbuild.log.$lastproductbuildts");
			$logfile = "build.log.$buildtimestamp" if (-e "$logs_location{$ccprodtype}/log.$levelproj/log.$entityname/build.log.$buildtimestamp");
		}elsif($buildlevel eq "Proj"){
			$logfile = "harccbuild.log.$buildtimestamp";
		}elsif($buildlevel eq "Module"){
			$logfile = "build_module.log.V${variant}.$buildtimestamp";
		}elsif($buildlevel eq "Prod"){
			$logfile = "build_product.log.V${variant}.$buildtimestamp";
		}

		return $logfile;
}
sub get_last_log {
	my ($dir,$type) = @_;
	my @new_list = ();
	my $log_file;
	opendir(LOG_DIR,"$dir") || warn "Can't open $dir" ;
	my (@list) = readdir LOG_DIR ;
	close LOG_DIR;
	chomp @list;
	if (!defined $type || $type eq "timestamp"){
		foreach $file (@list) {
			if ($file =~/^(.*build.*\d+_\d+)$/) {
				push (@new_list, $file);
			}
		}	
	}
	if ($type eq "mandatory"){
		foreach $file (@list) {
			if ($file =~/^ccManProdRep\.${product}\.${version}.*\.rep$/) {
				push (@new_list, $file);
			}
		}	
	}
	#my @snew_list = sort (@new_list);
	($log_file) = pop(@new_list) ;
	return $log_file;
}
sub get_last_log_for_build_timestamp {
	my ($dir,$type) = @_;
	my (@new_list,@snew_list) = ();
	my $log_file;
	opendir(LOG_DIR,"$dir") || warn "Can't open $dir" ;
	my (@list) = readdir LOG_DIR ;
	close LOG_DIR;
	chomp @list;
	if ($type eq "Prod"){
		foreach $file (@list) {
			if ($file =~/^(build_product.log\.V$variant\.\d+_\d+)$/) {
				push (@new_list, $file);
			}
		}	
	}elsif ($type eq "Module"){
		foreach $file (@list) {
			if ($file =~/^(build_module.log\.V$variant\.\d+_\d+)$/) {
				push (@new_list, $file);
			}
		}
	}elsif ($type eq "Proj"){
		foreach $file (@list) {
			if ($file =~/^(harccbuild.log\.\d+_\d+)$/) {
				push (@new_list, $file);
			}
		}
	}elsif ($type eq "BB"){
		foreach $file (@list) {
			if ($file =~/^(.*build\.\d+_\d+)$/) {
				push (@new_list, $file);
			}
		}
	}
	my @snew_list = sort (@new_list);
	($log_file) = pop(@snew_list) ;
	return $log_file;
}
sub get_time_stamp{
	($year,$month,$day,$hour)=@_;
	$tsday=$day if ($day > 10 );
	$tsday="0$day" if ($day < 10 );
	@tmphour=split /:/,$hour;
	${tshour}=$tmphour[0];
	${tsminute}=$tmphour[1];
	${tssecond}=$tmphour[2];
	$endtimestamp="$year$month_in_the_year{$month}${tsday}_${tshour}$tsminute$tssecond";
	return $endtimestamp;
}
sub hashValueDescendingNum {
   $moduletime{$a}[0] <=> $moduletime{$b}[0];
}
sub calc_percentage {
local ($error_files,$total_files) = @_ ;
local $temp_percentage;
$total_files = 1 if ($total_files == 0) ;
  $temp_percentage = 100 - ($error_files/$total_files)*100 ;
  $temp_percentage = sprintf("%.1f",$temp_percentage) ;
  $temp_percentage =~ s/\.0// ;
return($temp_percentage) ;
}
sub wanted {

   if ( -f $File::Find::name ) {
      if ($_ =~ /-weblogic-ejb-jar.xml/) {
       ($base_jar_fname) = split (/-weblogic-ejb-jar.xml/,$_) ; 
        push(@Beans_ARR,$base_jar_fname) if (! grep (/$base_jar_fname$/,@Beans_ARR));

      }
   }

}
######## initialization function ###########
sub initialize_proj {


$DATA_DIR = "$HOME/product/${product}/v${version}/config" ;

$print_errors_counter = 0 ;
$excl_exe_file = "${DATA_DIR}/exclude_proj_exe_list.dat" ;
$proj_area     = "$ENV{HOME}/proj/${pname}" ;
$bin_area      = "${proj_area}/bin" ;
$lib_area      = "${proj_area}/lib" ;
$ut_area       = "${proj_area}/ut" ;

$proj_total_java = 0 ;
$proj_total_java_err = 0 ;
$proj_total_objects_err = 0 ;
$proj_total_objects = 0 ;
$proj_total_objects_zero_size = 0 ;
$proj_total_shared_libs = 0 ;
$proj_total_shared_libs_err = 0 ;
$proj_total_pars = 0 ;
$proj_total_pars_err = 0;
$proj_total_pars_maps = 0 ;
$proj_total_pars_maps_err = 0;
$proj_total_jars = 0 ;
$proj_total_jars_err = 0 ;
$proj_total_exes = 0 ;
$proj_total_err = 0 ;
$exist_map_flag = 1;

@proj_GDD_errors = () ;
@proj_par_errors = () ;
@proj_DEP_errors = () ;
@proj_TIMEOUT_errors = () ;
@proj_ANT_errors = () ;
@proj_PERL_errors = () ;
@proj_sonar_failure = () ;
@proj_GDD_COPY2DEB_errors = () ;
@proj_GDD_OLDINDEB_errors = () ;

}
sub initialize_general {
	
$ENV{ARCH} = `uname -s` ;
chomp($ENV{ARCH}) ;

if ( $ENV{ARCH} eq "HP-UX") {
   $DYNAMIC_LIB_EXT = "sl" ;
} else {
   $DYNAMIC_LIB_EXT = "so" ;
}


$ENV{HW_MODEL} = `uname -m` ;
chomp($ENV{HW_MODEL}) ;

if ( $ENV{HW_MODEL} eq "ia64") {
   $DYNAMIC_LIB_EXT = "so" ;
}
$totalerrors = 0; 
$totalwarning = 0;
@errormodule=();
}
sub initialize_product {
$product_total_java += $module_total_java ;
$product_total_java_err += $module_total_java_err ;
$product_total_objects += $module_total_objects ;
$product_total_objects_err += $module_total_objects_err ;
$product_total_shared_libs += $module_total_shared_libs ;
$product_total_shared_libs_err += $module_total_shared_libs_err ;
$product_total_jars += $module_total_jars ;
$product_total_jars_err += $module_total_jars_err ;
$product_total_exes += $module_total_exes ;
$product_total_err += $module_total_err ;
$product_total_pars += $module_total_pars ;
$product_total_pars_err += $module_total_pars_err ;
$product_par_total_maps += $module_total_pars_maps;
$product_par_total_maps_err += $proj_total_pars_maps_err;

}
sub initialize_module {
$module_total_java += $proj_total_java ;
$module_total_java_err += $proj_total_java_err ;
$module_total_objects_err += $proj_total_objects_err ;
$module_total_objects += $proj_total_objects ;
$module_total_objects_zero_size += $proj_total_objects_zero_size ;
$module_total_shared_libs += $proj_total_shared_libs ;
$module_total_shared_libs_err += $proj_total_shared_libs_err ;
$module_total_pars += $proj_total_pars ;
$module_total_pars_err += $proj_total_pars_err;
$module_total_pars_maps += $proj_total_pars_maps ;
$module_total_pars_maps_err += $proj_total_pars_maps_err;
$module_total_jars += $proj_total_jars ;
$module_total_jars_err += $proj_total_jars_err ;
$module_total_exes += $proj_total_exes ;
$module_total_err += $proj_total_err ;
$exist_map_flag = 1;

@module_GDD_errors = () ;
@module_par_errors = () ;
@module_DEP_errors = () ;
@module_TIMEOUT_errors = () ;
@module_ANT_errors = () ;
@module_PERL_errors = () ;
@module_sonar_failure = () ;
@module_GDD_COPY2DEB_errors = () ;
@module_GDD_OLDINDEB_errors = () ;
}
sub initialize_info_build{
	my ($Build_Product_End_Time,$exe_percentage,$jars_percentage,$sl_percentage,$obj_percentage,$Running_Modules,$Finished_Modules,$Gdd_Build_Result,$Gdd_Build_Result);
	$umb_id = "N/A" if (!defined $umb_id);
	$Build_Product_End_Time=&get_Build_Product_End_Time;
	if ((!defined $Mandatory_Products_Result) or ($Mandatory_Products_Result eq "Product Still running")) {
		$Mandatory_Products_Result=&get_Mandatory_Products_Result("$Build_Product_End_Time");
	}
	$exe_percentage = (100 - &calc_percentage($product_total_err,$product_total_exes)) ;
	$jars_percentage = (100 - &calc_percentage($product_total_jars_err,$product_total_jars)) ;
	$sl_percentage = (100 - &calc_percentage($product_total_shared_libs_err,$product_total_shared_libs) )  ;
	$obj_percentage = (100 - &calc_percentage($product_total_objects_err,$product_total_objects) )  ;
	@Running_Modules=&get_running_module_from_processes;
	@Finished_Modules=&get_finish_module;
	$Gdd_Build_Result="Success" if (!@gdd_bb_failes);
	$Gdd_Build_Result="failed" if (@gdd_bb_failes);
	my %info_build=("Machine"=>"$HOST",
	"Product"=>"${product}",
	"Core_Product"=>"$core_product",
	"Version"=>"v${version}",
	"Variant"=>"${variant}",
	"Release"=>"${release}",
	"Build_Number"=>"$buildnumber",
	"Build_Product_Start_Time"=>"$buildtimestamp",
	"Build_Product_End_Time"=>"$Build_Product_End_Time",
	"Build_Product_Status"=>"$Build_Product_Status",
	"Mandatory_Products_Result"=>"$Mandatory_Products_Result",
	"Exe_Failure"=>"$exe_percentage\%",
	"Jars_Failure"=>"$jars_percentage\%",
	"Shared_Libraries_Failure"=>"$sl_percentage\%",
	"Compilation_Failure"=>"$obj_percentage\%",
	"Total_Errors_Number"=>"$totalerrors",
	"Total_Warnings_Number"=>"$totalwarning",
	"Running_Modules"=>"@Running_Modules",
	"Failed_Modules"=>"@errormodule",
	"Finished_Modules"=>"@Finished_Modules",
	"Gdd_Build_Result"=>"$Gdd_Build_Result @gdd_bb_failes",
	"Duplicated_Main_Symbol_Result"=>"N/A",
	"Duplicate_Flds_Result"=>"N/A",
	"Umb_Request_Id"=>"$umb_id"
	);
	return %info_build;
}
######## write log function ################
sub write_general_Build_Info{
	%Build_Info_structure = &initialize_info_build;
	&write_Build_Info_log(\%Build_Info_structure);
}
sub write_Build_Info_log{
	if (($Build_Product_Status eq "Running") || (!-e "$LogDir/BuildInfo/Build_Info_v${version}_${product}_${variant}.txt")) {
		open(BUILDINFO, ">$LogDir/BuildInfo/Build_Info_v${version}_${product}_${variant}.txt") || die "cannot open $LogDir/BuildInfo/Build_Info_v$version_$product_$variant file\n";
	}elsif($Build_Product_Status eq "Finished"){
		open(BUILDINFO, ">$LogDir/BuildInfo/Build_Info_v${version}_${product}_${variant}.txt.tmp") || die "cannot open $LogDir/BuildInfo/Build_Info_v$version_$product_$variant file\n";
	}
	my(%Build_Info) = %{$_[0]};
	print BUILDINFO "Machine=$Build_Info{Machine}\n";
	print BUILDINFO "Product=$Build_Info{Product}\n";
	print BUILDINFO "Core_Product=$Build_Info{Core_Product}\n";
	print BUILDINFO "Version=$Build_Info{Version}\n";
	print BUILDINFO "Release=$Build_Info{Release}\n";
	print BUILDINFO "Variant=$Build_Info{Variant}\n";
	print BUILDINFO "Build_Number=$Build_Info{Build_Number}\n";
	print BUILDINFO "Build_Product_Start_Time=$Build_Info{Build_Product_Start_Time}\n";
	print BUILDINFO "Build_Product_End_Time=$Build_Info{Build_Product_End_Time}\n";
	print BUILDINFO "Build_Product_Status=$Build_Info{Build_Product_Status}\n";
	print BUILDINFO "Mandatory_Products_Result=$Build_Info{Mandatory_Products_Result}\n";
	print BUILDINFO "Exe_Failure=$Build_Info{Exe_Failure}\n";
	print BUILDINFO "Jars_Failure=$Build_Info{Jars_Failure}\n";
	print BUILDINFO "Shared_Libraries_Failure=$Build_Info{Shared_Libraries_Failure}\n";	
	print BUILDINFO "Compilation_Failure=$Build_Info{Compilation_Failure}\n";
	print BUILDINFO "Total_Errors_Number=$Build_Info{Total_Errors_Number}\n";
	print BUILDINFO "Total_Warnings_Number=$Build_Info{Total_Warnings_Number}\n";
	print BUILDINFO "Running_Modules=$Build_Info{Running_Modules}\n";
	print BUILDINFO "Failed_Modules=$Build_Info{Failed_Modules}\n";
	print BUILDINFO "Finished_Modules=$Build_Info{Finished_Modules}\n";
	print BUILDINFO "Gdd_Build_Result=$Build_Info{Gdd_Build_Result}\n";
	print BUILDINFO "Duplicated_Main_Symbol_Result=$Build_Info{Duplicated_Main_Symbol_Result}\n";
	print BUILDINFO "Duplicate_Flds_Result=$Build_Info{Duplicate_Flds_Result}\n";
	print BUILDINFO "Umb_Request_Id=$Build_Info{Umb_Request_Id}\n";
	close(BUILDINFO);
}
sub write_module_Info_log{
	open(MODULEINFO, ">$LogDir/BuildInfo/Modules_Info_v${version}_${product}_${variant}.txt") || die "cannot open $LogDir/BuildInfo/Build_Info_v$version_$product_$variant file\n";
	foreach $key (sort hashValueDescendingNum (keys(%moduletime))) {
  	print MODULEINFO "$moduletime{$key}[0]\t$key\t$moduletime{$key}[1]\t$moduletime{$key}[2]\t 00:00:00\n";
	}
	close(MODULEINFO);
}
sub write_module_success_rate_report{
	my ($module)=@_;
	my ($java_percentage,$obj_percentage,$sl_percentage,$jars_percentage,$exe_percentage,$pars_percentage,$maps_percentag,$total_module_failure,$total_module_success_rate);
	$java_percentage = &calc_percentage($module_total_java_err,$module_total_java) ;
	$obj_percentage = &calc_percentage($module_total_objects_err,$module_total_objects) ;
	$sl_percentage = &calc_percentage($module_total_shared_libs_err,$module_total_shared_libs) ;
	$jars_percentage = &calc_percentage($module_total_jars_err,$module_total_jars) ;
	$exe_percentage = &calc_percentage($module_total_err,$module_total_exes) ;
	$pars_percentage = &calc_percentage($module_total_pars_err,$module_total_pars) ;
	$maps_percentage = &calc_percentage($module_par_total_maps_err,$module_par_total_maps) ;
	$total_module_failure = 600 - ($jars_percentage + $java_percentage + $obj_percentage + $exe_percentage + $sl_percentage + $pars_percentage) if (defined $mapbb);
	$total_module_failure = 500 - ($jars_percentage + $java_percentage + $obj_percentage + $exe_percentage + $sl_percentage ) if (!defined $mapbb);
	$total_module_success_rate = &calc_percentage($total_module_failure,600) if (defined $mapbb);
	$total_module_success_rate = &calc_percentage($total_module_failure,500) if (!defined $mapbb);
	
	open(MODULEINFO, ">$LogDir/Reports/${module}_build_report.txt") || die "cannot open $LogDir/BuildInfo/Build_Info_v$version_$product_$variant file\n";
	print MODULEINFO "Total Java Files = $module_total_java \n" ; 
	print MODULEINFO "Total C/C++ Files = $module_total_objects \n" ;
	print MODULEINFO "Total Shared Libraries Files =  $module_total_shared_libs \n" ;
	print MODULEINFO "Total Jar Files =  $module_total_jars \n" ;
	print MODULEINFO "Total Executables Files =  $module_total_exes \n\n" ;
	print MODULEINFO "Total Par Files =  $module_total_pars \n\n" if (defined $mapbb);
	print MODULEINFO "Total Maps Files =  $module_par_total_maps \n\n" if (defined $mapbb); ;
	
	print MODULEINFO "Failure Java Files = $module_total_java_err\n" ;
	print MODULEINFO "Failure C/C++ Files =  $module_total_objects_err\n" ;
	print MODULEINFO "Failure Shared Libraries Files = $module_total_shared_libs_err \n" ; 
	print MODULEINFO "Failure Jar Files = $module_total_jars_err \n" ; 
	print MODULEINFO "Failure Executables Files = $module_total_err\n\n" ; 
	print MODULEINFO "Failure Par Files = $module_total_pars_err\n\n" if (defined $mapbb);;
	print MODULEINFO "Failure Maps Files = $module_par_total_err\n\n" if (defined $mapbb);;
	
	print MODULEINFO "Success Rate Java = ${java_percentage}% \n" ;
	print MODULEINFO "Success Rate C/C++ =  ${obj_percentage}% \n" ;
	print MODULEINFO "Success Rate Shared Libraries = ${sl_percentage}% \n" ;
	print MODULEINFO "Success Rate Jars =  ${jars_percentage}% \n" ; 
	print MODULEINFO "Success Rate Executables =  ${exe_percentage}% \n\n" ;
	print MODULEINFO "Success Rate Par =  ${pars_percentage}% \n\n" if (defined $mapbb);;
	print MODULEINFO "Success Rate Maps =  ${maps_percentage}% \n\n" if (defined $mapbb);;
	
	print MODULEINFO "Total Build Success Rate = ${total_module_success_rate}% \n" ;
	close(MODULEINFO);
}
sub write_product_success_rate_report{
	my ($java_percentage,$obj_percentage,$obj_percentage,$sl_percentage,$jars_percentage,$exe_percentage,$pars_percentage,$maps_percentage,$total_product_failure,$total_product_success_rate);
	$java_percentage = &calc_percentage($product_total_java_err,$product_total_java) ;
	$obj_percentage = &calc_percentage($product_total_objects_err,$product_total_objects) ;
	$sl_percentage = &calc_percentage($product_total_shared_libs_err,$product_total_shared_libs) ;
	$jars_percentage = &calc_percentage($product_total_jars_err,$product_total_jars) ;
	$exe_percentage = &calc_percentage($product_total_err,$product_total_exes) ;
	$pars_percentage = &calc_percentage($product_total_pars_err,$product_total_pars) ;
	$maps_percentage = &calc_percentage($product_par_total_maps_err,$product_par_total_maps) ;
	$total_product_failure = 600 - ($jars_percentage + $java_percentage + $obj_percentage + $exe_percentage + $sl_percentage + $pars_percentage) if (defined $mapbb);
	$total_product_failure = 500 - ($jars_percentage + $java_percentage + $obj_percentage + $exe_percentage + $sl_percentage ) if (!defined $mapbb);
	$total_product_success_rate = &calc_percentage($total_product_failure,600) if (defined $mapbb);
	$total_product_success_rate = &calc_percentage($total_product_failure,500) if (!defined $mapbb);
	
	open(PRODUCTINFO, ">$LogDir/Reports/product_success_rate_report.txt") || die ">$LogDir/Reports/product_success_rate_report.txt\n";
	print PRODUCTINFO "Total Java Files = $product_total_java \n" ; 
	print PRODUCTINFO "Total C/C++ Files = $product_total_objects \n" ;
	print PRODUCTINFO "Total Shared Libraries Files =  $product_total_shared_libs \n" ;
	print PRODUCTINFO "Total Jar Files =  $product_total_jars \n" ;
	print PRODUCTINFO "Total Executables Files =  $product_total_exes \n\n" ;
	print PRODUCTINFO "Total Par Files =  $product_total_pars \n\n" if (defined $mapbb);
	print PRODUCTINFO "Total Maps Files =  $product_par_total_maps \n\n" if (defined $mapbb); ;

	print PRODUCTINFO "Failure Java Files = $product_total_java_err\n" ;
	print PRODUCTINFO "Failure C/C++ Files =  $product_total_objects_err\n" ;
	print PRODUCTINFO "Failure Shared Libraries Files = $product_total_shared_libs_err \n" ; 
	print PRODUCTINFO "Failure Jar Files = $product_total_jars_err \n" ; 
	print PRODUCTINFO "Failure Executables Files = $product_total_err\n\n" ; 
	print PRODUCTINFO "Failure Par Files = $product_total_pars_err\n\n" if (defined $mapbb);;
	print PRODUCTINFO "Failure Maps Files = $product_par_total_err\n\n" if (defined $mapbb);;
	      
	print PRODUCTINFO "Success Rate Java = ${java_percentage}% \n" ;
	print PRODUCTINFO "Success Rate C/C++ =  ${obj_percentage}% \n" ;
	print PRODUCTINFO "Success Rate Shared Libraries = ${sl_percentage}% \n" ;
	print PRODUCTINFO "Success Rate Jars =  ${jars_percentage}% \n" ; 
	print PRODUCTINFO "Success Rate Executables =  ${exe_percentage}% \n\n" ;
	print PRODUCTINFO "Success Rate Par =  ${pars_percentage}% \n\n" if (defined $mapbb);;
	print PRODUCTINFO "Success Rate Maps =  ${maps_percentage}% \n\n" if (defined $mapbb);;
	      
	print PRODUCTINFO "Total Build Success Rate = ${total_product_success_rate}% \n" ;
	close(PRODUCTINFO);
}
sub write_error_warning_logs {
	open(ERRORINFO, ">$LogDir/Reports/build_errors.txt") || warn ">$LogDir/Reports/build_errors.txt\n";
	print ERRORINFO @errorlog;
	close(ERRORINFO);
	open(WARNINGINFO, ">$LogDir/Reports/build_warnings.txt") || warn ">$LogDir/Reports/build_warnings.txt\n";
	print WARNINGINFO @warninglog;
	close(WARNINGINFO);
}
sub write_tmp_log_files {
	system("mv -f $LogDir/BuildInfo/Build_Info_v${version}_${product}_${variant}.txt.tmp $LogDir/BuildInfo/Build_Info_v${version}_${product}_${variant}.txt");
}
sub send_CheckProductXML_log {
	if (!-e "$sdkhome/$sdkrelease/tools/build/bin/CheckProductXML.pl"){
		print "$sdkhome/$sdkrelease/tools/build/bin/CheckProductXML.pl does not exist";
		return;
	}
	system ("$sdkhome/$sdkrelease/tools/build/bin/CheckProductXML.pl -pd $product -v v${version} -vrt $variant -ts $lastproductbuildts -SM ");
}

######## check BB function ################
sub check_Beans {

$pattern = "dynamics = amdocs" ;

$amdocs_dyn_topic = grep(/$pattern/,@bb_profile) ;

if ( $amdocs_dyn_topic ) {

    chdir "${src_area}/amdocs" ;

    find(\&wanted, "${src_area}/amdocs");

}

}
sub check_according_to_main_list {

	my $pname_no_Variant;
	($pname_no_Variant) = (split(/V/,$pname))[0];
	foreach $current_topic ( @static_topics ){
		chdir "${src_area}/${current_topic}/src" ;
    if ( (-f "${src_area}/${current_topic}/src/main.list") && ( ! -z "${src_area}/${current_topic}/src/main.list" )) {
      open(MAIN_LIST,"${src_area}/${current_topic}/src/main.list") || die "Can't open ${src_area}/${current_topic}/src/main.list" ; 
      while(<MAIN_LIST>) {
				chomp ;
				if ( (! /^$/) && (! /^#/) && (! /\.sql/)) {
          ($file) = split(/\s+/,$_) ;
		      open(EXCLUDE,"$excl_exe_file") || die "Can't open $excl_exe_file" ;
     			chomp($excl_exe_file) ;
    			if ( grep(/${pname_no_Variant}.*\@${file}/,<EXCLUDE>) && ($file)) {
						next;
					}
      		close(EXCLUDE) ;
          if (/DYNAMIC_LIB_EXT/ || /DLLLIB_EXT/)  {
           ($exe_lib_file) = split (/\./,$file) ;
           $exe_lib_file .= ".${DYNAMIC_LIB_EXT}" ; 
           $bb_failure_status = 1     if (! -x "$ENV{HOME}/proj/${pname}/lib/${exe_lib_file}" && ! -x "$ENV{HOME}/proj/${pname}/ut/${exe_lib_file}");
           push(@exe_failure,$file)   if (! -x "$ENV{HOME}/proj/${pname}/lib/${exe_lib_file}" && ! -x "$ENV{HOME}/proj/${pname}/ut/${exe_lib_file}");
           $proj_total_exes += 1 ;
          }
          else {
        		($file) = split(/\$/,$file) ;
 	      		$bb_failure_status = 1     if (! -x "$ENV{HOME}/proj/${pname}/bin/${file}" && ! -x "$ENV{HOME}/proj/${pname}/ut/${file}" ) ;
  	      	push(@exe_failure,$file)   if (! -x "$ENV{HOME}/proj/${pname}/bin/${file}" && ! -x "$ENV{HOME}/proj/${pname}/ut/${file}" );
						$proj_total_exes += 1 ;
        	}
				}
      }
      close(MAIN_LIST) ;
   	}
	}
}
sub check_shared_library {

return if (( $bb_name =~ /gdd/) || ($bb_name =~ /_generated/) || ($bb_name =~ /_config/) ) ;

## The following check if there is at least one object file. ##
opendir(DEB,"$proj_area/$bb_name") || return ;
if ( ! grep(/\.o$/,(readdir(DEB))) ) {
  closedir(DEB) ;
  return ;
}
##

if ( (-f "${src_area}/make.def") || (-f "$proj_area/make.def")) {

open(BB_MAKE_DEF,"${src_area}/make.def") ;
open(PROJ_MAKE_DEF,"$proj_area/make.def") ;
open(PROJECT_SETUP,"$proj_area/.project.setup") if (-f "$proj_area/.project.setup") ; 

@BB_MAKE_DEF =<BB_MAKE_DEF> ;
@PROJ_MAKE_DEF = <PROJ_MAKE_DEF> ; 
@PROJECT_SETUP= <PROJECT_SETUP> ;

close(BB_MAKE_DEF);
close(PROJ_MAKE_DEF);
close(PROJECT_SETUP) if (-f "$proj_area/.project.setup")  ; 



 if   ((grep(/BB_LIBRARY_TYPE\s*=\s*DYNAMIC/,@BB_MAKE_DEF) && ! grep(/#\s*BB_LIBRARY_TYPE\s*=\s*DYNAMIC/,@BB_MAKE_DEF)  ||  grep(/BB_LIBRARY_TYPE\s*=\s*DYNAMIC/,@PROJ_MAKE_DEF))  && ! grep(/#\s*BB_LIBRARY_TYPE\s*=\s*DYNAMIC/,@PROJ_MAKE_DEF) && ! grep(/BB_LIBRARY_TYPE\s*=\s*ARCHIVED/,@BB_MAKE_DEF))  {

       $proj_total_shared_libs += 1 ;


   if ((! -f "$lib_area/lib${bb_name}.${DYNAMIC_LIB_EXT}") && (! -f "$lib_area/lib${bb_name}mt.${DYNAMIC_LIB_EXT}") && (! -f "$ut_area/lib${bb_name}.${DYNAMIC_LIB_EXT}") ) {

      return if (&check_excluded("lib${bb_name}") || grep(/${bb_name}_LIB_DIVIDE/,@PROJECT_SETUP)) ;

       push(@sl_failure,"$lib_area/lib${bb_name}.${DYNAMIC_LIB_EXT}") ;
       $bb_failure_status = 1 ;
       $proj_total_shared_libs += 1 ;
       $proj_total_shared_libs_err += 1 ;


   }
    
 }  # endif BB_LIBRARY_TYPE=DYNAMIC

} #endif make.def existance 


}
#sub check_jars {
#
#	return if (( $bb_name =~ /gdd/) || ($bb_name =~ /_generated/) || ($bb_name =~ /_config/) ) ;
#	return if (! -f "${src_area}/build.xml")  ;
#	open(BUILDXML,"${src_area}/build.xml");
#	@build_xml =<BUILDXML> ;
#
#	if ( grep(/antcall target="create_jars_job"/,@build_xml) ) {
#		$proj_total_jars += 1 ;
#		if ((! -f "$lib_area/${bb_name}_classes.jar") && (! -f "$ut_area/${bb_name}_classes.jar")) {
# 			if (&check_excluded("${bb_name}_classes.jar")) {	
#    		close(BUILDXML) ;
#      	return;
#      }
#
#    	push(@jars_failure,"$lib_area/${bb_name}_classes.jar") ;
#   		$bb_failure_status = 1 ;
#   		$proj_total_jars_err += 1 ;
#   	}
#	}
#	close(BUILDXML) ;
#  
# # checking jar files according to jar target in build_$bb.xml file
#    
#	return if (! -f "${src_area}/build_${bb_name}.xml")  ;
#	open(BUILDBBXML,"${src_area}/build_${bb_name}.xml");
#	@build_bb_xml = <BUILDBBXML> ;
#  
#	if ( grep(/^\s*<jar/,@build_bb_xml) ) { #if there is jar command in buid_bb.xml  	
#  	@jartarget = grep(/^\s*<jar/,@build_bb_xml); #number of spase and after <jar  	
#  	foreach $jar_command ( @jartarget ){
#  		$proj_total_jars += 1 ;  		
#   		@jar_param = split(/ /,$jar_command);  		  		
#  		@dest_jar = grep (/destfile/,@jar_param); #cut the "destfile=..." from jar command  		
#  		$jar = (split(/\//,$dest_jar[0]))[-1];  		
#  		$jar = (split(/"/,$jar))[0]; 	
#  		 			
#  		if (grep (/\.jar$/, $jar)){ #if file finished with .jar
#   			if (grep (/\$\{env\.ACCOUNT_NAME\}/, $jar)){
#
#  				$jar = (split(/\$\{env\.ACCOUNT_NAME\}/,$jar))[1];
#  				$jar = $ENV{ACCOUNT_NAME}.$jar;
#
#		  		if (! -f "$lib_area/$jar") {
#    				if (&check_excluded("$jar")) {
#   						close(BUILDXML) ;
#     					return;
#     				}
#					
#   					push(@jars_failure,"$lib_area/$jar") ;
#   					$bb_failure_status = 1 ;
#   					$proj_total_jars_err += 1 ;
#   				}   				
#  			}
# 			
#  			else{
#		  		if (! -f "$lib_area/$jar") {
#    				if (&check_excluded("$jar")) {
#   						close(BUILDXML) ;
#     					return;
#     				}
#					
#   					push(@jars_failure,"$lib_area/$jar") ;
#   					$bb_failure_status = 1 ;
#   					$proj_total_jars_err += 1 ;
#   				} 
#  			}
#  		} 		
#  	}  	 	  	
#	}
#	close(BUILDBBXML) ;
#}
sub check_jars {
	return if (( $bb_name =~ /gdd/) || ($bb_name =~ /_generated/) || ($bb_name =~ /_config/) ) ;
	return if (! -f "${src_area}/build.xml")  ;
	open(BUILDXML,"${src_area}/build.xml");
	@build_xml =<BUILDXML> ;
	if ( grep(/antcall target="create_jars_job_${bb_name}"/,@build_xml) ) {
		$proj_total_jars += 1 ;
		if ((! -f "$lib_area/${bb_name}_classes.jar") && (! -f "$ut_area/${bb_name}_classes.jar")) {
 			if (&check_excluded("${bb_name}_classes.jar")) {	
    		close(BUILDXML) ;
      	return;
      }
    	push(@jars_failure,"$lib_area/${bb_name}_classes.jar") ;
   		$bb_failure_status = 1 ;
   		$proj_total_jars_err += 1 ;
   	}
	}
	close(BUILDXML) ;
	return if (! -f "${src_area}/build_${bb_name}.xml")  ;
	open(BUILDBBXML,"${src_area}/build_${bb_name}.xml");
	@build_bb_xml = <BUILDBBXML> ;
	if ( grep(/^\s*<jar/,@build_bb_xml) ) { #if there is jar command in buid_bb.xml  	
  	@jartarget = grep(/^\s*<jar/,@build_bb_xml); #number of spase and after <jar  	
  	foreach $jar_command ( @jartarget ){
  		$proj_total_jars += 1 ;  		
   		@jar_param = split(/ /,$jar_command);  		  		
  		@dest_jar = grep (/destfile/,@jar_param); #cut the "destfile=..." from jar command  		
  		$jar = (split(/\//,$dest_jar[0]))[-1];  		
  		$jar = (split(/"/,$jar))[0]; 		
  		if (grep (/\.jar$/, $jar)){ #if file finished with .jar
		  	if (! -f "$lib_area/$jar") {
    			if (&check_excluded("$jar")) {
   					close(BUILDXML) ;
     				return;
     			}

   			push(@jars_failure,"$lib_area/$jar") ;
   			$bb_failure_status = 1 ;
   			$proj_total_jars_err += 1 ;
   			}   			
  		} 		
  	}  	 	  	
	}
	close(BUILDBBXML) ;
}
sub check_java_compilation_error {

$last = "last" ;
@errors_topics = () ;
$count = 0;

$bb_path_topic = "";

foreach $current_topic ( @dynamic_topics ) {

  next if (&check_excluded("$current_topic")) ;  
  
  $java_files_num{$current_topic} = 0 ;
  $java_files_failure_num{$current_topic} = 0 ;

  opendir (TOPIC,"$src_area/$current_topic") || die "can't open $src_area/$current_topic" ;

  foreach $java_file (readdir (TOPIC)) {

  	if ($java_file =~ /\.java$/) {

    	$java_files_num{$current_topic} += 1 ;
      $proj_total_java += 1 ;

      ($class_file) = split (/\.java/,$java_file) ;
      $class_file .= ".class" ;
      
      @manipulated_topic = `grep package ${src_area}/$current_topic/$java_file`;
      $manipulated_topic[0] =~ s/package //g;
      $manipulated_topic[0] =~ s/\;//g;
      $manipulated_topic[0] =~ tr/\./\//;
			chomp $manipulated_topic[0];			
			
			$java_topic = "$current_topic";			
      $java_topic =~ s/JavaClasses\///g;
     
      if (! -f "$proj_area/classes/$current_topic/$class_file" && ! -f "$proj_area/ut/classes/${bb_name}/$current_topic/$class_file" && ! -f "$proj_area/${bb_name}/classes/$current_topic/$class_file" && ! -f "$proj_area/${bb_name}/classes/$manipulated_topic[0]/$class_file" && ! -f "$proj_area/${bb_name}/classes/$java_topic/$class_file" && ! -f "$proj_area/classes/$java_topic/$class_file" && ! -f "$proj_area/classes/$manipulated_topic[0]/$class_file")  {
      	
      	$count += 1;
      	
      	push(@errors_topics,$current_topic) ;
        $java_files_failure_num{$current_topic} += 1 ;
        $proj_total_java_err += 1 ;

      }

     }  # endif java_file = java

   }  # end foreach $java_files 

}   # end foreach current_topic 

foreach (@errors_topics) {

 next  if ( $last eq $_ ) ;

   push(@java_failure,$_) ;
   $bb_failure_status = 1 ;

   $last = $_ ;

}

}
sub check_par_creation {
	@all_maps = () ;
	if ( $bb_name =~ m/$mapbb/ ){
		$build_log_dir="$logs_location{$ccprodtype}/log.$pname/log.$bb_name";
  	my $log_file = &get_last_log($build_log_dir,$bb_name);
   	open(LOG_FILE,"$build_log_dir/$log_file") || warn "Can't open $log_file" ;
  	
  	if ( grep/exit status=1/,<LOG_FILE> ) {  
      push (@par_errors,$bb_name) ;
     	push (@proj_par_errors,$bb_name) ;
     	$bb_failure_status = 1 ;
  	}
		
		open(BUILDXML,"${src_area}/build.xml");
		@build_xml =<BUILDXML> ;
		#@maps = `find ${src_area} -type f -entity "*.bpm" | awk \'\{print \$NF\}\'`; #maps under source area
    @maps = `find ${src_area} -type f -name "bmp_files.txt" | xargs cat '`; #for vm project 
    			   					
    foreach (@maps) {
			($map_file) = (split/\//)[-1];
			($map_class) = split (/\.bpm/,$map_file) ;
			$map_class .= ".class" ;
			push(@all_maps,$map_class) ;
			$proj_total_pars_maps += 1;
		}	
				
		#print "@all_maps \n";		
		if ( grep(/antcall target="build_par"/,@build_xml) ) {
      $exist_map_flag == 0;
			foreach $current_topic ( @dynamic_topics ) {	
			  next if (&check_excluded("$current_topic")) ;			  
			  $par_files_num{$current_topic} = 0 ;  				
 				if ( -d "$proj_area/$bb_name/classes/$current_topic"){ 					
  				opendir (TOPIC,"$proj_area/$bb_name/classes/$current_topic") || die "can't open $proj_area/$bb_name/classes/$current_topic" ;  				
  				foreach $par_file (readdir (TOPIC)) {
  					
  					#print "$proj_area/$bb_name/classes/$current_topic $par_file \n"; 
  					if ($par_file =~ /\.par$/) {  						
  						$exist_map_flag = 1;  								
    					$par_files_num{$current_topic} += 1 ;    					    	
    					$proj_total_pars += 1 ;    					
    					foreach $mapa (@all_maps) {
    						if ( ! grep ( /$mapa/,`unzip -l $proj_area/$bb_name/classes/$current_topic/$par_file | awk \'\{print \$NF\}\'`)){
    							push(@maps_failure,"$mapa") ;
    							$bb_failure_status = 1 ;
    							$proj_total_pars_maps_err += 1;			   			 		  
 				     		}				     		 				     		
							}
      			}# endif par_file = par      			
      		}      
    		} # if directory exist
 			} # foreach current topic
		} # if there is command par_file		

      				
    if ( $exist_map_flag == 0) {      				
   		@maps_failure = @all_maps ;
     	$proj_total_pars_maps_err = $proj_total_pars_maps;					
			
			if ( $proj_total_pars < 1 ) {				
				$proj_total_pars_err = 1;				
			}															
		}			
	} #if bb name is Core		
}
sub check_objects_compilation_error { 

	if (( $bb_name !~ /gdd/) && ($bb_name !~ /_generated/) && ($bb_name !~ /_config/) ) { 
		$suffixes_list = "c,cpp,ppc,pc,ppx,px,cbl" ;
  	foreach $current_topic ( @static_topics ) {
    	opendir(TOPIC,"$src_area/$current_topic/src") || warn "can't open $src_area/$current_topic/src" ;
    	foreach $file (readdir(TOPIC)) {
  	  	if ( $file =~ /\.c$/ || $file =~ /\.cpp$/ || $file =~ /\.ppc$/ || $file =~ /\.pc$/ || $file =~ /\.ppx$/ || $file =~ /\.px$/  ) { 
					($object_file) = split (/\./,$file) ;
        	$object_file .= ".o" ;
        	$proj_total_objects += 1 ;
					next if  (&check_excluded($object_file)) ; ## Don't check if the file is excluded.
					push(@objects_failure,$object_file)  if (! -f "$proj_area/$bb_name/$object_file") ;
        	$bb_failure_status = 1 if (! -f "$proj_area/$bb_name/$object_file") ;
 					$proj_total_objects_err  += 1 if (! -f "$proj_area/$bb_name/$object_file") ; 
				}
			}
			closedir(TOPIC) ; 
  	}
	}
}
sub check_sonar_failure {
	return if (! opendir(SONAR,"$proj_area/sonar_templates") ) ;
	foreach (readdir(SONAR) ) {
		chomp ;
		if ( /STBError_\w*_*$bb_name/ ) {
    	push(@sonar_failure,$bb_name)  if (! grep(/$bb_name/,@sonar_failure)) ;
    	push(@proj_sonar_failure,$bb_name) if (! grep(/$bb_name/,@proj_sonar_failure)) ;
    	$bb_failure_status = 1 ;
 		}
	}
}
sub check_objects_with_zero_size {
	$static_topics_existance = scalar(@static_topics) ;
	return if (! $static_topics_existance);
	return if (( $bb_name =~ /gdd/) || ($bb_name =~ /_generated/) || ($bb_name =~ /_config/) ) ;
	$debArea = "$proj_area/$bb_name" ;
	opendir(DEB_AREA,"$debArea") || warn "Can't open $debArea" ;
	foreach (readdir DEB_AREA) {
		if ( ( -z "$debArea/$_" ) && ( /\.o$/ ) )  {               # the file is object & has zero size.
     push(@objects_with_zero_size,$_) ; 
     $proj_total_objects_zero_size += 1 ; 
     $bb_failure_status = 1 ;
  	}
	}
}
sub check_gdd_failure {
	return if ( $bb_name !~ /gdd/ ) ;
	$build_log_dir="$logs_location{$ccprodtype}/log.$pname/log.$bb_name";
	my $log_file = &get_last_log($build_log_dir,$bb_name);
	open(LOG_FILE,"$build_log_dir/$log_file") || warn "Can't open $log_file" ;
	#($errorInd) = grep(/XGen error:/,<LOG_FILE>)   ;
	if ( grep(/XGen error:/,<LOG_FILE>) ) {  
     push (@GDD_errors,$bb_name) ;
     push (@proj_GDD_errors,$bb_name) ;
     $bb_failure_status = 1 ;
     push @gdd_bb_failes,"$bb_name\t";
 	}
close(LOG_FILE) ;
closedir(LOG_DIR) ;
### ONLY if env.$CCCORETYPE=FULL
	if ( ${CCCORETYPE} eq "FULL") {
		### Check if all files from BB are presented in DEB area
		#Get the ALL files list from BB
		undef @filelist;
		undef local @bbfilelist;
		#undef @missingfiles;
		$src_area = "$ENV{HOME}/bb/${bb_name}/${bb_ver}" ;
		&get_file_list($src_area, 0);
		#print "\nPrepare list of files under BB $src_area\n";
		foreach $curfile (@filelist) {
			if (($curfile =~ /\.xml\.|\.tql$|\.ttrql$|\.phony_idat$/) and ($curfile !~ /\.x2\./)) {
				#print "curfile = $curfile\n";
				push (@bbfilelist, $curfile);
			}
		}		
		#Get the  files list from BB, but only under .../src directory
		undef @filelist;
		undef local @bb_src_only_filelist;
		#undef @missingfiles;
		$src_area = "$ENV{HOME}/bb/${bb_name}/${bb_ver}" ;
		&get_file_list($src_area, 1);
		#print "\nPrepare list of files under BB $src_area /*/src \n";
		foreach $curfile (@filelist) {
			if (($curfile =~ /\.xml\.|\.tql$|\.ttrql$|\.phony_idat$/) and ($curfile !~ /\.x2\./)) {
				#print "curfile = $curfile\n";
				push (@bb_src_only_filelist, $curfile);
			}
		}	
		
		#Get the ALL files list from DEB area:
		undef @filelist;
		undef local @debfilelist;
		undef local $old_deb_status;
		$src_area = "${proj_area}/${bb_name}" ;
		&get_file_list($src_area, 0);
		#print "\nPrepare list of files under DEB $src_area\n";
		foreach $curfile (@filelist) {
			if (($curfile =~ /\.xml\.|\.tql$|\.ttrql$|\.phony_idat$/) and ($curfile !~ /\.x2\./)) {
				#print "curfile = $curfile\n";
				push (@debfilelist, $curfile);
			}
		}
		
		#print "bbfilelist = @bbfilelist\n\n\n\n";
		#print "debfilelist = @debfilelist\n";
		
		##Compare two arrays and found files missing in DEB
		undef local $deb_status;
		foreach $curfile (@bb_src_only_filelist) {
			local $is_found = 0;
			#print "curfile = $curfile\n";
			foreach $incurfile (@debfilelist) {
				#print "incurfile = $incurfile\n";
				if ($curfile eq $incurfile) {
					#print "incurfile = $incurfile\n";
					#print "FOUND!\n";
					$is_found = 1;
				}
			}
			if ($is_found == 0) {
				push (@GDD_COPY2DEB_errors,$curfile) ;
				$deb_status = 1
			}
		}	
		if ($deb_status) {
			push (@proj_GDD_COPY2DEB_errors,$bb_name) ;
     			$bb_failure_status = 1 ;
	     	}
		
		##Compare two arrays and found files missing in BB but still presented in DEB
		undef local $deb_status;
		foreach $curfile (@debfilelist) {
			local $is_found = 0;
			#print "curfile = $curfile\n";
			foreach $incurfile (@bbfilelist) {
				#print "incurfile = $incurfile\n";
				if ($curfile eq $incurfile) {
					#print "incurfile = $incurfile\n";
					#print "FOUND!\n";
					$is_found = 1;
				}
			}
			## ignore files bl1_xml_config.template.xml.table.preImplant 
			## and bl1_xml_config.template.xml.table.implantedFileNames.list
			if ($curfile =~ /\.preImplant$|.implantedFileNames.list$/) {
				$is_found = 1;
			}
			if ($is_found == 0) {
				#print "File $curfile not found!\n";
				push (@GDD_OLDINDEB_errors,$curfile) ;
				$deb_status = 1
			}
		}	
		if ($deb_status) {
			push (@proj_GDD_OLDINDEB_errors,$bb_name) ;
     			$bb_failure_status = 1 ;
	     	}
	}
}
sub check_dep_failure {
	$build_log_dir="$logs_location{$ccprodtype}/log.$pname/log.$bb_name";
	my $log_file = &get_last_log($build_log_dir,$bb_name);
	open(LOG_FILE,"$build_log_dir/$log_file") || warn "Can't open $log_file" ;
  if ( grep(/gmake: \*\*\* No rule to make target `.*\.h', needed by `.*o'|gmake: \*\*\* No rule to make target `.*\.h', needed by `.*dep'/,<LOG_FILE>) ) {
  	push (@DEP_errors,$bb_name) ;
    push (@proj_DEP_errors,$bb_name) ;
    $bb_failure_status = 1 ;
  }
	close(LOG_FILE) ;
	closedir(LOG_DIR) ;
}
sub check_timeout_failure {
	$build_log_dir="$logs_location{$ccprodtype}/log.$pname/log.$bb_name";
	my $log_file = &get_last_log($build_log_dir,$bb_name);
	open(LOG_FILE,"$build_log_dir/$log_file") || warn "Can't open $log_file" ;
  if ( grep(/Timeout: killed the sub-process/,<LOG_FILE>) ) {
  	push (@TIMEOUT_errors,$bb_name) ;
    push (@proj_TIMEOUT_errors,$bb_name) ;
    $bb_failure_status = 1 ;
  }
	close(LOG_FILE) ;
	closedir(LOG_DIR) ;
}
sub check_ant_failure {
	$build_log_dir="$logs_location{$ccprodtype}/log.$pname/log.$bb_name";
	my $log_file = &get_last_log($build_log_dir,$bb_name);
	open(LOG_FILE,"$build_log_dir/$log_file") || warn "Can't open $log_file" ;
	if ( grep(/BUILD FAILED/,<LOG_FILE>) ) {
  	push (@ANT_errors,$bb_name) ;
    push (@proj_ANT_errors,$bb_name) ;
    $bb_failure_status = 1 ;
  }
	close(LOG_FILE) ;
	closedir(LOG_DIR) ;
}
