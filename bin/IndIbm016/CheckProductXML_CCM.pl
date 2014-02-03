#!/usr/local/bin/perl

use File::Find;
use Getopt::Long;
use Time::Local;
use POSIX qw(strftime);


$CCMngrIncDir = "$ENV{CCMNGRHOME}/include" ;
push(@INC, $CCMngrIncDir) ;
require ("LogWrite.pl");

$CCPRODTYPE = $ENV{CCPRODTYPE} ;

&analyze_params ;

$ENV{BUILDHOME} = $ENV{CCMNGRHOME} ;


if ($CCPRODTYPE eq "") {
	print "\$CCPRODTYPE not defined\n";
  exit (1);
}
else {
  print "CCPRODTYPE is $CCPRODTYPE\n";
}

if ( ! defined($order) ) {
	$GetListCMD = "$ENV{CCMNGRHOME}/bin/GetListOfCCEnt -pd $product -v $version -p -vrt $variant |" if ($variant ne "") ;
	$GetListCMD = "$ENV{CCMNGRHOME}/bin/GetListOfCCEnt -pd $product -v $version -p |" if ($variant eq "") ;

	if (! open(PIPE, $GetListCMD)) {
   		print "\n\tError: There are no projects to work on.\n" ;
	}
	@project_list = <PIPE> ;
	chomp(@project_list) ;
	close(PIPE);
}
else {
	@project_list = &getProjectsListinOrder ;
}

#defining project list for OMS 
if ( $product =~ /oms/i){	
	$version_num = (split(/v/,$version))[1] ;
	@project_list = (c9ord.$version_num.V.$variant,ordgdd.$version_num.V.$variant,osecgdd.$version_num.V.$variant);
	print "This is a project $project_list[0] \n";
}

#defining project list for AMSS 
if ( $product =~ /amss/i){	
	$version_num = (split(/v/,$version))[1] ;
	@project_list = (c3ecrbe.$version_num.V.$variant,ecrgdd.$version_num.V.$variant);
	print "This is a project $project_list[0] \n";
}

foreach $pname (@project_list) {
	&initialize ;	
	open(EXCLUDE,"$excl_exe_file") || die "Can't open $excl_exe_file" ;
  chomp($excl_exe_file) ;
  if (! grep(/^\s*$pname\s+/,<EXCLUDE>)) {
  	print "Run for $pname \n" ;
		&run_check_for_project ;
	}
}


&initialize ;

&open_xml_files;
&check_product_statistics_results;
&get_header_info ; 
&create_header_xml ;
&create_xml_report;
&close_xml_files ;


&create_html ;
if (defined ($SendMail)) {
 &send_email ;
 &send_pmd_email;
}


#####################################################
# sub analyze_params
#####################################################
sub analyze_params {

$opt_status = GetOptions( "v=s"    => \$version,
                          "pd=s"   => \$product,
                          "ts=s"   => \$timestamp,
                          "vrt=s"  => \$variant,
                          "order:s"  => \$order,
                          "SM"   => \$SendMail 
                         );


&Usage if (! defined($version) );
&Usage if (! defined($product) );
&Usage if (! defined($timestamp) );
&Usage if (! defined($variant) );

$host = `uname -n` ;
chomp($host) ;

&create_log_files ;

}

#####################################################
# sub create_log_files
#####################################################
sub create_log_files {

	syswrite STDOUT, "timestamp is $timestamp\n";

	if ($CCPRODTYPE eq "EN6") {
		$LOGDIR = "$ENV{CCPROJECTHOME}/$version/$product/Audit/prd/$timestamp" ;
	}
	else {
		$LOGDIR = "$ENV{CCPROJECTHOME}/$version/$product/Audit/prd/$variant/$timestamp" ;
	}
	
	$FULL_LOG = "$LOGDIR/logFull.xml" ;
	$SUMM_LOG = "$LOGDIR/logSum.xml" ;
	$REP_LOG = "$LOGDIR/build_report.${timestamp}.xml" ;


	unlink ($FULL_LOG) if (-e $FULL_LOG) ;
	unlink ($SUMM_LOG) if (-e $SUMM_LOG) ;
	unlink ($REP_LOG) if (-f $REP_LOG);

	system ("/bin/touch $FULL_LOG $SUMM_LOG") ;

}

####################################################
#  sub getProjectsListinOrder
####################################################
sub getProjectsListinOrder {

	$productDir = "$ENV{CCPROJECTHOME}/product/$product/$version/config" ;
	$modboFileName = $product."_".$version."_modbo.dat" ;
	open(MODBO,"$productDir/$modboFileName") || die "Can't open $productDir/$modboFileName" ;

	@modboLines = <MODBO> ;
	chomp(@modboLines) ;
	close(MODBO) ;

	foreach (@modboLines) {
    ($module) = (split/\s/)[1] ;
    push(@moduleList,$module) ;
	}

	foreach $module (@moduleList) {
		$module_profile = "$ENV{CCPROJECTHOME}/module/$module/$version/config/module_profile" ;
		open(MOD_PROFILE,"$module_profile") || die "Can't open $module_profile" ;

    foreach (<MOD_PROFILE>) {
      next if (/PROJnames/i) ;
      next if (/Base =/i) ;
      ($project) = (split/\s/)[0] ;
			$project .= "V".$variant  if defined($variant) ;
      push(@projectList,$project) ;
     }
	close(MOD_PROFILE) ;
	}
return(@projectList) ;

}

#####################################################
# sub open_xml_files
#####################################################
sub open_xml_files {
	open(REPORT,">$REP_LOG") || die "Cant open $REP_LOG" ;
	open(FULL_LOG,"$FULL_LOG") || die "Cant open $FULL_LOG" ;
	open(SUMM_LOG,"$SUMM_LOG") || die "Cant open $SUMM_LOG" ;
}

#####################################################
# sub get_header_info
#####################################################
sub get_header_info {

	#$product_log_statistics_dir = "$ENV{CCPROJECTHOME}/$version/$product/Audit/prd/$timestamp" ;
	
	if ($CCPRODTYPE eq "EN6") {
		$product_log_statistics_dir = "$ENV{CCPROJECTHOME}/$version/$product/Audit/prd/$timestamp" ;
	}
	else {
		$product_log_statistics_dir = "$ENV{CCPROJECTHOME}/$version/$product/Audit/prd/$variant/$timestamp" ;
	}

	$product_log_statistics_file = "${product_log_statistics_dir}/stats_${product}_${version}_V${variant}.log" ;

	open(PRODUCT_LOG_STAT,$product_log_statistics_file) || die "Can't open $product_log_statistics_file" ;
	@list = <PRODUCT_LOG_STAT> ;
	close (PRODUCT_LOG_STAT) ;

	foreach (@list) {
		($build_type) = (split ( /\s+=\s+/))[1] if ( /Build Type/i) ;
		($build_counter) = (split ( /\s+=\s+/))[1] if ( /Build Number/i) ;
		($product_build_counter) = (split ( /\s+=\s+/))[1] if ( /Build PRODUCT Number/i) ;
		($build_start_time) = (split ( /\s+=\s+/))[1] if ( /Start Time/i) ;
		($build_end_time) = (split ( /\s+=\s+/))[1] if ( /End Time/i) ;
		($checkout_files) = (split ( /\s+=\s+/))[1] if ( /Checkout files/i) ;
		($deleted_files) = (split ( /\s+=\s+/))[1] if ( /Deleted files/i) ;
	}

	chomp($build_counter);
	chomp($product_build_counter);
	chomp($build_type);
	chomp($build_start_time) ;
	chomp($build_end_time) ;
	chomp($checkout_files) ;
	chomp($deleted_files) ;
	($Days, $Hours, $Minutes, $Seconds) = &diffdate($build_start_time,$build_end_time) ;
	$total_time = $Hours . "H" . ${Minutes} . "MI" ;

}

