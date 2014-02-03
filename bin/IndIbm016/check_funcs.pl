#########################################
## sub check_Beans
#########################################

sub check_Beans {
	$pattern = "dynamics = amdocs" ;
	$amdocs_dyn_topic = grep(/$pattern/,@bb_profile) ;

	if ( $amdocs_dyn_topic ) {
    chdir "${src_area}/amdocs" ;
    find(\&wanted, "${src_area}/amdocs");
    find(\&wanted1, "${src_area}/amdocs");
	}
}

sub check_Beans_err {
	
	foreach (@Beans_ARR) {
		$proj_total_jars += 4 ;
		
		if ((! -f "$proj_area/ejb/WLS/${_}Bean.jar") && ! &check_excluded("WLS/${_}Bean.jar")){
	     push (@Beans_ARR_ERR, "WLS/${_}Bean.jar");
	     $proj_total_jars_err += 1 ;
	 	}
	
	 	if ((! -f "$proj_area/ejb/WLS/${_}BeanSec.jar" ) && ! &check_excluded("WLS/${_}BeanSec.jar")) {
	     push (@Beans_ARR_ERR, "WLS/${_}BeanSec.jar");
	     $proj_total_jars_err += 1 ;
	 	}
	
	 	if ((! -f "$proj_area/ejb/WAS/${_}Bean.jar") && ! &check_excluded("WAS/${_}Bean.jar")) {
	     push (@Beans_ARR_ERR, "WAS/${_}Bean.jar");
	     $proj_total_jars_err += 1 ;
	 	}
	
	 	if ((! -f "$proj_area/ejb/WAS/${_}BeanSec.jar" ) && ! &check_excluded("WAS/${_}BeanSec.jar")) {
	     push (@Beans_ARR_ERR, "WAS/${_}BeanSec.jar");
	     $proj_total_jars_err += 1 ;
	 	}
	
		$bb_failure_status = 1 if ($proj_total_jars_err > 0 ) ;
	}
	
	
	foreach (@Beans_WLS_ARR) {
	
		$proj_total_jars += 2 ;
	
	 	if ((! -f "$proj_area/ejb/WLS/${_}Bean.jar") && ! &check_excluded("WLS/${_}Bean.jar")) {
	 		push (@Beans_WLS_ARR_ERR, "WLS/${_}Bean.jar");
	    $proj_total_jars_err += 1 ;
	 	}	
	 	if ((! -f "$proj_area/ejb/WLS/${_}BeanSec.jar" ) && ! &check_excluded("WLS/${_}BeanSec.jar")) {
	 		push (@Beans_WLS_ARR_ERR, "WLS/${_}BeanSec.jar");
	    $proj_total_jars_err += 1 ;
	 	}	
		$bb_failure_status = 1 if ($proj_total_jars_err > 0 ) ;
	
	}
	
	foreach (@Beans_WAS_ARR) {
	
		$proj_total_jars += 2 ;
	
	 	if ((! -f "$proj_area/ejb/WAS/${_}Bean.jar") && ! &check_excluded("WAS/${_}Bean.jar")) {
	 		push (@Beans_WAS_ARR_ERR, "WAS/${_}Bean.jar");
	    $proj_total_jars_err += 1 ;
	 	}	
	 	if ((! -f "$proj_area/ejb/WAS/${_}BeanSec.jar" ) && ! &check_excluded("WAS/${_}BeanSec.jar")) {
	 		push (@Beans_WAS_ARR_ERR, "WAS/${_}BeanSec.jar");
	    $proj_total_jars_err += 1 ;
	 	}	
		$bb_failure_status = 1 if ($proj_total_jars_err > 0 ) ;
	}	
}

#########################################################
# sub wanted
#########################################################

sub wanted {

   if ( -f $File::Find::name ) {
      if ($_ =~ /-weblogic-ejb-jar.xml/) {
       ($base_jar_fname) = split (/-weblogic-ejb-jar.xml/,$_) ; 
        push(@Beans_WLS_ARR,$base_jar_fname) if (! grep (/$base_jar_fname$/,@Beans_WLS_ARR));
        $proj_total_jars+=1;
      }
   }

}

#########################################################
# sub wanted
#########################################################

