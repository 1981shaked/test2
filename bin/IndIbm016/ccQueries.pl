#!/usr/local/bin/perl 
#-d:ptkdb
use Getopt::Long;
use DBI;
use Env qw (ARCH HOME HAR_TWO_TASK HAR_REPORT_USER HAR_REPORT_PASS);
push (@INC, "$HOME/bin");
#require general_cc_func;
my $scriptname=(split /\//,$0)[-1];
my $logscriptname=(split/\./,$scriptname)[0];
my $ts=`timestamp`;
$opt_status = GetOptions( 
	'h'      => \$help,
	'con:s'  => \$conection_string,
	'v:s'    => \$version,
	'que:s'  => \$query_name,
	'opt:s'  => \$query_option,
);
&check_param;
if ($query_name eq "get_locked_file"){
	if (!$query_option ){
		$state="Development"
	}
	$query="select HI.ITEMNAME , HPF.PATHFULLNAME from HARENVIRONMENT he , HARSTATE hs , HARVERSIONS hv , HARPACKAGE hp , HARITEMS hi ,HARPATHFULLNAME hpf where HE.ENVIRONMENTNAME = 'Tasks $version' and HS.STATENAME ='$state' and HE.ENVOBJID = HS.ENVOBJID and HP.STATEOBJID = HS.STATEOBJID and HP.ENVOBJID = HE.ENVOBJID and HV.PACKAGEOBJID = HP.PACKAGEOBJID and HV.VERSIONSTATUS = 'R' and HV.ITEMOBJID = HI.ITEMOBJID and HI.PARENTOBJID =HPF.ITEMOBJID";
}elsif ($query_name eq "get_files_from_task"){
	&Usage("-opt <task name> is mandatory for get_files_from_task query") if (!$query_option);
	$query="select hi.ITEMNAME from HARENVIRONMENT	he, HARPACKAGE hp, HARSTATE	hsp, HARVERSIONS hv, HARITEMS	hi,	HARREPOSITORY hr, HARPATHFULLNAME hpf where
	( trim( he.ENVIRONMENTNAME ) like 'Tasks $version' or trim( he.ENVIRONMENTNAME ) = 'Infra' )
 and	he.ENVISACTIVE		= 'Y'
 and	hp.ENVOBJID 		= he.ENVOBJID
 and	hp.PACKAGENAME like '$query_option'
 and	hsp.STATEOBJID		= hp.STATEOBJID
 and	hv.PACKAGEOBJID 	= hp.PACKAGEOBJID
 and	hi.ITEMOBJID		= hv.ITEMOBJID
 and	hi.ITEMTYPE		!= 0
 and	hr.REPOSITOBJID		= hi.REPOSITOBJID
 and	hpf.ITEMOBJID		= hi.PARENTOBJID
 order by hp.PACKAGENAME";
 }
&db_connect;
$sth = $dbh->prepare("$query");
$sth->execute();
while ( @row = $sth->fetchrow_array ) {
   print "@row\n";
}
exit;
sub check_param {
	&Usage("you wanted help") if ($help);
	&Usage(" -v and -que are mandatory arguments") if ((!$version) || (!$query_name));
	$state="Development" if (!$state);
}
sub db_connect {
	my ($User,$Passwd,$Instance,@TmpConnection,@TmpConnection1);
	if ($conection_string){
		@TmpConnection=split /\@/,$conection_string;
		$Instance=$TmpConnection[1];
		@TmpConnection1=split /\@/,$TmpConnection[0];
		$User=$TmpConnection1[0];
		$password=$TmpConnection1[1];
	}else{
		$Instance = $HAR_TWO_TASK ;
		$User     = $HAR_REPORT_USER ;
		$Passwd   = $HAR_REPORT_PASS ;
	}
	$dsn = "dbi:Oracle:$Instance";
	$dbh = DBI->connect($dsn, $User, $Passwd,{AutoCommit=>0}) or die "Couldn't connect to database: " . DBI->errstr;
}
sub Usage { 
	my ($errormassege)=@_;
	print "\nName    : $scriptname v 1.0
        
Running quries on XtraC
          
Usage : 

-v : Tasks version ( e.g. 750 ) < mandatory >
-con : connection string e.g. harupc/harupc\@upcxtrac < not mandatory, defult is \$HAR_REPORT_USER/\$HAR_REPORT_PASS\@HAR_TWO_TASK >
-que : query name, can be one of the following : < mandatory >
	1. get_locked_file : getting list of locked files from development state. 
		-opt : state < not mandatory, development is defult > 
	2. get_files_from_task : list of files in a given task
		-opt : task name < mandatory > 

your error : $errormassege\n\n"; 
         exit;
}