#####################################################
# sub create_header_xml
#####################################################
sub create_header_xml {

print REPORT "<?xml version='1.0'?>\n" ;
print REPORT "<?xml-stylesheet type='text/xsl' href='Breport.xsl'?>\n" ;
print REPORT "<TOTAL>\n";
print REPORT "<Products>\n" ;
print REPORT "       <Product>\n" ;
print REPORT "                <Name>$product</Name>\n" ;
print REPORT "                <Machine>$host</Machine>\n" ;
print REPORT "                <Version>$version</Version>\n" ;
print REPORT "                <Build_number>$build_counter</Build_number>\n" ;
print REPORT "                <Build_Product_number>$product_build_counter</Build_Product_number>\n" ;
print REPORT "                <Build_Type>$build_type</Build_Type>\n" ;
print REPORT "                <Build_Start_Time>$build_start_time</Build_Start_Time>\n" ;
print REPORT "                <Build_Time>$total_time</Build_Time>\n" ;
print REPORT "                <Success>$total_product_success_rate %</Success>\n" ;
print REPORT "                <Refresh_files>$checkout_files</Refresh_files>\n" ;
print REPORT "                <Deleted_files>$deleted_files</Deleted_files>\n" ;
print REPORT "       </Product>\n" ;
print REPORT "</Products>\n" ;

}

#####################################################
# sub create_xml_report
#####################################################
sub create_xml_report {

print REPORT "\n\n\n\n<Projects>\n" ;

foreach (<SUMM_LOG>) {
  print REPORT;
}

print REPORT "\n</Projects>\n" ;


print REPORT "\n<Error_Details>\n" ;

foreach (<FULL_LOG>) {
  print REPORT;
}

print REPORT "\n</Error_Details>\n" ;

&get_tasks_report ;
&get_Error_Messag_report;
&get_statistics_report ;

print REPORT "</TOTAL>\n";

}

#####################################################
# sub close_xml_files
#####################################################
sub close_xml_files {
	close(FULL_LOG) ;
	close(SUMM_LOG) ;
	close(REPORT) ;
}

#####################################################
# sub run_check_for_project 
#####################################################
sub run_check_for_project {

	&check_msg_failure ;

	open(PROJ_PROFILE,"${proj_area}/proj_profile" ) || die "Cant open ${proj_area}/proj_profile" ;

	foreach (<PROJ_PROFILE>) {

		#open(EXCLUDE,"$excl_exe_file") || die "Can't open $excl_exe_file" ;
  	#chomp($excl_exe_file) ;
  	#if ( grep(/^\s*$pname\s+/,<EXCLUDE>)) {
 	  #	print "Run for $pname \n" ;
    #  next;
		#}

		next if (( /BBNames/i ) || ( /SubProjects/i )) ;

		($bb_name,$bb_ver) = (split(/\s+/,$_))[0,1] ;
		
			$bb_failure_status = 0 ; 
			@dynamic_topics = () ;
			@static_topics = () ;
			&open_bb_profile ;
			@Beans_ARR = () ;
			@exe_failure = () ;
			@sl_failure = () ;
			@jars_failure = () ;
			@java_failure = () ;
			@pars_failure = ();
			@server_failure = ();
			@maps_failure = ();
			@objects_failure = () ;
			@objects_with_zero_size = () ;
			@GDD_errors = () ;
			@par_errors = () ;
			@server_errors = () ;
			@DEP_errors = () ;
			@TIMEOUT_errors = () ;
			@ANT_errors = () ;
			@PERL_errors = () ;
			@sonar_failure = () ;
			@GDD_COPY2DEB_errors = () ;
			@GDD_OLDINDEB_errors = () ;
			&check_Beans ;

			if ($CCPRODTYPE eq "EN6") {
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
    			#$proj_total_err += 1 ;
 				}
 				if (! -f "$proj_area/ejb/WAS/${_}BeanSec.jar" ) {
    			#$proj_total_err += 1 ;
  			}
				$bb_failure_status = 1 if ($proj_total_err > 0 ) ;
			}
			}
			
			if ( $pname =~ /c9ord/){
				
				print "$bb_name bb $bb_failure_status sts $OMS_BUILD_ERR gello\n";
				if ( $bb_name =~ /cord9deploy/ ){
					&check_oms_server_compilation;
				}
				elsif ($bb_name =~ /cord9utilities/ ){
					&oms_utilities_build;
				}
			}
			
			elsif ($pname =~ /c3ecrbe/){
				if ( $bb_name =~ /cbe3_deploy/ ){
					&find_main_list ;
					&check_shared_library ;
					&check_jars;
					&check_java_compilation_error;
					&check_par_creation;
					&check_objects_compilation_error ;
					&check_sonar_failure ;
					&check_objects_with_zero_size ;
					&check_gdd_failure ;
					&check_dep_failure ;
					&check_timeout_failure;
					&check_ant_failure;
				}	
			}
			
			else{
			&find_main_list ;
			&check_shared_library ;
			&check_jars;
			&check_java_compilation_error;
			&check_par_creation;
			&check_objects_compilation_error ;
			&check_sonar_failure ;
			&check_objects_with_zero_size ;
			&check_gdd_failure ;
			&check_dep_failure ;
			&check_timeout_failure;
			&check_ant_failure;
			#&check_perl_failure;
			}	
			close(BB_PROFILE) ;
			&print_errors ; 	
	}
	close(PROJ_PROFILE) ;
	&LogWrite ($FULL_LOG, "</Project>\n") if ($print_errors_counter) ;
	&print_summary_output;

}  ## End of sub run_check_for_project.


#####################################################
# sub initialize
#####################################################
sub initialize {

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

$DATA_DIR = "$ENV{HOME}/product/${product}/${version}/config" ;

$print_errors_counter = 0 ;
$excl_exe_file = "${DATA_DIR}/exclude_proj_exe_list.dat" ;
$proj_area     = "$ENV{HOME}/proj/${pname}" ;
$bin_area      = "${proj_area}/bin" ;
$lib_area      = "${proj_area}/lib" ;
$ut_area       = "${proj_area}/ut" ;

$product_total_java += $proj_total_java ;
$product_total_java_err += $proj_total_java_err ;
$product_total_objects += $proj_total_objects ;
$product_total_objects_err += $proj_total_objects_err ;
$product_total_shared_libs += $proj_total_shared_libs ;
$product_total_shared_libs_err += $proj_total_shared_libs_err ;
$product_total_jars += $proj_total_jars ;
$product_total_jars_err += $proj_total_jars_err ;
$product_total_exes += $proj_total_exes ;
$product_total_err += $proj_total_err ;
$product_total_pars += $proj_total_pars ;
$product_total_server += $proj_total_server ;
$product_total_server_err += $proj_total_server_err ;
$product_total_pars_err += $proj_total_pars_err ;
$product_par_total_maps += $proj_total_pars_maps;
$product_par_total_maps_err += $proj_total_pars_maps_err;

$proj_total_java = 0 ;
$proj_total_java_err = 0 ;
$proj_total_objects_err = 0 ;
$proj_total_objects = 0 ;
$proj_total_objects_zero_size = 0 ;
$proj_total_shared_libs = 0 ;
$proj_total_shared_libs_err = 0 ;
$proj_total_pars = 0 ;
$proj_total_pars_err = 0;
$proj_total_server = 0 ;
$proj_total_server_err = 0;
$proj_total_pars_maps = 0 ;
$proj_total_pars_maps_err = 0;
$proj_total_jars = 0 ;
$proj_total_jars_err = 0 ;
$proj_total_exes = 0 ;
$proj_total_err = 0 ;
$exist_map_flag = 1;

@proj_GDD_errors = () ;
@proj_par_errors = () ;
@proj_server_errors = () ;
@proj_DEP_errors = () ;
@proj_TIMEOUT_errors = () ;
@proj_ANT_errors = () ;
@proj_PERL_errors = () ;
@proj_sonar_failure = () ;
@proj_GDD_COPY2DEB_errors = () ;
@proj_GDD_OLDINDEB_errors = () ;

$OMS_BUILD_ERROR = "";

}