sub wanted1 {

	if ( -f $File::Find::name ) {
  	if ($_ =~ /-ibm-ejb-jar-bnd.xmi/) {
    	($base_jar_fname) = split (/-ibm-ejb-jar-bnd.xmi/,$_) ; 
      if ((! grep (/$base_jar_fname$/,@Beans_WAS_ARR)) && (! grep (/$base_jar_fname$/,@Beans_WLS_ARR)) && (! grep (/$base_jar_fname$/,@Beans_ARR))){
      	push(@Beans_WAS_ARR,$base_jar_fname);
        $proj_total_jars+=1;
      }elsif ((grep (/$base_jar_fname$/,@Beans_WLS_ARR)) && (grep (/$base_jar_fname$/,@Beans_WAS_ARR)) && (grep (/$base_jar_fname$/,@Beans_ARR))) {
        &rm_from_array(\@Beans_WAS_ARR,$base_jar_fname);
        &rm_from_array(\@Beans_WLS_ARR,$base_jar_fname);
      }elsif ((grep (/$base_jar_fname$/,@Beans_WLS_ARR)) && (grep (/$base_jar_fname$/,@Beans_WAS_ARR)) && (! grep (/$base_jar_fname$/,@Beans_ARR))) {
        push(@Beans_ARR,$base_jar_fname);
        $proj_total_jars+=1;
        &rm_from_array(\@Beans_WAS_ARR,$base_jar_fname);
        &rm_from_array(\@Beans_WLS_ARR,$base_jar_fname);
      }elsif ((grep (/$base_jar_fname$/,@Beans_WLS_ARR)) && ( grep (/$base_jar_fname$/,@Beans_ARR)) && (!grep (/$base_jar_fname$/,@Beans_WAS_ARR) )) {        	
       	&rm_from_array(\@Beans_WLS_ARR,$base_jar_fname);
      }elsif ((grep (/$base_jar_fname$/,@Beans_WAS_ARR)) && ( grep (/$base_jar_fname$/,@Beans_ARR)) && (!grep (/$base_jar_fname$/,@Beans_WLS_ARR) )) {
       	&rm_from_array(\@Beans_WAS_ARR,$base_jar_fname);
      }elsif (grep (/$base_jar_fname$/,@Beans_WLS_ARR) && (! grep (/$base_jar_fname$/,@Beans_ARR))) {
       	push(@Beans_ARR,$base_jar_fname);
       	$proj_total_jars+=1;
       	&rm_from_array(\@Beans_WLS_ARR,$base_jar_fname);	
      }
    }
  }
}

####################################################################
# Name    : rm_from_array 
# Purpose : remove an element from an array. 
#           
# Input   : target  - reference to an array.
#           element - element to remove.
# Output  : target - reference to the array after removing an element.
# Returns : $st_ok  - on success.
#           $st_bad - when element to remove is missing. 
####################################################################
sub rm_from_array {
	local($target, $element) = @_; 
	my ($ind);
	my $removed = $FALSE; 

	for ($ind=0;$ind<=$#$target;$ind++){
		if ($$target[$ind] eq $element){
			splice (@$target,$ind,1);
			$removed = $TRUE;
			last;
		}
	}
	if ($removed){
		return $st_ok;
	} 
}

#####################################################
## sub find_main.list
#####################################################

