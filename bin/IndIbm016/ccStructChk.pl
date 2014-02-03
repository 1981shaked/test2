#! /usr/local/bin/perl 
#-d:ptkdb
#===============================================================================================
#== File Name          : ccStructChk.pl                                              
#== Description        : The script checks structure differences between one version to another. 
#== The options are :                                                                            
#== projects, check mising projects in the new version and not in the old version.               
#== bbs, check mising bbs in the new version and not in the old version.                         
#== topics, check mising topicss in the new version and not in the old version.                  
#== ALL, checks the all 3 options above.                                                         
#== make sure that these Env Vars are already set properly
#==
#== HAR_TWO_TASK 
#== HAR_REPORT_USER 
#== HAR_REPORT_PASS 
#==
#==============================================================================================#
use Env qw (ARCH
            HAR_REPORT_USER
            HAR_REPORT_PASS
            HAR_TWO_TASK
            USER
            CCPROJECTHOME
            HOME
            CCMNGRHOME
            CCPROJNAME
           );
undef $User;
undef $Passwd;
undef $Instance;


use DBI;
use Getopt::Long;

$opt_status = GetOptions( "sv=s"  =>  \$old_ver,
                          "tv=s"  =>  \$new_ver,
                          "opt=s" =>  \$option,
                        );

&Usage if (! defined($old_ver) || ! defined($new_ver) || ! defined($option)) ; 

($old_version_no_underscore = $old_ver) =~ s/_//g ;
($new_version_no_underscore = $new_ver) =~ s/_//g ;

&db_connect ;

&prepare_queries ;

if ( $option eq "ALL" ) {
   &check_topics ;
   &check_BBs ;
   &check_projects;
   &check_modules ;
   &check_comp ;
} elsif ( $option eq "topics") {
     &check_topics ;
} elsif ( $option eq "bbs") {
     &check_BBs ;
} elsif ( $option eq "projects") {
     &check_projects ;
} elsif ( $option eq "module") {
     &check_modules ;
} elsif ( $option eq "comp") {
     &check_comp ;
} else {
     die "You choose wrong option (ALL or projects or bbs or topics)" ;
}  

&db_disconnect ;

#=====================================
#=== sub db_connect
#=====================================
sub db_connect {
	my ($User,$Passwd,$Instance);
	$Instance = $HAR_TWO_TASK ;
	$User     = $HAR_REPORT_USER ;
	$Passwd   = $HAR_REPORT_PASS ;
	if ($Instance eq "" or $User eq "" or $Passwd eq "" ){
		print "Environment variables are missing...\n";
		print "Please setenv: ,HAR_TWO_TASK, HAR_REPORT_USER, HAR_REPORT_PASS...\n";
		exit 9;
	}
	$dsn = "dbi:Oracle:$Instance";
	  print "Connecting to $Instance as $User  ....\n" ;
	$dbh = DBI->connect($dsn, $User, $Passwd,{AutoCommit=>0});
	unless ($dbh) {
	      print "\nDBI connect failed: $DBI:errstr\n";
	      print "Unable to connect to database $dsn\n\n";
	exit 0 ;
	}
}
#=====================================
#=== sub prepare_queries 
#=====================================

sub prepare_queries {
	
	#===  Select topics that exist in one version and not in the other.  
	
	$SlctRowTopics = $dbh->prepare(q{select ab.BBNAME,amt.TOPICNAME from amdbb ab,amdbbversion abv,amdtopic amt 
	where abv.VERNAME LIKE ? 
	and abv.BBID = ab.BBID
	and ab.STATUS = 1
	and abv.STATUS =1
	and abv.BBVERSIONID = amt.BBVERSIONID
	and ab.BBNAME in ( select ab1.BBNAME from amdbb ab1,amdbbversion abv1 where abv1.VERNAME = ? and abv1.BBID = ab1.BBID )
	and amt.STATUS = 1
	and amt.TOPICNAME not in 
	( select amt.TOPICNAME from amdbbversion abv,amdtopic amt where
	abv.VERNAME = ? 
	and abv.BBID = ab.BBID
	and abv.BBVERSIONID = amt.BBVERSIONID
	)
	}) ;
	
	
	#=== Select BB's that exist in one version and not in the other.
	
	$SlctRowBBs = $dbh->prepare(q{select ab.BBNAME from amdbb ab,amdbbversion abv where
	abv.VERNAME = ? 
	and abv.BBID = ab.BBID
	and abv.STATUS =1
	and ab.STATUS = 1
	and ab.BBNAME not in ( select ab1.BBNAME from amdbb ab1,amdbbversion abv1 where abv1.VERNAME = ? and abv1.BBID = ab1.BBID )
	}) ;
	
	#=== Select projects that exist in one version and not in the other.
	
	$SlctRowProjects = $dbh->prepare(q{select ap.PROJNAME from amdproject ap
	where
	ap.PROJNAME LIKE ?
	and ap.STATUS = 1
	and replace(ap.PROJNAME,?,?) not in ( select ap.PROJNAME from amdproject ap where ap.PROJNAME LIKE ? and ap.STATUS = 1)
	}) ;

        #=== Select modules that exist in one version and not in the other.

        $SlctRowModules = $dbh->prepare(q{select MODNAME  from AMDMODULE 
        where MODID in (select MODID from AMDMODULEVERSION where VERNAME= ?
        and MODID not in (select MODID from AMDMODULEVERSION where VERNAME= ? ))
        });

        #=== Select components that exist in one version and not in the other.

        $SlctRowComp = $dbh->prepare(q{select compname from AMDCOMPONENT
        where COMPID in (select COMPID from AMDCOMPVERSION where vername= ? ) 
        and COMPID not in (select COMPID from AMDCOMPVERSION where vername= ? )
        });

}