#####################################################
## sub open_bb_profile
#####################################################

sub open_bb_profile {

$src_area = "$ENV{HOME}/bb/${bb_name}/${bb_ver}" ;

open(BB_PROFILE,"${src_area}/bb_profile") || warn "Cant open ${src_area}/bb_profile" ;

@bb_profile = <BB_PROFILE> ;

foreach ( @bb_profile ) {
chomp;
  if ( /topics = \w+/ ) {
       @topics = split(/topics = /,$_) ;
       shift(@topics) ;     # remove the first space from @topics
       @static_topics = split(/\s+/,join(//,@topics)) ;
  } elsif ( /dynamics = \w+/ ) {
       @topics1 = split(/dynamics = /,$_) ;
       shift(@topics1) ;     # remove the first space from @topics1
       @dynamic_topics = split(/\s+/,join(//,@topics1)) ;
 }

}

}

#####################################################
## sub find_main.list
#####################################################

sub find_main_list {

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

#########################################
## sub check_Beans
#########################################

sub check_Beans {

$pattern = "dynamics = amdocs" ;

$amdocs_dyn_topic = grep(/$pattern/,@bb_profile) ;

if ( $amdocs_dyn_topic ) {

    chdir "${src_area}/amdocs" ;

    find(\&wanted, "${src_area}/amdocs");

}

}

#########################################################
# sub wanted
#########################################################

sub wanted {

   if ( -f $File::Find::name ) {
      if ($_ =~ /-weblogic-ejb-jar.xml/) {
       ($base_jar_fname) = split (/-weblogic-ejb-jar.xml/,$_) ; 
        push(@Beans_ARR,$base_jar_fname) if (! grep (/$base_jar_fname$/,@Beans_ARR));

      }
   }

}

#########################################################
# sub check_shared_library 
#########################################################

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

#########################################################
# check_objects_compilation_error
#########################################################

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

#########################################################
# sub check_jars
#########################################################

sub check_jars {

	return if (( $bb_name =~ /gdd/) || ($bb_name =~ /_generated/) || ($bb_name =~ /_config/) ) ;
	return if (! -f "${src_area}/build.xml")  ;
	open(BUILDXML,"${src_area}/build.xml");
	@build_xml =<BUILDXML> ;

	if ( grep(/antcall target="create_jars_job"/,@build_xml) ) {
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
  
 # checking jar files according to jar target in build_$bb.xml file
    
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
   			if (grep (/\$\{env\.ACCOUNT_NAME\}/, $jar)){

  				$jar = (split(/\$\{env\.ACCOUNT_NAME\}/,$jar))[1];
  				$jar = $ENV{ACCOUNT_NAME}.$jar;

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
 			
  			else{
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
	}
	close(BUILDBBXML) ;
}

####################################################
# check_par_creation & maps in this par
####################################################

sub check_par_creation {
	
	@all_maps = () ;
	if ( $bb_name =~ m/clfyCore/ ){
		
		if ($CCPRODTYPE eq "EN6") {
			$build_log_dir = "$ENV{HOME}/log.$pname/log.$bb_name" ;
		}
		else {
			$build_log_dir = "$ENV{HOME}/$version/$product/Audit/proj/log.$pname/log.$bb_name" ;
		}
				
  	my $log_file = &get_last_log($build_log_dir);
   	open(LOG_FILE,"$build_log_dir/$log_file") || warn "Can't open $log_file" ;
  	
  	if ( grep/exit status=1/,<LOG_FILE> ) {  
      push (@par_errors,$bb_name) ;
     	push (@proj_par_errors,$bb_name) ;
     	$bb_failure_status = 1 ;
  	}
		
		open(BUILDXML,"${src_area}/build.xml");
		@build_xml =<BUILDXML> ;
		#@maps = `find ${src_area} -type f -name "*.bpm" | awk \'\{print \$NF\}\'`; #maps under source area
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
		close(LOG_FILE) ;
	
	} #if bb name is Core		
}

####################################################
# check_oms_server_compilation;
####################################################

sub check_oms_server_compilation {
	
	if ( $bb_name =~ m/cord9deploy/ ){

		$proj_total_server = 1;
		
		if ($CCPRODTYPE eq "EN6") {
			$build_log_dir = "$ENV{HOME}/log.$pname/log.$bb_name" ;
		}
		else {
			$build_log_dir = "$ENV{HOME}/$version/$product/Audit/proj/log.$pname/log.$bb_name" ;
		}
				
		my $log_file = "hbuild.log.$timestamp";
		open(LOG_FILE,"$build_log_dir/$log_file") || warn "Can't open $log_file" ;

		if ( grep/exit status=1/,<LOG_FILE> ){ 
			push (@server_errors,$bb_name) ;
			push (@proj_server_errors,$bb_name) ;
			$bb_failure_status = 1 ;
			$proj_total_server_err = 1;
			if ($OMS_BUILD_ERR eq ""){
				$OMS_BUILD_ERR = 	"Gide failure";
			}
			else{
				$OMS_BUILD_ERR = 	$OMS_BUILD_ERR."  "."and Gide failure";
			}
  	}	
  	close(LOG_FILE) ;

 		open(LOG_FILE,"$build_log_dir/$log_file") || warn "Can't open $log_file" ; 	
  	if (grep/ERROR: GIDE/,<LOG_FILE>) {
  		push (@server_errors,$bb_name) ;
			push (@proj_server_errors,$bb_name) ;
			$bb_failure_status = 1 ;
			$proj_total_server_err = 1;
			
			if ($OMS_BUILD_ERR eq ""){
				$OMS_BUILD_ERR = 	"Gide failure";
			}
			else{
				$OMS_BUILD_ERR = 	$OMS_BUILD_ERR."  "."and Gide failure";
			}
  	}  	
  	close(LOG_FILE) ;
 
	} #if bb name is cord9deploy
}

####################################################
# check oms build
####################################################

sub oms_utilities_build{
	
	if ( $bb_name =~ m/cord9utilities/ ){
		
		$proj_total_server = 1;
		
		if ($CCPRODTYPE eq "EN6") {
			$build_log_dir = "$ENV{HOME}/log.$pname/log.$bb_name" ;
		}
		else {
			$build_log_dir = "$ENV{HOME}/$version/$product/Audit/proj/log.$pname/log.$bb_name" ;
		}
				
		my $log_file = "hbuild.log.$timestamp";
		open(LOG_FILE,"$build_log_dir/$log_file") || warn "Can't open $log_file" ;

		if ( grep/BUILD FAILED/,<LOG_FILE> ){ 
			push (@server_errors,$bb_name) ;
			push (@proj_server_errors,$bb_name) ;
			$bb_failure_status = 1 ;
			$proj_total_server_err = 1;

  		if ($OMS_BUILD_ERR eq ""){
				$OMS_BUILD_ERR = 	"BUILD failure";
			}
			else{
				$OMS_BUILD_ERR = 	$OMS_BUILD_ERR."  "."and BUILD failure";
			}		
  	}	
  	close(LOG_FILE) ;
  
	} #if bb name is cord9utilities
	
}



####################################################
# check_java_compilation_error
####################################################

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



####################################################
# sub check_sonar_failure
####################################################

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


####################################################
# sub check_msg_failure
####################################################

sub check_msg_failure {
return if (! opendir(MSG,"$proj_area/docs") ) ;

foreach (readdir(MSG) ) {
chomp ;

 if ( /_message_diff_report.html$/ ) {

     $msgPattern = "No differences were found" ;

     open(MSGFILE,"$proj_area/docs/$_") ;
     @msgFile = <MSGFILE> ;
     close(MSGFILE) ;

     if (! grep(/$msgPattern/,@msgFile)) { 
	    push(@proj_msg_failure,$pname) if (! grep(/$pname/,@proj_msg_failure)) ;
    }

 }

}


}


#########################################
## sub check_objects_with_zero_size
#########################################

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

#########################################
## sub get_last_log
#########################################

sub get_last_log {
	my ($dir) = @_;
	
	my @new_list = ();
	my %man_bbs = {};
	my $log_file;
	
	opendir(LOG_DIR,"$dir") || warn "Can't open $dir" ;

	my (@list) = readdir LOG_DIR ;
	close LOG_DIR;
	
	chomp @list;
	foreach $l (@list) {
		#check wehther the log has a suffix after the timestamp (like _man)
		if ($l =~/^(hbuild.log.*\d+_\d+)_(\w+)$/) {
			$man_bbs{$1} = $l;
			push (@new_list, $1);	
		}else {
			push (@new_list, $l);	
		}
	}
	
	#get the newest log and get back the suffix if needed
	my @snew_list = sort (@new_list);
	($log_file) = pop(@snew_list) ;
	
	if ($man_bbs{$log_file}) {
		$log_file = $man_bbs{$log_file}	
	}
	
	return $log_file;
	
}
#########################################
## sub check_gdd_failure
#########################################

sub check_gdd_failure {

return if ( $bb_name !~ /gdd/ ) ;

	if ($CCPRODTYPE eq "EN6") {
		$build_log_dir = "$ENV{HOME}/log.$pname/log.$bb_name" ;
	}
	else {
		$build_log_dir = "$ENV{HOME}/$version/$product/Audit/proj/log.$pname/log.$bb_name" ;
	}

#$build_log_dir = "$ENV{HOME}/log.$pname/log.$bb_name" ;

my $log_file = &get_last_log($build_log_dir);


open(LOG_FILE,"$build_log_dir/$log_file") || warn "Can't open $log_file" ;

#($errorInd) = grep(/XGen error:/,<LOG_FILE>)   ;

  if ( grep(/XGen error:/,<LOG_FILE>) ) {  
     push (@GDD_errors,$bb_name) ;
     push (@proj_GDD_errors,$bb_name) ;
     $bb_failure_status = 1 ;
  }

close(LOG_FILE) ;
closedir(LOG_DIR) ;

	### ONLY if env.$CCCORETYPE=FULL

	if ( $ENV{CCCORETYPE} eq "FULL") {
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

#########################################
## sub check_dep_failure
#########################################

sub check_dep_failure {

#$build_log_dir = "$ENV{HOME}/log.$pname/log.$bb_name" ;

	if ($CCPRODTYPE eq "EN6") {
		$build_log_dir = "$ENV{HOME}/log.$pname/log.$bb_name" ;
	}
	else {
		$build_log_dir = "$ENV{HOME}/$version/$product/Audit/proj/log.$pname/log.$bb_name" ;
	}

my $log_file = &get_last_log($build_log_dir);

open(LOG_FILE,"$build_log_dir/$log_file") || warn "Can't open $log_file" ;

  if ( grep(/gmake: \*\*\* No rule to make target `.*\.h', needed by `.*o'|gmake: \*\*\* No rule to make target `.*\.h', needed by `.*dep'/,<LOG_FILE>) ) {

     push (@DEP_errors,$bb_name) ;
     push (@proj_DEP_errors,$bb_name) ;
     $bb_failure_status = 1 ;
  }

close(LOG_FILE) ;
closedir(LOG_DIR) ;
}

#########################################
## sub check_timeout_failure
#########################################

sub check_timeout_failure {

#$build_log_dir = "$ENV{HOME}/log.$pname/log.$bb_name" ;

	if ($CCPRODTYPE eq "EN6") {
		$build_log_dir = "$ENV{HOME}/log.$pname/log.$bb_name" ;
	}
	else {
		$build_log_dir = "$ENV{HOME}/$version/$product/Audit/proj/log.$pname/log.$bb_name" ;
	}

opendir(LOG_DIR,"$build_log_dir") || warn "Can't open $build_log_dir" ;

(@list) = sort(readdir LOG_DIR) ;
(@list) = grep(/^hbuild.log.*\d+_\d+$/,@list) ;
($log_file) = pop(@list) ;

open(LOG_FILE,"$build_log_dir/$log_file") || warn "Can't open $log_file" ;

  if ( grep(/Timeout: killed the sub-process/,<LOG_FILE>) ) {
     push (@TIMEOUT_errors,$bb_name) ;
     push (@proj_TIMEOUT_errors,$bb_name) ;
     $bb_failure_status = 1 ;
  }

close(LOG_FILE) ;
closedir(LOG_DIR) ;
}

#########################################
## sub check_ant_failure
#########################################

sub check_ant_failure {

#$build_log_dir = "$ENV{HOME}/log.$pname/log.$bb_name" ;

	if ($CCPRODTYPE eq "EN6") {
		$build_log_dir = "$ENV{HOME}/log.$pname/log.$bb_name" ;
	}
	else {
		$build_log_dir = "$ENV{HOME}/$version/$product/Audit/proj/log.$pname/log.$bb_name" ;
	}

my $log_file = &get_last_log($build_log_dir);

open(LOG_FILE,"$build_log_dir/$log_file") || warn "Can't open $log_file" ;

  if ( grep(/BUILD FAILED/,<LOG_FILE>) ) {
     push (@ANT_errors,$bb_name) ;
     push (@proj_ANT_errors,$bb_name) ;
     $bb_failure_status = 1 ;
  }

close(LOG_FILE) ;
closedir(LOG_DIR) ;
}

#########################################
## sub check_perl_failure
#########################################

sub check_perl_failure {

#$build_log_dir = "$ENV{HOME}/$version/$product/Audit/proj/log.$pname/log.$bb_name" ;
	
	if ($CCPRODTYPE eq "EN6") {
		$build_log_dir = "$ENV{HOME}/log.$pname/log.$bb_name" ;
	}
	else {
		$build_log_dir = "$ENV{HOME}/$version/$product/Audit/proj/log.$pname/log.$bb_name" ;
	}

	my $log_file = &get_last_log($build_log_dir);

	open(LOG_FILE,"$build_log_dir/$log_file") || warn "Can't open $log_file" ;

  if ( grep(/ERROR/,<LOG_FILE>) ) {
     push (@PERL_errors,$bb_name) ;
     push (@proj_PERL_errors,$bb_name) ;
     $bb_failure_status = 1 ;
  }

close(LOG_FILE) ;
closedir(LOG_DIR) ;
}

####################################################
# sub check_excluded
####################################################

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


####################################################
# sub print_errors 
####################################################

sub print_errors {

	if ( $bb_failure_status == 1 && (! $print_errors_counter) ) {
		&LogWrite ($FULL_LOG, "<Project title='$pname'>") ;
		$print_errors_counter = 1 ;
	}

	### <a href="#top">Back to top</a>

	if ( $bb_failure_status == 1) {
		&LogWrite ($FULL_LOG,   "<bb name='$bb_name. The log file: $build_log_dir/$log_file'>") ;
	}

	$total_beans_failrue = 0 ;

	if ($CCPRODTYPE eq "EN6") {
		foreach (@Beans_ARR) {
			if (! -f "$proj_area/bin/${_}Bean.jar") {
			LogWrite ($FULL_LOG,  "	<error name='ERROR: $pname - $bb_name : - ${_}Bean.jar'> </error>") ;
			$total_beans_failrue += 1 ;
   		}

 			if (! -f "$proj_area/bin/${_}BeanSec.jar") {
				LogWrite ($FULL_LOG,  "      <error name='ERROR: $pname - $bb_name : - ${_}BeanSec.jar'> </error>") ;
				$total_beans_failrue += 1 ;
   		}
		}
	}
	else {
		foreach (@Beans_ARR) {
			if (! -f "$proj_area/ejb/WLS/${_}Bean.jar") {
				LogWrite ($FULL_LOG,  "	<error name='ERROR: $pname - $bb_name : - WLS/${_}Bean.jar'> </error>") ;
  	 		$total_beans_failrue += 1 ;
	  	}
  
			if (! -f "$proj_area/ejb/WLS/${_}BeanSec.jar") {
				LogWrite ($FULL_LOG,  "      <error name='ERROR: $pname - $bb_name : - WLS/${_}BeanSec.jar'> </error>") ;
				$total_beans_failrue += 1 ;
  		}

			if (! -f "$proj_area/ejb/WAS/${_}Bean.jar") {
			#	LogWrite ($FULL_LOG,  "      <error name='ERROR: $pname - $bb_name : - WAS/${_}Bean.jar'> </error>") ;
			#	$total_beans_failrue += 1 ;
			}

			if (! -f "$proj_area/ejb/WAS/${_}BeanSec.jar") {
			#	LogWrite ($FULL_LOG,  "      <error name='ERROR: $pname - $bb_name : - WAS/${_}BeanSec.jar'> </error>") ;
			#	$total_beans_failrue += 1 ;
			}
		}
	}
	
	LogWrite ($FULL_LOG,"\n	<error name='$total_beans_failrue Beans executable(s) failed in the build.'> </error>\n") if ($total_beans_failrue) ; 

	foreach (@sl_failure) {
 		LogWrite ($FULL_LOG,"\n	<error name='The build of the shared library $_  FAILED !'> </error>\n") ;
	}

	foreach (@jars_failure) {
 		LogWrite ($FULL_LOG,"\n        <error name='The build of the jar $_  FAILED !'> </error>\n") ;
	}

	foreach (@exe_failure) {
  	LogWrite ($FULL_LOG,"	<error name='The build of $_ is FAILED !'>  </error>") ; 
		$proj_total_err += 1 ;
	}

	foreach (@maps_failure) {
 		LogWrite ($FULL_LOG,"\n        <error name='The $_ is missing in par file FAILED !'> </error>\n") ;
	}

	$length = @exe_failure ;
	LogWrite ($FULL_LOG,"	<error name='$length executable(s) failed in the build.'> </error>\n") if (@exe_failure) ; 

	foreach (@java_failure) {
 		LogWrite ($FULL_LOG,"	<error name='ERROR: $java_files_failure_num{$_} java file(s) failed in topic $_ ($java_files_failure_num{$_}/$java_files_num{$_})'> </error> ") ;
	}

	foreach (@objects_failure) {
 		LogWrite ($FULL_LOG,"	<error name='ERROR: object file $_ failed in compilation.'> </error> ") ;
	}

	$length = @objects_failure ;
	LogWrite ($FULL_LOG,"\n	<error name='$length object(s) FAILED in the build.'> </error>\n") if (@objects_failure) ;

	foreach (@objects_with_zero_size) {
 		LogWrite ($FULL_LOG,"	<error name='ERROR: object file $_ has zero size.'> </error> ") ;
	}

	foreach (@GDD_errors) {
 		LogWrite ($FULL_LOG,"	<error name='ERROR: XGen problems with $_ .'> </error> ") ;
	}

	foreach (@par_errors) {
 		LogWrite ($FULL_LOG,"	<error name='ERROR: Gide compilation error in $_ .'> </error> ") ;
	}

	foreach (@server_errors) {
 		LogWrite ($FULL_LOG,"	<error name='ERROR: Compilation error in $_ .'> </error> ") ;
	}
	
	foreach (@DEP_errors) {
 		LogWrite ($FULL_LOG,"  <error name='ERROR: DEP problems with $_ .'> </error> ") ;
	}

	foreach (@TIMEOUT_errors) {
 		LogWrite ($FULL_LOG,"  <error name='ERROR: TIMEOUT problems with $_ .'> </error> ") ;
	}

	foreach (@ANT_errors) {
 		LogWrite ($FULL_LOG,"  <error name='ERROR: ANT problems with $_ .'> </error> ") ;
	}

	foreach (@PERL_errors) {
 		LogWrite ($FULL_LOG,"  <error name='ERROR: PERL problems with $_ .'> </error> ") ;
	}

	foreach (@sonar_failure) {
  	LogWrite ($FULL_LOG,"	<error name='Error while generating sonarTemplate for $bb_name'> </error> ") ;
	}

	foreach (@GDD_COPY2DEB_errors) {
 		LogWrite ($FULL_LOG,"	<error name='ERROR: Missing in DEB area of $bb_name : $_ .'> </error> ") ;
	}

	foreach (@GDD_OLDINDEB_errors) {
 		LogWrite ($FULL_LOG,"	<error name='ERROR: Unnecessary in DEB area: $_ .'> </error> ") ;
	}

	&LogWrite ($FULL_LOG,   "</bb>") if ( $bb_failure_status == 1);

}

####################################################
# sub print_summary_output 
####################################################

sub print_summary_output {

if ($proj_total_err > 0) {

  $percentage = ($proj_total_err/$proj_total_exes)*100 ;
  $percentage += 1 if ($percentage < 1) ;
  $percentage = sprintf("%d",$percentage) ;

  &print_with_xml_format($pname,"executables failure","$proj_total_err/$proj_total_exes","(${percentage}% failure)") ;
}

if ($proj_total_java_err > 0) {

  $percentage = ($proj_total_java_err/$proj_total_java)*100 ;
  $percentage += 1 if ($percentage < 1) ;
  $percentage = sprintf("%d",$percentage) ;

  &print_with_xml_format($pname,"java failure","$proj_total_java_err/$proj_total_java","(${percentage}% failure)") ;
}

if (($proj_total_pars_err > 0) && ($proj_total_pars > 0)) {

  $percentage = ($proj_total_pars_err/$proj_total_pars)*100 ;
  $percentage += 1 if ($percentage < 1) ;
  $percentage = sprintf("%d",$percentage) ;
  &print_with_xml_format($pname,"par failure","$proj_total_pars_err/$proj_total_pars","(${percentage}% failure)") ;
}


if (($proj_total_server_err > 0) && ($proj_total_server > 0)) {

  $percentage = ($proj_total_server_err/$proj_total_server)*100 ;
  $percentage += 1 if ($percentage < 1) ;
  $percentage = sprintf("%d",$percentage) ;

  #&print_with_xml_format($pname,"server failure","$proj_total_server_err/$proj_total_server","(${percentage}% failure)") ;
}

if (($proj_total_pars_maps_err > 0) && ($proj_total_pars_maps > 0)) {

	$percentage = ($proj_total_pars_maps_err/$proj_total_pars_maps)*100 ;
  $percentage += 1 if ($percentage < 1) ;
  $percentage = sprintf("%d",$percentage) ;

  &print_with_xml_format($pname,"BPM failure","$proj_total_pars_maps_err/$proj_total_pars_maps","(${percentage}% failure)") ;
}

if ($proj_total_objects_err > 0) {

  $percentage = ($proj_total_objects_err/$proj_total_objects)*100 ;
  $percentage += 1 if ($percentage < 1) ;
  $percentage = sprintf("%d",$percentage) ;

  &print_with_xml_format($pname,"C/C++  objects failure","$proj_total_objects_err/$proj_total_objects","(${percentage}% failure)") ;
}


if ($proj_total_shared_libs_err > 0) {
  $percentage = ($proj_total_shared_libs_err/$proj_total_shared_libs)*100 ;
  $percentage += 1 if ($percentage < 1) ;
  $percentage = sprintf("%d",$percentage) ;

  &print_with_xml_format($pname,"shared libraries failure","$proj_total_shared_libs_err/$proj_total_shared_libs","(${percentage}% failure)") ;
}

if ($proj_total_jars_err > 0) {
  $percentage = ($proj_total_jars_err/$proj_total_jars)*100 ;
  $percentage += 1 if ($percentage < 1) ;
  $percentage = sprintf("%d",$percentage) ;

  &print_with_xml_format($pname,"jars failure","$proj_total_jars_err/$proj_total_jars","(${percentage}% failure)") ;
}

if ($proj_total_objects_zero_size > 0 ) {

  $percentage = ($proj_total_objects_zero_size/$proj_total_objects)*100 if ($proj_total_objects>0) ;
  $percentage += 1 if ($percentage < 1) ;
  $percentage = sprintf("%d",$percentage) ;

  &print_with_xml_format($pname,"Zero sized objects","$proj_total_objects_zero_size/$proj_total_objects","(${percentage}% failure)") ;
}

foreach (@proj_GDD_errors) {
  &print_with_xml_format($pname,"GDD failure","XGen problems","($_)") ;
}

foreach (@proj_par_errors) {
  &print_with_xml_format($pname,"Gide failure","Gide problems","($_)") ;
}

foreach (@proj_server_errors) {
  &print_with_xml_format($pname,"OMS build failure",$OMS_BUILD_ERR,"($_)") ;
}

foreach (@proj_DEP_errors) {
  &print_with_xml_format($pname,"DEP failure","DEP problems","($_)") ;
}

foreach (@proj_TIMEOUT_errors) {
  &print_with_xml_format($pname,"TIMEOUT failure","timeout","($_)") ;
}

foreach (@proj_ANT_errors) {
  &print_with_xml_format($pname,"ANT failure","problems with ant","($_)") ;
}

foreach (@proj_PERL_errors) {
  &print_with_xml_format($pname,"PERL failure","problems with perl","($_)") ;
}

foreach (@proj_sonar_failure) {
  &print_with_xml_format($pname,"Sonar template failure","1/1","($_)") ;
}

foreach (@proj_GDD_COPY2DEB_errors) {
  &print_with_xml_format($pname,"GDD failure","Missing files in DEB area ","($_)") ;
}

foreach (@proj_GDD_OLDINDEB_errors) {
  &print_with_xml_format($pname,"GDD failure","Unnecessary files in DEB area ","($_)") ;
}

}


####################################################
# sub print_with_xml_format
####################################################

sub print_with_xml_format {

my($str1,$str2,$str3,$str4) = @_ ;

LogWrite ($SUMM_LOG , "        <Project> ") ;
LogWrite ($SUMM_LOG ,  "                <Name>$str1</Name> ") ;
LogWrite ($SUMM_LOG ,  "                <Failure type='Type'>$str2</Failure> ") ;
LogWrite ($SUMM_LOG ,  "                <Failure type='amount'>$str3</Failure> ") ;
LogWrite ($SUMM_LOG ,  "                <Failure type='rate'>$str4</Failure> ") ;
LogWrite ($SUMM_LOG ,  "        </Project> ") ;

}

####################################################
# sub print_with_txt_format
####################################################

sub print_with_txt_format {

my($str1,$str2,$str3,$str4) = @_ ;

  printf ("%-20s",$str1) ;
  printf ("%-30s",$str2) ;
  printf ("%-20s",$str3) ;
  printf ("%-20s",$str4) ;
  printf ("\n") ;

}

####################################################
# sub create_html
####################################################

sub create_html {

$html_report = "$LOGDIR/build_report.${timestamp}.html" ;

chdir "$ENV{BUILDHOME}/bin/XSL" ;
$cmd = "$ENV{BUILDHOME}/bin/XSL/runxsl.tcsh $REP_LOG $ENV{BUILDHOME}/bin/XML/build_report.xsl $html_report" ;

system($cmd) ;

}

####################################################
# sub send_email
####################################################

sub send_email {
	
	$RESULT = "FAILED";
	
	if ( ${total_product_success_rate} eq 100){
		$RESULT = "SUCCESSFUL";
	}

	$emailAddress = "$ENV{EMAILADDRESS}" ;
		
	$subject = "The Build $product_build_counter for $product version $version $variant variant on $host is ${RESULT}" ;

	if ( $ENV{ARCH} eq "HP-UX") {
		$cmd = "/bin/cat $html_report  | uuencode BuildReport_${product}_${version}_${variant}_${host}.html | mailx -s '$subject' -m $emailAddress" ;
	}
	else {
		$cmd = "/bin/cat $html_report  | uuencode BuildReport_${product}_${version}_${variant}_${host}.html | mailx -s '$subject' $emailAddress" ;
	}
	system($cmd) ;
}

####################################################
# sub send_pmd_email
####################################################

sub send_pmd_email {
		
	if ( $product =~ /crm/i) {
		$pmd_report_location = "$ENV{CCWPA}";
		$pmd_report_name = "PMD_Report_ccrm3Apps.html";
		
		$subject = "The PMD report for $product version $version $variant variantbuild for $product_build_counter on $host is ${RESULT}" ;

		if ( -f "$pmd_report_location/$pmd_report_name"){		
			if ( $ENV{ARCH} eq "HP-UX") {
				$cmd = "/bin/cat $pmd_report_location/$pmd_report_name  | uuencode $pmd_report_name | mailx -s '$subject' -m $emailAddress" ;
			}
			else {
				$cmd = "/bin/cat $pmd_report_location/$pmd_report_name  | uuencode $pmd_report_name | mailx -s '$subject' $emailAddress" ;
			}
			system($cmd) ;	
		}	
	}
}



####################################################
# sub diffdate
####################################################

sub diffdate()
{
	my $CurrentYear =  ((localtime(time))[5] + 1900);
	$CurrentYear =~ s/..//;
	my $Secs = 1;
	my $SecsInMinute   = $Secs * 60;
	my $SecsInHour    = $SecsInMinute * 60;
	my $SecsInDay      =  $SecsInHour * 24;
	my @TimeUnits = ($Secs,$SecsInMinute, $SecsInHour, $SecsInDay);

	my ($startdate, $enddate) = @_;
	local (@Start,@End, $DiffTime, $cnt) ;
	local (@Result) = (0,0,0,0);
	local $TimeStamp = 'A4A2A2AA2A2A2';
	local ($EpochStart, $EpochEnd);

  @Start = (unpack($TimeStamp, $startdate))[6,5,4,2,1,0];
  #$Start[5] += (($Start[5] > $CurrentYear) ? 1900 : 2000); # Get right year if year is only 2 digits
  $Start[4] -= 1; # -1 for month

  @End = (unpack($TimeStamp, $enddate))[6,5,4,2,1,0];
  #$End[5] += (($End[5] > $CurrentYear) ? 1900 : 2000); # Get right year if year is only 2 digits
  $End[4] -= 1; # -1 for month

  $EpochEnd = Time::Local::timelocal (@End);
  $EpochStart = Time::Local::timelocal (@Start);

  $DiffTime = $EpochEnd - $EpochStart;

  $cnt = 0;
  while ($DiffTime > 0 && $cnt < (scalar (@TimeUnits) - 1)) {
  	$Result[$cnt] = ($DiffTime % $TimeUnits[$cnt+1]) / $TimeUnits[$cnt] ;
    $DiffTime -= ($Result[$cnt] *  $TimeUnits[$cnt]);
    $cnt++;
  }
  $Result[$cnt] = $DiffTime / $TimeUnits[$cnt];
  return (reverse (@Result));
}

####################################################
# sub get_tasks_report
####################################################

sub get_tasks_report {
	return if (! defined $build_counter ) ;
	($version_num) = (split(/v/,$version))[1] ;
	$GetTasksList = "$ENV{CCMNGRHOME}/bin/getTasksFromBuildCounter.pl -v $version_num -b $build_counter|" ;
	
	if (! open(PIPE, $GetTasksList)) {
  	print "\n\tError: There are no tasks to work on.\n" ;
	}

	@tasks_list = <PIPE> ;
	chomp(@tasks_list) ;
	close(PIPE);

	print REPORT "<Tasks>\n" if (@tasks_list) ;

	foreach $task (@tasks_list) {
		$task =~ s/&/\//;
		print REPORT "    <Task>\n" ;
		print REPORT "       <Name>$task</Name>\n" ;
		print REPORT "    </Task>\n" ;
	} 
	print REPORT "</Tasks>\n"  if (@tasks_list) ;
}

####################################################
# sub check_product_statistics_results 
####################################################

sub check_product_statistics_results {

$java_percentage = &calc_percentage($product_total_java_err,$product_total_java) ;
$obj_percentage = &calc_percentage($product_total_objects_err,$product_total_objects) ;
$sl_percentage = &calc_percentage($product_total_shared_libs_err,$product_total_shared_libs) ;
$jars_percentage = &calc_percentage($product_total_jars_err,$product_total_jars) ;
$exe_percentage = &calc_percentage($product_total_err,$product_total_exes) ;
$pars_percentage = &calc_percentage($product_total_pars_err,$product_total_pars) ;
$server_percentage = &calc_percentage($product_total_server_err,$product_total_server) ;
$maps_percentage = &calc_percentage($product_par_total_maps_err,$product_par_total_maps) ;

print "product_total_java percentage success = $java_percentage \n" ;
print "product_total_obj percentage success = $obj_percentage \n" ;
print "product_total_sl  percentage success = $sl_percentage \n" ;
print "product_total_jars  percentage success = $jars_percentage \n" ;
print "product_total_exe percentage success = $exe_percentage \n" ;
print "product_total_pars  percentage success = $pars_percentage \n" ;
print "product_total_server  percentage success = $server_percentage \n" ;
print "product_total_maps  percentage success = $maps_percentage \n" ;

$total_product_failure = 700 - ($jars_percentage + $java_percentage + $obj_percentage + $exe_percentage + $sl_percentage + $pars_percentage + $server_percentage);
$total_product_success_rate = &calc_percentage($total_product_failure,700) ;

print "The success rate for the product build is '$total_product_success_rate' \n" ;
print "\nThe build SUCCESS \n" if  ($total_product_success_rate > 96) ;
print "\nThe build FAILED  \n" if  ($total_product_success_rate < 96) ;

	if ($CCPRODTYPE eq "EN6") {
		$product_log_statistics_dir = "$ENV{CCPROJECTHOME}/$version/$product/Audit/prd/$timestamp/" ;
	}
	else {
		$product_log_statistics_dir = "$ENV{CCPROJECTHOME}/$version/$product/Audit/prd/$variant/$timestamp/" ;
	}

$product_log_success_rate = "${product_log_statistics_dir}/success_rate_${product}_${version}_V${variant}.log" ;

open(PRODUCT_LOG_RATE,">$product_log_success_rate") || die "Can't open $product_log_success_rate" ;

##################

print PRODUCT_LOG_RATE "Total Java Files = $product_total_java \n" ; 
print PRODUCT_LOG_RATE "Total C/C++ Files = $product_total_objects \n" ;
print PRODUCT_LOG_RATE "Total Shared Libraries Files =  $product_total_shared_libs \n" ;
print PRODUCT_LOG_RATE "Total Jar Files =  $product_total_jars \n" ;
print PRODUCT_LOG_RATE "Total Executables Files =  $product_total_exes \n\n" ;
print PRODUCT_LOG_RATE "Total Par Files =  $product_total_pars \n\n" ;
print PRODUCT_LOG_RATE "Total OMS build =  $product_total_server \n\n" ;
print PRODUCT_LOG_RATE "Total Maps Files =  $product_par_total_maps \n\n" ;

print PRODUCT_LOG_RATE "Failure Java Files = $product_total_java_err\n" ;
print PRODUCT_LOG_RATE "Failure C/C++ Files =  $product_total_objects_err\n" ;
print PRODUCT_LOG_RATE "Failure Shared Libraries Files = $product_total_shared_libs_err \n" ; 
print PRODUCT_LOG_RATE "Failure Jar Files = $product_total_jars_err \n" ; 
print PRODUCT_LOG_RATE "Failure Executables Files = $product_total_err\n\n" ; 
print PRODUCT_LOG_RATE "Failure Par Files = $product_total_pars_err\n\n" ;
print PRODUCT_LOG_RATE "Failure OMS build = $product_total_server_err\n\n" ;
print PRODUCT_LOG_RATE "Failure Maps Files = $product_par_total_err\n\n" ;

print PRODUCT_LOG_RATE "Success Rate Java = ${java_percentage}% \n" ;
print PRODUCT_LOG_RATE "Success Rate C/C++ =  ${obj_percentage}% \n" ;
print PRODUCT_LOG_RATE "Success Rate Shared Libraries = ${sl_percentage}% \n" ;
print PRODUCT_LOG_RATE "Success Rate Jars =  ${jar_percentage}% \n" ; 
print PRODUCT_LOG_RATE "Success Rate Executables =  ${exe_percentage}% \n\n" ;
print PRODUCT_LOG_RATE "Success Rate Par =  ${pars_percentage}% \n\n" ;
print PRODUCT_LOG_RATE "Success Rate OMS build =  ${server_percentage}% \n\n" ;
print PRODUCT_LOG_RATE "Success Rate Maps =  ${maps_percentage}% \n\n" ;

print PRODUCT_LOG_RATE "Total Build Success Rate = ${total_product_success_rate}% \n" ;

##################################################

close (PRODUCT_LOG_RATE) ;

}

####################################################
# get_statistics_report
####################################################
sub get_statistics_report { 

print REPORT "\n\n<Statistics>\n" ;

if ($product !~ /oms/i){
	print REPORT "    <Record>\n" ;
	print REPORT "       <Name>Java</Name>\n" ;
	print REPORT "       <Total_Files>$product_total_java</Total_Files>\n" ;
	print REPORT "       <Failure>$product_total_java_err</Failure>\n" ;
	print REPORT "       <Success_rate>${java_percentage}%</Success_rate>\n" ;
	print REPORT "    </Record>\n" ;

	print REPORT "    <Record>\n" ;
	print REPORT "       <Name>C/C++</Name>\n" ;
	print REPORT "       <Total_Files>$product_total_objects</Total_Files>\n" ;
	print REPORT "       <Failure>$product_total_objects_err</Failure>\n" ;
	print REPORT "       <Success_rate>${obj_percentage}%</Success_rate>\n" ;
	print REPORT "    </Record>\n" ;

	print REPORT "    <Record>\n" ;
	print REPORT "       <Name>Shared Libraries</Name>\n" ;
	print REPORT "       <Total_Files>$product_total_shared_libs</Total_Files>\n" ;
	print REPORT "       <Failure>$product_total_shared_libs_err</Failure>\n" ;
	print REPORT "       <Success_rate>${sl_percentage}%</Success_rate>\n" ;
	print REPORT "    </Record>\n" ;

	print REPORT "    <Record>\n" ;
	print REPORT "       <Name>Jar Files</Name>\n" ;
	print REPORT "       <Total_Files>$product_total_jars</Total_Files>\n" ;
	print REPORT "       <Failure>$product_total_jars_err</Failure>\n" ;
	print REPORT "       <Success_rate>${jars_percentage}%</Success_rate>\n" ;
	print REPORT "    </Record>\n" ;

	print REPORT "    <Record>\n" ;
	print REPORT "       <Name>Executabls</Name>\n" ;
	print REPORT "       <Total_Files>$product_total_exes</Total_Files>\n" ;
	print REPORT "       <Failure>$product_total_err</Failure>\n" ;
	print REPORT "       <Success_rate>${exe_percentage}%</Success_rate>\n" ;
	print REPORT "    </Record>\n" ;

	print REPORT "    <Record>\n" ;
	print REPORT "       <Name>Par</Name>\n" ;
	print REPORT "       <Total_Files>$product_total_pars</Total_Files>\n" ;
	print REPORT "       <Failure>$product_total_pars_err</Failure>\n" ;
	print REPORT "       <Success_rate>${pars_percentage}%</Success_rate>\n" ;
	print REPORT "    </Record>\n" ;

	print REPORT "    <Record>\n" ;
	print REPORT "       <Name>BPM's in Par file</Name>\n" ;
	print REPORT "       <Total_Files>$product_par_total_maps</Total_Files>\n" ;
	print REPORT "       <Failure>$product_par_total_maps_err</Failure>\n" ;
	print REPORT "       <Success_rate>${maps_percentage}%</Success_rate>\n" ;
	print REPORT "    </Record>\n" ;
}
else{
	print REPORT "    <Record>\n" ;
	print REPORT "       <Name>OMS build</Name>\n" ;
	print REPORT "       <Total_Files>$product_total_server</Total_Files>\n" ;
	print REPORT "       <Failure>$product_total_server_err</Failure>\n" ;
	print REPORT "       <Success_rate>${server_percentage}%</Success_rate>\n" ;
	print REPORT "    </Record>\n" ;
}
print REPORT "</Statistics>\n" ;

}

####################################################
# get_Error_Messag_report
####################################################
sub get_Error_Messag_report {

print REPORT "\n\n<Error_Messaging>\n";


foreach (@proj_msg_failure) {
   print REPORT "   <Project>  \n";
   print REPORT "       <Name>$_</Name>\n" ;
   print REPORT "       <Failure_Message>Warnning! Messages differences.</Failure_Message> \n";
   print REPORT "   </Project>  \n";
}

print REPORT "\n\n</Error_Messaging>\n";

}


####################################################
# sub calc_percentage
####################################################
sub calc_percentage {

local ($error_files,$total_files) = @_ ;
local $temp_percentage;
$total_files = 1 if ($total_files == 0) ;
  $temp_percentage = 100 - ($error_files/$total_files)*100 ;
  $temp_percentage = sprintf("%.1f",$temp_percentage) ;
  $temp_percentage =~ s/\.0// ;
print "00 $error_files/$total_files $temp_percentage \n" ;
return($temp_percentage) ;


}


####################################################
# sub Usage
####################################################
sub Usage {

$Command = `basename $0` ;
chomp($Command);

print "\nUsage:\n" ;
print "\n\t $Command -pd abp -v v650 -vrt 64 -ts 20050403_113000 [-order] [-SM]\n\n";
print "-order: The projects list will be sorted according the modbo file.\n\n";
print "-SM: The report will be sent by email to '$ENV{EMAILADDRESS}' \n\n";
exit(1);

}

####################################################
# sub print_with_format
####################################################

sub print_with_format {

my($str1,$str2,$str3,$str4) = @_ ;

  printf ("%-20s",$str1) ;
  printf ("%-30s",$str2) ;
  printf ("%-20s",$str3) ;
  printf ("%-20s",$str4) ;
  printf ("\n") ;

}


####################################################
# sub get_file_list
####################################################
sub get_file_list {
	local ($dirn, $only_src) = @_;
	#print "DEBUG \$dirn = $dirn\n";
	#print "only_src = $only_src\n";
	local (@mylist, $item);
	@mylist = &read_dir($dirn, $only_src);
	$dirn = "" if ($dirn eq "/");
	#print " =================== \@mylist ==================\n @mylist\n";
	foreach $item (@mylist) {
		next if ($item =~ /^\.{1,2}$/);
		if (-f $dirn."/".$item) {
			if ((! $only_src) || (($only_src) && ($dirn =~ /\/src$/))) { 
				#print "File $dirn/$item\n";
				#print "$item\n";
				push (@filelist, $item);
			} 
		}
		&get_file_list($dirn."/".$item, $only_src) if (-d $dirn."/".$item);
	}
#print "FILE LIST is\n";
#print  @filelist;
#return @filelist;
}

####################################################
# sub read_dir
####################################################
sub read_dir {
	local ($mydirn) = @_;
	local @list;
	#print "\$mydirn=$mydirn\n";
	opendir (MYDIR, $mydirn) or die "Can\'t open directory $mydirn";
	@list = readdir(MYDIR);
	close ($mydirn);
	return @list;
}