sub find_main_list {

my $pname_no_Variant ;
($pname_no_Variant) = (split(/V/,$pname))[0] ;

foreach $current_topic ( @static_topics ) {
	chdir "${src_area}/${current_topic}/src" ;

	if ((-f "${src_area}/${current_topic}/src/main.list") && ( ! -z "${src_area}/${current_topic}/src/main.list" )) {

		open(MAIN_LIST,"${src_area}/${current_topic}/src/main.list") || print "Can't open ${src_area}/${current_topic}/src/main.list" ; 
		while(<MAIN_LIST>) {
			chomp ;
			if ( (! /^$/) && (! /^#/) && (! /\.sql/)) {
			($file) = split(/\s+/,$_) ;

				if ( &is_in_array($file,@{$excl_hash{$pname_no_Variant}{FILES}}) && ($file)) {
					next;
    		}
				if (/DYNAMIC_LIB_EXT/ || /DLLLIB_EXT/) {
					($exe_lib_file) = split (/\./,$file) ;
					$exe_lib_file .= ".${DYNAMIC_LIB_EXT}" ; 
					if ((! -x "$ENV{HOME}/proj/${pname}/lib/${exe_lib_file}" && ! -x "$ENV{HOME}/proj/${pname}/ut/${exe_lib_file}") || (! -r "$ENV{HOME}/proj/${pname}/lib/${exe_lib_file}" && ! -r "$ENV{HOME}/proj/${pname}/ut/${exe_lib_file}")) {
						$bb_failure_status = 1;
						push(@exe_failure,$file);
					}
					$proj_total_exes += 1 ;
				}
				else {
					($file) = split(/\$/,$file) ;
					if ((! -x "$ENV{HOME}/proj/${pname}/bin/${file}" && ! -x "$ENV{HOME}/proj/${pname}/ut/${file}") || ( ! -r "$ENV{HOME}/proj/${pname}/bin/${file}" && ! -r "$ENV{HOME}/proj/${pname}/ut/${file}" )) {
						$bb_failure_status = 1 ;
						push(@exe_failure,$file);
					}
					$proj_total_exes += 1 ;
        }
      }
    }

    close(MAIN_LIST) ;
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


my $envbb = $bb_name;
my $envbb_libdiv = $envbb.'_'.'LIB_DIVIDE';

 if   ((grep(/BB_LIBRARY_TYPE\s*=\s*DYNAMIC/,@BB_MAKE_DEF) && ! grep(/#\s*BB_LIBRARY_TYPE\s*=\s*DYNAMIC/,@BB_MAKE_DEF)  ||  grep(/BB_LIBRARY_TYPE\s*=\s*DYNAMIC/,@PROJ_MAKE_DEF))  && ! grep(/#\s*BB_LIBRARY_TYPE\s*=\s*DYNAMIC/,@PROJ_MAKE_DEF) && ! grep(/BB_LIBRARY_TYPE\s*=\s*ARCHIVED/,@BB_MAKE_DEF))  {

      $proj_total_shared_libs += 1 ;

    if (($ENV{$envbb_libdiv}) || grep(/${bb_name}_LIB_DIVIDE/,@PROJECT_SETUP)) {
    	$proj_total_shared_libs--;
    	foreach $current_topic ( @static_topics ) {
    		$proj_total_shared_libs += 1 ;
    		$libname = 'lib'.$bb_name.'_'.$current_topic.'.'.${DYNAMIC_LIB_EXT};
    		$base_libname = 'lib'.$bb_name.'_'.$current_topic;
    		$genrtd_mkfile = "$proj_area/$bb_name/Makefile."."$current_topic".".lib";
    		open (GMKF, "$genrtd_mkfile");
    		my @lines = <GMKF>;
    		close GMKF;
    		chomp @lines;
    		my $noObj = 0;
    		foreach $l (@lines) {
    			if ($l =~/^LIBOBJ\s*=\s*(.*)/) {
    				if ($1 eq "") {
    					$noObj = 1;
    					last;	
    				}
    			}
    		}
    		if ($noObj) {
    			next;	
    		}
    		if ((! -f "$lib_area/$libname") && (! -f "$lib_area/${base_libname}mt.${DYNAMIC_LIB_EXT}") && (! -f "$ut_area/$libname") )  {
    			return if (&check_excluded("$base_libname"));
    			push(@sl_failure,"$lib_area/$libname");
    			$bb_failure_status = 1 ;
       			$proj_total_shared_libs_err += 1 ;
    		}
    	}
    }elsif ((! -f "$lib_area/lib${bb_name}.${DYNAMIC_LIB_EXT}") && (! -f "$lib_area/lib${bb_name}mt.${DYNAMIC_LIB_EXT}") && (! -f "$ut_area/lib${bb_name}.${DYNAMIC_LIB_EXT}") ) {

      return if (&check_excluded("lib${bb_name}") || grep(/${bb_name}_LIB_DIVIDE/,@PROJECT_SETUP)) ;

       push(@sl_failure,"$lib_area/lib${bb_name}.${DYNAMIC_LIB_EXT}") ;
       $bb_failure_status = 1 ;
       $proj_total_shared_libs_err += 1 ;
   }
 }  # endif BB_LIBRARY_TYPE=DYNAMIC
} #endif make.def existance 


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
   			if (grep (/\$\{env\.CCBB\}/, $jar)){
					print "$ENV{CCBB} ---- build_${bb_name}.xml \n";
					
  				$jar = (split(/\$\{env\.CCBB\}/,$jar))[1];
  				$jar = ${bb_name}.$jar;
					chomp($jar);

		  		if (! -f "$lib_area/$jar") {
    				#if (&check_excluded("$jar")) {
   					#	close(BUILDXML) ;
     				#	return;
     				#}
					
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
# check_java_compilation_error
####################################################

sub check_java_compilation_error {

$last = "last" ;
@errors_topics = () ;

foreach $current_topic ( @dynamic_topics ) {

	print "CHECK_JAVA PARAM $ENV{CHECK_JAVA} \n";
  next if (&check_excluded("$current_topic") || ($ENV{CHECK_JAVA} eq "NO")) ;  
   
  $java_files_num{$current_topic} = 0 ;
  $java_files_failure_num{$current_topic} = 0 ;

  opendir (TOPIC,"$src_area/$current_topic") || die "can't open $src_area/$current_topic" ;

  foreach $java_file (readdir (TOPIC)) {

  	if ($java_file =~ /\.java$/) {

    	$java_files_num{$current_topic} += 1 ;
      $proj_total_java += 1 ;

      ($class_file) = split (/\.java/,$java_file) ;
      $class_file .= ".class" ;
      
      @package_topic = `grep package ${src_area}/$current_topic/$java_file`;
      $package_topic[0] =~ s/package //g;
      $package_topic[0] =~ s/\;//g;
      $package_topic[0] =~ tr/\./\//;
			chomp $package_topic[0];			

	    #Changing the search path to start from com
      #$java_topic =~ s/JavaClasses\///g;
      
      $java_topic = "$current_topic";
      $java_topic =~ s/^(\w+)\/com\//com\//g;
      
      next if (&check_excluded("${current_topic}"."/"."${class_file}"));
      
      if (! -f "$proj_area/classes/$java_topic/$class_file" && ! -f "$proj_area/classes/$current_topic/$class_file" && ! -f "$proj_area/classes/$package_topic[0]/$class_file" &&! -f "$proj_area/${bb_name}/classes/$java_topic/$class_file" && ! -f "$proj_area/${bb_name}/classes/$current_topic/$class_file" && ! -f "$proj_area/${bb_name}/classes/$package_topic[0]/$class_file") 
      {
      	
      	print "HHH $proj_area/${bb_name}/classes/$java_topic/$class_file \n";
      	print "The next class is failed $class_file \n";
      	$count += 1;
      	     	
      	push(@errors_topics,$current_topic) ;
        $java_files_failure_num{$current_topic} += 1 ;
        $proj_total_java_err += 1 ;
      }

     }  # endif java_file = java

   }  # end foreach $java_files 
}  

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

#sub check_sonar_failure {

#return if (! opendir(SONAR,"$proj_area/sonar_templates") ) ;

#foreach (readdir(SONAR) ) {
#chomp ;

# if ( /STBError_\w*_*$bb_name/ ) {

#    push(@sonar_failure,$bb_name)  if (! grep(/$bb_name/,@sonar_failure)) ;
#    push(@proj_sonar_failure,$bb_name) if (! grep(/$bb_name/,@proj_sonar_failure)) ;
#    $bb_failure_status = 1 ;

# }

#}


#}



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
## sub check_general_failure
#########################################

sub check_general_failure {

my ($ra_TYPE_failure, $ra_spec_TYPError, $ra_TYPE_errors, $ra_proj_TYPE_errors, $type) = @_;

$build_log_dir = "$ENV{HOME}/$version/$product/Audit/proj/log.$pname/log.$bb_name" ;


my $log_file = &get_last_log($build_log_dir);

open(LOG_FILE,"$build_log_dir/$log_file") || warn "Warning : Can't open $log_file log file" ;
my @lines = <LOG_FILE>;
chomp @lines;


my $spec_match = 0;
my $xe2 = "nochanceitmatches";
foreach $xe (@{$ra_TYPE_failure}) {
	$spec_match = 0;
	next if ($xe eq '') ;
	if ($xe =~/[\(\)\{\}\?\!\*\+]/) {
			$xe2 =$xe ;
			$xe2=~s/([\(\)\{\}\?\!\*\+])/\\$1/g;
			$spec_match = 1;
	}
	foreach $l (@lines) {
	
	if ((($l =~/$xe2/) && ($spec_match )) || ((!$spec_match) && ($l =~/$xe/))) {
	     unless ( &is_in_array($xe,@{$ra_spec_TYPError}) ) {
	     	push (@{$ra_spec_TYPError}, $xe);
		     push (@{$ra_TYPE_errors},$bb_name) ;
		     push (@{$ra_proj_TYPE_errors},$bb_name) ;
		     $product_type_errs = "$type"."_product_err";
		     ${$product_type_errs}++;
		     $bb_failure_status = 1 ;
		     push (@{genErr->{$pname}->{$bb_name}->{ERRORS}}, $xe);
		     push (@{genErr->{$pname}->{ERRORS}}, $xe);
		     $ptype = $type;
		     
		     $ptype =~s/_/ /g;
		     
		     push (@{errHash->{$type}->{ERRORS_TO_SEND}} , "The following building blocks in $pname project failed with $ptype errors : $bb_name with @{$ra_spec_TYPError}\n");
		     $error_counter++;
		     last;
	}
	     push (@{$ra_TYPE_errors},$bb_name) ;
	     push (@{$ra_proj_TYPE_errors},$bb_name) ;
	     $product_type_errs = "$type"."_product_err";
	     ${$product_type_errs}++;
	     $bb_failure_status = 1 ;
	     push (@{genErr->{$pname}->{$bb_name}->{ERRORS}}, $xe);
	     push (@{genErr->{$pname}->{ERRORS}}, $xe);
	     push (@{errHash->{$type}->{ERRORS_TO_SEND}} , "The following building blocks in $pname project failed with $type errors : $bb_name with @{$ra_spec_TYPError}\n");
	     $error_counter++;
         }
}
}

close(LOG_FILE) ;
closedir(LOG_DIR) ;

}

#########################################
## sub set_errors
#########################################
sub set_errors {
	
	my $error_file;
	
	if ($ENV{CCCORETYPE} eq "SDK") { 
		$error_file = "$ENV{SDKHOME}/$ENV{SDKRELEASE}/tools/build/config/CC_error.tmpl" ;
		$error_file_local = "$ENV{'CCPROJECTHOME'}/product/$ENV{CCPRODUCT}/$ENV{CCPRODUCTVER}/config/CC_error.tmpl" ;
	} else {
		
		$error_file = "$ENV{'CCPROJECTHOME'}/product/$ENV{CCPRODUCT}/$ENV{CCPRODUCTVER}/config/CC_error.tmpl" ;
		$error_file = "$ENV{'CCPROJECTHOME'}/product/$version/$product/config/CC_error.tmpl" ;
	} 
	
	open (ERF, "$error_file");
	my @lines = <ERF>;
	close ERF;
	
	open (ERF, "$error_file_local");
	my @lines_loc = <ERF>;
	close ERF;
	
	chomp @lines;
	chomp @lines_loc;
	my $email;
	my @types = ();
	
	#go over the types, define an array for each type like @{$failure_ar} and set the array of errors and an array of emails
	#for each type
	
		foreach $l (@lines_loc) {
			&treat_line($l, \@types);
		}
		
		foreach $l (@lines) {
			&treat_line($l, \@types);
		}
	
	return @types;
}
	


sub treat_line {
	
	my ($l, $ra_types) = @_;
	
	if ($l=~/^\#/) {
		next;
	}elsif ($l =~ /([^=]*)\s*=+(.*)/) {
		$type = $1;
		$type1 = $type;
		$type1 =~tr/a-z/A-Z/;
		$type1 =~s/\s/_/g;
		$type1 =~s/\_$//;
	}
	if ( &is_in_array($type1,@{$ra_types}) ) {
		return();	
	}
	push (@{$ra_types}, $type1);
	my $lc_type = $type1;
	$lc_type =~tr/A-Z/a-z/;	
	my $failure_ar = "$type1"."_failure";
	my $email_ar = "$lc_type"."_email";
	
	if ($l =~/$type\s*=\s*(.*)/i) {
		my $value = $1;
		chomp $value;
		if ($value =~/\%/){
			@{$failure_ar}=split ('%',$value);
		}else {
			@{$failure_ar}= $value;
		}
		
		my $num_of_el = scalar(@{$failure_ar}) - 1;
		if (${$failure_ar}[$num_of_el] =~/Email\s*=\s*(.*)/) {
			$email = $1;
			@{$email_ar} = split ('\s', $email);
			foreach my $em (@{$email_ar}) {
				if ($em =~/^(\$)+(.*)/) {
					push (@{emails->{$type1}}, "$ENV{$2}");
				}else {
					push (@{emails->{$type1}}, $em);
				}
			}
			#print "emails->{$type1} is @{emails->{$type1}}\n";
			&rm_from_array(\@{$failure_ar}, ${$failure_ar}[$num_of_el]);
			
			#print " failure_ar is @{$failure_ar}\n\n";
		}
	}	
}

#########################################
## sub check_optional_failure
#########################################
sub check_optional_failure{

$build_log_dir = "$ENV{HOME}/$version/$product/Audit/proj/log.$pname/log.$bb_name" ;


my $log_file = &get_last_log($build_log_dir);

open(LOG_FILE,"$build_log_dir/$log_file") || warn "Can't open $log_file" ;

foreach $of (@Optional_failure) {


my $of_grep_result = grep (/$of/,<LOG_FILE>);

  if ( $of_grep_result ) {
     push (@OPTIONAL_errors,$bb_name) ;
     push (@proj_OPTIONAL_errors,$bb_name) ;
     $bb_failure_status = 1 ;
     $error_counter++;
  }
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
	my $found_excl = 0;
	
	($pname_no_Variant) = (split(/V/,$pname))[0] ;
#	print "excl_hash{$pname_no_Variant}{FILES} isS >@{$excl_hash{$pname_no_Variant}{FILES}}< :: FILE IS $exclude_file \n";
	
	foreach $f (@{$excl_hash{$pname_no_Variant}{FILES}}) {
		if ($f=~/^\*\.(.*)$/) {
			$suffix = $1;
#  		print " (check_excluded) f is $f :: suffix is $suffix :: exclude_file is $exclude_file\n";
		}
		if (($f eq $exclude_file) || ($exclude_file =~/.*\.$suffix$/)) {
			$found_excl = 1;
			last;
		}
  }
#	print " (check_excluded) found_excl is $found_excl for $exclude_file\n";
	return $found_excl;
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
	opendir (MYDIR, $mydirn) or print "Can\'t open directory $mydirn";
	@list = readdir(MYDIR);
	close ($mydirn);
	return @list;
}



####################################################
# sub print_with_xml_format
####################################################

sub print_with_xml_format {

my($SUMM_LOG, $str1,$str2,$str3,$str4) = @_ ;

&LogWrite ($SUMM_LOG , "        <Project> ") ;
&LogWrite ($SUMM_LOG ,  "                <Name>$str1</Name> ") ;

&LogWrite ($SUMM_LOG ,  "                <Failure type='Type'>$str2</Failure> ") ;
&LogWrite ($SUMM_LOG ,  "                <Failure type='amount'>$str3</Failure> ") ;
&LogWrite ($SUMM_LOG ,  "                <Failure type='rate'>$str4</Failure> ") ;
&LogWrite ($SUMM_LOG ,  "        </Project> ") ;


}

####################################################################
# Name    : is_in_array
# Purpose : Check if an element belongs to an array.
# Input   : element , array .
# Return  : $TRUE/$FALSE .
####################################################################
sub is_in_array {
	my ($element,@array) = @_;

	if (grep(/^\Q$element\E$/,@array)){
		return 1 ;
	}else{
		return 0;
	}
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


sub crt_excl_hash {

	

	$excl_exe_file = "${DATA_DIR}/exclude_proj_exe_list.dat" ;
	my $version1 = $version;
	$version1 =~s/v//;
	open (EXCL_FILE, "$excl_exe_file");
	my @excl_lines = <EXCL_FILE>;
	close EXCL_FILE;
	
	chomp @excl_lines;
	
	
	
	foreach $l (@excl_lines) {
		my ($proj) = (split ('@', $l))[0];
		my ($files_lst) = $l;
		$files_lst =~s/$proj\@//;
		
		unless ($proj =~/(.*)$version1$/) {
			$proj .="$version1";
		}
		my @excl_files= split ('@', $files_lst);
#		print "(crt_excl_hash_1) PROJ IS $proj :: files_lst IS $files_lst\n";
		foreach $file (@excl_files) {
			push (@{$excl_hash{$proj}{FILES}} , $file);
		}
#		print "(crt_excl_hash_1) PROJ IS $proj :: excl_hash{$proj}{FILES} IS @{$excl_hash{$proj}{FILES}}\n";
		
	}
	
}

#########################################################
# sub check_jar_file
#########################################################

sub check_jar_file {

return if (( $bb_name =~ /gdd/) || ($bb_name =~ /_generated/) || ($bb_name =~ /_config/) ) ; ## Don't perform this check

return if (! -f "${src_area}/build.xml")  ;

open(BUILDXML,"${src_area}/build.xml") ;

@build_xml =<BUILDXML> ;

if ( grep(/antcall target="create_jars_job"/,@build_xml) ) {

   $proj_total_jars += 1 ;

   if ((! -f "$lib_area/${bb_name}_classes.jar") && (! -f "$ut_area/${bb_name}_classes.jar")) {

      if (&check_excluded("${bb_name}_classes.jar")) {
         close(BUILDXML) ;
         return;
      }

       $proj_total_jars_failure += 1 ;

   }

}

close(BUILDXML) ;

}

sub additional_gdd_check {
	
	my ($gnrtd_bb) = @_;
		my (@gddFILES, @failedFiles) =();
		$gddChecked{$bb_name} = 1;
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
			if ($curfile =~ /\.domain$|\.table$|\.sequence$|\.structure$/)  {
#				print "curfile = $curfile\n";
				unless (&is_in_array( $curfile,@gddFILES)) {
					push (@gddFILES, $curfile);
				}
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
			my $last_incurfile;
			foreach $incurfile (@debfilelist) {
				#print "incurfile = $incurfile\n";
				if ($curfile eq $incurfile) {
					#print "incurfile = $incurfile\n";
					#print "FOUND!\n";
					$is_found = 1;
					$last_incurfile = $incurfile;
				}
			}
			if ($is_found == 0) {
				push (@GDD_COPY2DEB_errors,$curfile) ;
				$deb_status = 1
			}
		}	
		if ($deb_status) {
			unless ( &is_in_array($bb_name,@proj_GDD_COPY2DEB_errors) ) {
				push (@proj_GDD_COPY2DEB_errors,$bb_name) ;
     				$bb_failure_status = 1 ;
     				$error_counter++;
     			}
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
			&check_gdd_products($bb_name,\@gddFILES ,$gnrtd_bb, \$deb_status, \@failedFiles);
		if ($deb_status) {
			push (@proj_GDD_OLDINDEB_errors,$bb_name) ;
     			$bb_failure_status = 1 ;
	     	}
	}
	
	
}

sub check_gdd_products {
	my ($bb,$ra_gddFILES,$gnrtd_bb, $rs_status, $ra_failed) = @_;
	my @files_to_check = ();
	$gnrtd_checked = 1;
	my @proj_ar = split ('/',$proj_area);
	my $num_of_el = @proj_ar;
	my $proj = $proj_ar[$num_of_el-1];
	my $gnrtd_out_dir = "$proj_area"."/"."$gnrtd_bb";
#	print "BEFORE 11 get_gnrtd_files :: $bb, $gnrtd_bb, $proj :: proj_area is $proj_area :: proj_ar is @proj_ar ::  num_of_el is $num_of_el :: PROJ IS $proj\n\n";
	&get_gnrtd($ra_gddFILES, $bb, $gnrtd_bb, $proj,\@files_to_check );
	foreach $f (@files_to_check ) {
		my $fullF = "$gnrtd_out_dir"."/"."$f";
		$proj_total_gdd += 1 ;
#		print "FFF IS $f\n";
 		next if  (&check_excluded($f));
#		unless ($f =~/.*\.udat/) {
			unless (-f $fullF) {
				$$rs_status = 1;
				unless (&is_in_array ($f, @$ra_failed)) {
					push (@$ra_failed, $f);
					push (@GDD_gnrtd_errors, , $f);
					$proj_total_gdd_err += 1 ;
				}				
			}
#		}
	}
	

}

##########################################################################
# Name : get_gnrtd
# Purpose : to get the files that are products of this BB and
#	reside in the _generated BB proj area .
##########################################################################

sub get_gnrtd {
	my ($ra_gddFILES, $bb, $gnrtd_bb, $proj,$ra_files_to_check) = @_;
	my ($file1, $file2, $file3, $file4);
	my (@gdd_files) = @$ra_gddFILES;
	my ($file_to_rm, $my_topic, $gnrtd_out_dir, $ver, $gnrtd_out_file, $suff) ;
	
	
	foreach $fl (@gdd_files) {
		$fl=~/(\w*)(\.(.*))+/;
		$file = $1;
		$fl=~/(.*)\.(.*)/;
		$suff = $2;
		$gnrtd_out_dir = "$proj_area"."/"."$gnrtd_bb";
		$gnrtd_out_file = "$gnrtd_out_dir"."/"."."."$file".".$suff";
		
		&get_files_to_chk ($gnrtd_out_file, $ra_files_to_check);
	}
	
#	print " (get_gnrtd) DEBUg :: FILES in GNRTD  are >@$ra_files_to_check<\n";
	
	
}


sub get_files_to_chk {
	my ($gnrtd_out_file, $ra_files_to_check) =@_;
	my (@lines) = ();
#	print "DEBUg :: (get_files_to_chk) gnrtd_out_file is $gnrtd_out_file, ra_files_to_check is @$ra_files_to_check\n";
	open (GNRTD,"$gnrtd_out_file");
	@lines = <GNRTD>;
	chomp (@lines);
    	close(GNRTD);
	foreach $line (@lines) {
		push (@$ra_files_to_check, $line);
	}
#	print "DEBUg :: (get_files_to_chk)THE files to check are @$ra_files_to_check\n";
}


sub send_err_mes_email {
	my ( $type,$ra_email_address, @msg_to_send) = @_;
	my $mail_cmd;
	
	my $host = `uname -s`;
	
	
	if (@$ra_email_address) {
		$mail_cmd = "echo \"";
		foreach $mes (@msg_to_send) {
			$mail_cmd .= "$mes"."\n";	
		}
		if ( $ENV{ARCH} eq "HP-UX") {
			$mail_cmd .= "\" | mailx -s \"$type errors on $host\" -m @$ra_email_address";
		} else {
			$mail_cmd .= "\" | mailx -s \"$type errors on $host\" @$ra_email_address";
		}
		#print " \n mail_cmd is $mail_cmd\n\n";
		system $mail_cmd;
	}
	
}

#########################################
## sub get_last_log
#########################################

sub get_last_log {
	my ($dir) = @_;
	my $log_file;
        
	chdir($dir);
  open(LOG_DIR,"ls -tr *build* |") || warn "Can't open $dir" ;
  while(<LOG_DIR>){
		chomp();
    if(/^hbuild.log/ || /^build./){
        $log_file =$_;
    }
  }        
  return $log_file;
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
  	} 
  	elsif ( /dynamics = \w+/ ) {
   		@topics1 = split(/dynamics = /,$_) ;
    	shift(@topics1) ;     # remove the first space from @topics1
    	@dynamic_topics = split(/\s+/,join(//,@topics1)) ;
		}
	}
}


####################################################################
# Name    : rm_from_array 
# Purpose : remove an element from an array. 
# 
####################################################################
sub rm_from_array {
	local($target, $element) = @_; 
	my ($ind);
	my $removed = $FALSE; 



	for ($ind=0;$ind<=$#$target;$ind++){
		if ($$target[$ind] eq $element){
			splice (@$target,$ind,1);
			$removed = $TRUE;
			last;
		}
	}
	
	if ($removed){
		return $st_ok;
	} else {
		chomp($element);			
		my @temp = @$target;
		chomp(@temp);
	}
}

1;