#=====================================
#=== sub check_topics 
#=====================================

sub check_topics {
	print "=========================================================================\n" ;
	print "Missing topics in version $new_ver that exist in version $old_ver\n" ;
	print "=========================================================================\n" ;
	
	$old_ver2 = "$old_ver" . "%" ;
	
	$SlctRowTopics->execute($old_ver2,$new_ver,$new_ver) ;
	
	while (@rows = $SlctRowTopics->fetchrow_array) {
	   print "@rows \n" ;
	}

}


#=====================================
#=== sub check_BBs
#=====================================

sub check_BBs {

	print "\n=========================================================================\n" ;
	print "Missing BBs in version $new_ver that exist in version $old_ver\n" ;
	print "=========================================================================\n" ;
	
	
	$SlctRowBBs->execute($old_ver,$new_ver) ;
	
	while (@rows = $SlctRowBBs->fetchrow_array) {
	   print "@rows\n" ;
	}

}

#=====================================
#=== sub check_modules
#=====================================

sub check_modules {

        print "\n=========================================================================\n" ;
        print "Missing modules in version $new_ver that exist in version $old_ver\n" ;
        print "=========================================================================\n" ;

        $SlctRowModules->execute($old_version_no_underscore,$new_version_no_underscore);

        while (@rows = $SlctRowModules->fetchrow_array) {
           print "@rows \n" ;
        }

}

#=====================================
#=== sub check_comp
#=====================================

sub check_comp {

        print "\n=========================================================================\n" ;
        print "Missing components in version $new_ver that exist in version $old_ver\n" ;
        print "=========================================================================\n" ;

        $SlctRowComp->execute($old_version_no_underscore,$new_version_no_underscore);

        while (@rows = $SlctRowComp->fetchrow_array) {
           print "@rows \n" ;
        }

}

#=====================================
#=== sub check_projects
#=====================================

sub check_projects {

	print "\n=========================================================================\n" ;
	print "Missing projects in version $new_ver that exist in version $old_ver\n" ;
	print "=========================================================================\n" ;
	
	$old_version_no_underscore2 = "%" . "$old_version_no_underscore" ;
	$new_version_no_underscore2 = "%" . "$new_version_no_underscore" ;
	
	$SlctRowProjects->execute($old_version_no_underscore2,$old_version_no_underscore,$new_version_no_underscore,$new_version_no_underscore2) ;
	
	while (@rows = $SlctRowProjects->fetchrow_array) {
	   print "@rows\n" ;
	}

}




#=====================================
#=== sub db_disconnect 
#=====================================

sub db_disconnect {

 if (defined($dbh)) {
    print "\nDisconnecting from $ENV{HAR_TWO_TASK}\n\n";
    $SlctRowTopics->finish ;
    $SlctRowBBs->finish ;
    $SlctRowProjects->finish ;
    $dbh->disconnect;
  }
}       

#=====================================
#=== sub db_disconnect
#=====================================

sub Usage {

	$command = `basename $0` ;
	chomp($command) ;
	
	print "\n$command -sv 60_0 -tv 60_1 -opt ALL|comp|module|projects|bbs|topics \n" ; 
	print "\n-sv = The original version.\n" ;
	print "\n-tv = The new version.\n\n" ;
	exit(1) ;

}
