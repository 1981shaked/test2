#!/usr/local/bin/perl

# Author: Khalil Jiries
# Desk:   Script to combine schema during CC build and upgrade master DB



# flush STDOUT/STDERR buffer
$| = 1;

# The script version
$UPGRADE_SCHEMA_VER = "2.0";
$ScriptName = (split (/\// , $0))[-1];

if (! defined ($ENV{"SCHEMA_MGR_HOME"}))
{
	&printErr ("Environment variable 'SCHEMA_MGR_HOME' must be defined!\n\n");
    exit 1;
}

if (! defined ($ENV{"SCHEMA_MGR_CLASS_PATH"}))
{
	&printErr ("Environment variable 'SCHEMA_MGR_CLASS_PATH' must be defined!\n\n");
    exit 1;
}

$SCHEMA_MGR_HOME = $ENV{"SCHEMA_MGR_HOME"};
$SCHEMA_MGR_CLASS_PATH = $ENV{"SCHEMA_MGR_CLASS_PATH"};

push (@INC, "$SCHEMA_MGR_HOME");

print ("\n");

$ccDir = "";
$userDir = "";
$outputSchemaFile = "";
$xsdPath = "";
$validationClasses = "";
$upgradeDbInd = 0;
$deleteViewsInd = 0;
$serverName = "";
$crmDb = "";
$dbUser = "";
$dbPass = "";
$mailList = "";
$mailServer = "";
$dbBackupDir = "";
$dataexPath = "";
$dbHost = "";

# Analizing options passed to the script.
if (! &analyzeOptions (\$ccDir, \$userDir, \$outputSchemaFile, \$xsdPath, \$validationClasses,
					\$upgradeDbInd, \$deleteViewsInd, \$serverName, \$crmDb, \$dbUser, \$dbPass, 
					\$mailList, \$mailServer, \$dbBackupDir, \$dataexPath, \$dbHost))
{
	&usage ();
	exit 1;
}

# Run Init & basic validations
if ($st = &init ($ccDir, $userDir, $outputSchemaFile, $xsdPath, $validationClasses, $mailList, $upgradeDbInd, $dbBackupDir, $dataexPath))
{
	&printErr ("Error occurred at the init phase! $st.\n\n");
	exit 1;
}

if ($upgradeDbInd) # Send mail on starting DB schema upgrade
{
	$mailSubj = "About to upgrade schema of DB $crmDb";
	@mailMsg = ();
	push (@mailMsg, "Hi All,\n\n");
	push (@mailMsg, "Schema of DB \"$crmDb\" is about to be upgarded.\n\n");
	push (@mailMsg, "Please stop any activities on the DB.");
	if ($st = &sendMail ("SchemaManager\@amdocs.com" , [split (/;/, $mailList)] , [] , $mailSubj, \@mailMsg , [], $mailServer))
	{
		&printErr ("Couldn't send mail! $st.\n");
		exit 1;
	}
}

# Combine schema
if ($st = &RunSchemaCombine ($ccDir, $userDir, $outputSchemaFile, $xsdPath, $validationClasses))
{
	&printErr ("Couldn't combine schema! $st.\n");
	
	if ($upgradeDbInd)
	{
		$mailSubj = "Schema upgrade for DB $crmDb FAILED!";
		@mailMsg = ();
		push (@mailMsg, "Hi All,\n\n");
		push (@mailMsg, "Failed to upgrade Schema of DB \"$crmDb\"!\n");
		push (@mailMsg, "Reason: Couldn't combine schema! $st.");
		if ($st = &sendMail ("SchemaManager\@amdocs.com" , [split (/;/, $mailList)] , [] , $mailSubj, \@mailMsg , [], $mailServer))
		{
			&printErr ("Couldn't send mail! $st.\n");
		}
	}
	
    exit 1;
}

# Backup DB before schema upgrade
if ($upgradeDbInd)
{
	$dbAcc = $dbUser . "/" . $dbPass . "\@" . $crmDb;
	$dmpFile = $dbBackupDir . "/" . $crmDb . "_Backup_Schema_Upgrade_" . &timeStamp() . ".dmp";
	
	print ("\n" . &timeStamp() . ": Creating backup for DB \"$crmDb\". Dump file \"$dmpFile\".\n");
	
	if ($st = &exportOraDB($dbAcc, $dmpFile, "", ""))
	{
		&printErr ("Failed to export and backup DB \"$crmDb\"! $st\n.");
		
		if ($upgradeDbInd)
		{
			$mailSubj = "Schema upgrade for DB $crmDb FAILED!";
			@mailMsg = ();
			push (@mailMsg, "Hi All,\n\n");
			push (@mailMsg, "Failed to upgrade Schema of DB \"$crmDb\"!\n");
			push (@mailMsg, "Reason: Failed to export and backup DB \"$crmDb\"! $st.");
			if ($st = &sendMail ("SchemaManager\@amdocs.com" , [split (/;/, $mailList)] , [] , $mailSubj, \@mailMsg , [], $mailServer))
			{
				&printErr ("Couldn't send mail! $st.\n");
			}
		}
		
	    exit 1;
	}
}

# Upgrade DB with new schema
if ($upgradeDbInd)
{
	if ($st = &upgradeSchema($outputSchemaFile, $serverName, $crmDb, $dbUser, $dbPass, $deleteViewsInd, $xsdPath, $validationClasses, $dataexPath, $dbHost))
	{
		&printErr ("Failed to upgrade DB schema for \"$crmDb\"! $st\n.");

		$mailSubj = "Schema upgrade for DB $crmDb FAILED!";
		@mailMsg = ();
		push (@mailMsg, "Hi All,\n\n");
		push (@mailMsg, "Failed to upgrade Schema of DB \"$crmDb\"!\n");
		push (@mailMsg, "Reason: OOB Schema Manager failed to upgrade schema! $st.");
	}
	else
	{
		$mailSubj = "Schema upgrade for DB $crmDb ended SUCCESSFULLY";
		@mailMsg = ();
		push (@mailMsg, "Hi All,\n\n");
		push (@mailMsg, "Schema of DB \"$crmDb\" was upgraded successfully with schema file \"$outputSchemaFile\".\n");
		push (@mailMsg, "You can proceed your work on the DB.");
	}
	
	
	if ($st = &sendMail ("SchemaManager\@amdocs.com" , [split (/;/, $mailList)] , [] , $mailSubj, \@mailMsg , [], $mailServer))
	{
		&printErr ("Couldn't send mail! $st");
	}
}

print ("\n");
exit 0;


sub upgradeSchema
{
	local ($schemaFile, $serverName, $crmDb, $dbUser, $dbPass, $deleteViewsInd, $xsdPath, $validationClasses, $dataexPath, $dbHost) = @_;
	local ($cmd, $st, $exitSts, @outputArr, $mailSubj, @mailMsg);
	
	$cmd = "java -cp \"$SCHEMA_MGR_CLASS_PATH\" -Xms64m -Xmx1024m -DdbUser=$dbUser -DdbPass=$dbPass -DdbServer=$serverName -DdbName=$crmDb -DdbType=oracle -DschemaFile=\"$schemaFile\" -DdataexPath=\"$dataexPath\"";
	
	if (defined ($xsdPath))
	{
		$cmd .= " -DxsdFile=$xsdPath";
	}
	
	if (defined ($validationClasses))
	{
		$cmd .= " -DvalidationClasses=$validationClasses";
	}
	
	if ($deleteViewsInd)
	{
		$cmd .= " -DdeleteViews=true -DdbHost=$dbHost";
	}
	
	$cmd .= " com.clarify.schemamgr.SchemaUpgrade";
	
	print ("\n" . &timeStamp() . ": Running Schema Upgrade command: \"$cmd\"\n");
	
	if ($st = &runShCmd ($cmd, \$exitSts, \@outputArr, 1))
    {
        return "Couldn't run \"$cmd\"! $st";
    }
    
    if ($exitSts != 0)
    {
    	return "Schema Upgrade ended with exit status \"$exitSts\"!";
    }
    
    return "";
}


sub RunSchemaCombine
{
	local ($ccDir, $userDir, $outputSchemaFile, $xsdPath, $validationClasses) = @_;
	local ($cmd, $st, $exitSts, @outputArr, $mailSubj, @mailMsg);
	
	$cmd = "java -cp \"$SCHEMA_MGR_CLASS_PATH\" -Xms64m -Xmx1024m -DOutputSchemaFile=$outputSchemaFile -DCcDirectory=$ccDir";
	if (defined ($userDir))
	{
		$cmd .= " -DUserDirectory=$userDir";
	}
	
	if (defined ($xsdPath))
	{
		$cmd .= " -DXsdFile=$xsdPath";
	}
	
	if (defined ($validationClasses))
	{
		$cmd .= " -DValidationClasses=$validationClasses";
	}
	
	$cmd .= " com.clarify.schemamgr.SchemaCombine";
	
	print ("\n" . &timeStamp() . ": Running Schema Combine command: \"$cmd\"\n");
	
	if (-f $outputSchemaFile)
	{
		print "Output schema file already exists, deleting it...\n";
		if (! unlink($outputSchemaFile))
		{
			return "Couldn't remove the file \"$outputSchemaFile\"! $!";
		}
	}
	
	if ($st = &runShCmd ($cmd, \$exitSts, \@outputArr, 1))
    {
        return "Couldn't run \"$cmd\"! $st";
    }
    
    if ($exitSts != 0)
    {
    	return "Schema Combine ended with exit status \"$exitSts\"!";
    }
    
    return "";
}


sub init
{
	local ($ccDir, $userDir, $outputSchemaFile, $xsdPath, $validationClasses, $mailList, $upgradeDbInd, $dbBackupDir, $dataexPath) = @_;
	
	if (! -d $ccDir)
	{
		return $ccDir . ": is not a directory";
	}
	
	if (defined($userDir))
	{
		if (! -d $userDir)
		{
			return $userDir . ": is not a directory";
		}
	}
	
	if (defined($xsdPath) && ! -f $xsdPath)
	{
		return "XSD file \"$xsdPath\" doesn't exists";
	}
	
	print "SCHEMA_MGR_CLASS_PATH = $SCHEMA_MGR_CLASS_PATH \n\n";
	
	if ($mailList ne "" && $mailList !~ /^((.+?;)?([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?);?){1,}$/i)
	{
		return "Invalid email address \"$mailList\"";
	}
	
	if ($upgradeDbInd)
	{
		if (! -d $dbBackupDir)
		{
			return "Invalid DB backup directory address \"$dbBackupDir\"";
		}
		
		if (! -e $dataexPath)
		{
			return "Invalid dataex path/file \"$dataexPath\"";
		}
	}
	
	return "";
}


# Analyze options passed to the script.
sub analyzeOptions
{
	local ($ccDirRef, $userDirRef, $outputSchemaFileRef, $xsdPathRef, $validationClassesRef,
			$upgradeDbIndRef, $deleteViewsIndRef, $serverNameRef, $crmDbRef, $dbUserRef, $dbPassRef, 
			$mailListRef, $mailServerRef, $dbBackupDirRef, $dataexPathRef, $dbHostRef) = @_;

	&Getopts ("c:u:o:x:v:s:d:r:p:e:m:b:t:z:lgh");

	if (defined ($opt_h))
	{
		return 0;
	}
	
	if (! defined ($opt_c) || ! defined ($opt_o))
	{
		&printErr ("You must specify \"-c\" and \"-o\" options.\n");
		return 0;
	}

	$$ccDirRef = $opt_c;

	if (defined ($opt_u))
	{
		$$userDirRef = $opt_u;
	}
	else
	{
		$$userDirRef = undef;
	}
	
	$$outputSchemaFileRef = $opt_o;
	
	if (defined ($opt_x))
	{
		$$xsdPathRef = $opt_x;
	}
	else
	{
		$$xsdPathRef = undef;
	}
	
	if (defined ($opt_v))
	{
		$$validationClassesRef = $opt_v;
	}
	else
	{
		$$validationClassesRef = undef;
	}
	
	$$upgradeDbIndRef = 0;
	$$deleteViewsIndRef = 0;
	
	if (defined ($opt_g))
	{
		$$upgradeDbIndRef = 1;
		
		if (! defined ($opt_s) || ! defined ($opt_d) || ! defined ($opt_r) || ! defined ($opt_p) || ! defined ($opt_b) || ! defined ($opt_t))
		{
			&printErr ("When specifying \"-g\" you must specify \"-s\" and \"-d\" and \"-r\" and \"-p\" and \"-b\" and \"-t\" options.\n");
			return 0;
		}
		
		$$serverNameRef = $opt_s;
		$$crmDbRef = $opt_d;
		$$dbUserRef = $opt_r;
		$$dbPassRef = $opt_p;
		$$dbBackupDirRef = $opt_b;
		$$dataexPathRef = $opt_t;
		
		if (defined ($opt_l))
		{
			$$deleteViewsIndRef = 1;
			
			if (! defined ($opt_z))
			{
				&printErr ("When specifying \"-l\" you must specify \"-z\" option.\n");
				return 0;
			}
			
			$$dbHostRef = $opt_z;
		}
		
		if (defined ($opt_e))
		{
			$$mailListRef = $opt_e;
			
			if (! defined ($opt_m))
			{
				&printErr ("When specifying \"-e\" you must specify \"-m\" option.\n");
				return 0;
			}
			
			$$mailServerRef = $opt_m;
		}
	}
	
	return 1;
}


# Print usage
sub usage
{
	print ("\nUsage:\n");
	print ("\t$ScriptName -c <CC Dir> [-u <User Dir>] -o <Output Schema File> [-x <XSD File>] [-v <Validation Java Classes>]\n");
	print ("\t			  [-g -s <Server Name> -d <CRM DB> -r <User> -p <Pass> [-l -z <DB Host Server>] [-e <Mailing List> -m <Mail Server List>]\n");
	print ("\t			  [-b <DB Backup Dir>] -r <dataex path>] [-h]\n\n");
	print ("\t-c:		CC directory where all schema files are located.\n");
	print ("\t-u:		User directory where private schema files are located.\n");
	print ("\t-o:		Location for output schema file.\n");
	print ("\t-x:		Location of schema XSD file.\n");
	print ("\t-v:		List of validation Java classes.\n");
	print ("\t-g:		Indicated whether to upgrade a given DB with the generated schema. It requires DB parameters to be populated.\n");
	print ("\t-s:		DB Server Name.\n");
	print ("\t-d:		CRM Database.\n");
	print ("\t-r:		DB user.\n");
	print ("\t-p:		DB password.\n");
	print ("\t-l:		Delete all views prior schema upgrade.\n");
	print ("\t-z:		The server name running the DB.\n");
	print ("\t-e:		Mailing list for notification prior schema upgrade (MailAddr1@Server;MailAddr2@Server;...).\n");
	print ("\t-m:		SMTP Mail Server list (MailServer1;MailServer2;...).\n");
	print ("\t-b:		DB Backup Directory.\n");
	print ("\t-t:		dataex path.\n");
	print ("\t-h:		Show usage.\n\n");
	print ("\tThis is version \"$UPGRADE_SCHEMA_VER\" of \"$ScriptName\" script.\n\n");
}


sub runShCmd
{
        local ($cmd, $exitStsRef, $outputArrRef, $stdOut) = @_;
        local (*PIPE);
        
        $$exitStsRef = 0;
        @{$outputArrRef} = ();
        
        if (! open (PIPE , "$cmd 2>&1 |"))
        {
                return "Couldn't open pipe to command \"$cmd\"! $!";
        }
        
        if ($stdOut)
        {
                while ($l = <PIPE>)
                {
                        print $l;
                        chomp ($l);
                        push (@{$outputArrRef}, $l);
                }
        }
        else
        {       
                chomp (@{$outputArrRef} = <PIPE>);
        }
        
        close (PIPE);
        
        $$exitStsRef = $?/256;
        
        return "";
}


# Usage:
#      do Getopts('a:bc');  # -a takes arg. -b & -c not. Sets opt_* as a
#                           #  side effect.
# Updated by Mahdy Hijazy 15/08/2001 
# adding option to have flags that can have argument or just to be defined
# for example -o or -o 20010814 can be supported, all flags whith ',' are flags that can be 
# with or without argument.
# in this case you can call the function like this: Getopts('p:d:b:F:t:l:o,eiah'); 

sub Getopts 
{
    	local($argumentative) = @_;
    	local(@args,$_,$first,$rest);
    	local($errs) = 0;
    	local($[) = 0;

    	@args = split( / */, $argumentative );
    	while(@ARGV && ($_ = $ARGV[0]) =~ /^-(.)(.*)/) 
    	{
		($first,$rest) = ($1,$2);
		$pos = index($argumentative,$first);
		if($pos >= $[) 
		{
	    		if($args[$pos+1] eq ':') 
	    		{
				shift(@ARGV);
				if($rest eq '') 
				{
		    			++$errs unless @ARGV;
		    			$rest = shift(@ARGV);
				}
				eval "\$opt_$first = \$rest;";
	    		}
	    		elsif($args[$pos+1] eq ',')
	    		{
	    			shift(@ARGV);
				if($ARGV[0] =~ /^-(.*)/ || @ARGV == 0) 
				{
					eval "\$opt_$first = 1";
		    			
				}
				else{
					$rest = shift(@ARGV);
					eval "\$opt_$first = \$rest;";
				}
	    		}
	    		else 
	    		{
				eval "\$opt_$first = 1";
				if($rest eq '') 
				{
		    			shift(@ARGV);
				}
				else 
				{
		    			$ARGV[0] = "-$rest";
				}
	    		}
		}
		else 
		{
	    		print STDERR "Unknown option: $first\n";
	    		++$errs;
	    		if($rest ne '') 
	    		{
				$ARGV[0] = "-$rest";
	    		}
	    		else 
	    		{
				shift(@ARGV);
	    		}
		}
    	}
    	$errs == 0;
}


# Description: 	this function print the error message passed to it to STDERR in the format:
#			Error [FileName:SubName:LineNumber]: ErrMess
#		When:	       
#			FileName   : the files where printErr was called.
#	       		SabName    : the subroutine that called printErr.
#			LineNumber : where printErr was called (at FileNAme).

# Input : Error message.
# Return: 1.

sub printErr
{
	local ($err) = @_;
	local ($packName , $fileName , $lineNum) = caller;
	local ($subName) = (caller(1))[3] || 'main';
        	
	print STDERR ("Error [${fileName}::${subName}::${lineNum}]: $err");
	return 1;
}


################################################################
# Name    : timeStamp
# Purpose : return a string of the time
# Return  : String in the format : YYMMDD_hhmmss
################################################################
sub timeStamp  
{
	local ($sec , $min , $hour , $mday , $mon , $year , $wday , $yday , $isdst);
        
        ($sec , $min , $hour , $mday , $mon , $year , $wday , $yday , $isdst) = localtime (time);
        $year = $year + 1900;
        $mon  = $mon  + 1;
        if ($mon == 13)
        {
                $mon  = 1;
                $year = $year + 1;
        }

        return sprintf("%04d%02d%02d_%02d%02d%02d" , $year , $mon , $mday , $hour , $min , $sec);              
}


# Send Mail method
sub sendMail
{
	local ($sender , $toRef , $ccRef , $subject , $messRef , $filesRef, $mailServers) = @_;
	local (%mail , $to , $cc , $message , $boundary , $file , *F , $st);
	
	if ($st = &passiveUse ("Mail::Sendmail"))
	{
		return "Couldn't use \"Mail::Sendmail\"! $st";
	}
	
	if ($st = &passiveUse ("MIME::QuotedPrint"))
	{
		return "Couldn't use \"MIME::QuotedPrint\"! $st";
	}
	
	if ($st = &passiveUse ("MIME::Base64"))
	{
		return "Couldn't use \"MIME::Base64\"! $st";
	}
	
	$Mail::Sendmail::mailcfg{'smtp'} = [split (/;/, $mailServer)];
        
        $to = join ("," , @{$toRef});
        $cc = join ("," , @{$ccRef});
        $message = join ("", @{$messRef});
        
	%mail = (
                	from => "$sender",
                	to => $to,
                	cc => $cc,
                	subject => "$subject",
                	message => "$message\n",
                );

        $boundary = "====" . time() . "====";
        $mail{'content-type'} = "multipart/mixed; boundary=\"$boundary\"";
        $boundary = '--'.$boundary;

        $mail{body} = "$boundary\nContent-Type: text/plain; charset=\"iso-8859-1\"\nContent-Transfer-Encoding: quoted-printable\n\n";
        $mail{body} .= encode_qp ($mail{message});

        foreach $file (@{$filesRef})
        {
                $mail{body} .= "$boundary\n";
                $mail{body} .= "Content-Type: application/octet-stream; name=\"$file\"\nContent-Transfer-Encoding: base64\nContent-Disposition: attachment; filename=\"" . basename ($file) . "\"\n\n";
                open (F , $file) or return "Couldn't open the file \"$file\" for input! $!";
                binmode (F); undef ($/);
                $mail{body} .= encode_base64 (<F>);
                close (F);
        }
        
        $mail{body} .= "\n$boundary--\n";

	$st = "";
	if (! sendmail(%mail))
	{
		chop ($st = $Mail::Sendmail::error);
	}
        
        return $st;
}


sub passiveUse
{
	local ($module) = @_;
	
	eval ("use $module");
	chomp ($@);
	return $@ if ($@);
	return "";
}

# Method to export oracle DB
sub exportOraDB
{
	local ($accountName , $dmpFile , $tablesList , $flags) = @_;
	local ($st , $exitSts, $cmd, @outputArr, @tmp);
		
	print ("\nAbout to export $accountName...\n\n");
    
    if ($tablesList ne "")
    {
    	$cmd = "$ENV{'ORACLE_HOME'}/bin/exp $accountName file=$dmpFile tables=$tablesList $flags < /dev/null";
    }
    else
    {
    	$cmd = "$ENV{'ORACLE_HOME'}/bin/exp $accountName file=$dmpFile $flags < /dev/null";
    }
    
    if ($st = &runShCmd ($cmd, \$exitSts, \@outputArr, 1))
    {
        return "Couldn't run \"$cmd\"! $st";
    }
    
   	@tmp = grep (/Export terminated successfully/i, @outputArr);
   	if  (! @tmp)
   	{
   		return "Export terminated unsuccessfully for \"$accountName\"";
   	}
    
	if (! -e $dmpFile)
	{
		return "The export didn't create the dump file \"$dmpFile\"";
	}
	
	$status = system ("gzip -f $dmpFile");
	if ($status == 0 || $status == 2)
	{
		print "The file \"$dmpFile\" was compressed successfully by gzip.\n";
	}
	else
	{
		&printErr ("Failed to compress the file \"$dmpFile\" by gzip.\n");
	}
	
	return "";
}