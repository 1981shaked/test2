#! /usr/local/bin/perl 
#-d:ptkdb

use Env qw ( CCPRODUCT
		HOME
		CCPROJECTHOME
		HARVESTHOME
		);
use File::Basename;
use File::Copy;
use Getopt::Long;

sub Usage{
	print "
	This script creates backup for build logs to proccess by Deugger tool
	-h Help
	-Pr Product[In case of Enabler]
	-M Module[In case of Enabler]
	-v Version
	-p Project name[In case of Enabler/Ensamble]
	-vrt Variant[64/64O2/64OG]
	-T Product type[enb6/enb7/ens] 
	-cb To copy the Cobol *.lst files 
	
	invocation:
	$0 {-T <Product Type>} [{-Pr <Product> -v <Version> -vrt <Variant>}][{-M <Module> -v <Version> -vrt <Variant>}][{-p <Project> -v <Version> -vrt <Variant>}] [-h] [-cb]
	example:$0 -T enb6 -Pr lel -v v706 -vrt 64
	example:$0 -T enb6 -M cm -v v706 -vrt 64
	example:$0 -T enb6 -p ccm706 -v v706 -vrt 64
	example:$0 -T ens -p ldb0706 -v v0706 -cb
	\n";
}

my $help;
my $Product;
my $Module;
my $Version;
my $Variant;
my $opt_status;
my $ProdType;
my $cobol;
my $path="$CCPROJECTHOME/log/ccLogFreeze";

$opt_status = GetOptions( 'h:s'	=> \$help,
			  'Pr=s' => \$Product,
			  'v=s' => \$Version,
			  'M=s' => \$Module,
			  'vrt=s' => \$Variant,
			  'p=s' => \$Project,
			  'T=s' => \$ProdType,
			  'cb:s' => \$cobol,
			);

if (! defined $ProdType ){
	print "You must provide Product type\n\n\n";
	&Usage;
	exit;
}

	if (defined $help){
		&Usage;
		exit;
	}

&verifyParam;

if ( $ProdType eq "enb6"){
	print "Script is running for Amdocs6 based project \n";
	&FreezeForAmdocs6;
}else{
	if ( $ProdType eq "enb7"){
		print "Script is running for Amdocs7 based project \n";
		&FreezeForAmdocs7;
	}else{
		if ( $ProdType eq "ens"){
			print "Script is running for Ensamble based project \n";
			&FreezeForEnsamble;
		}
	}
} 

sub verifyParam{
	print "Inside the verifyParam function \n";
	local $prd_ver="$CCPROJECTHOME/product/$Product/$Version";
	local $mod="$CCPROJECTHOME/module/$Module";
	local $mod_ver="$CCPROJECTHOME/module/$Module/$Version";

	if ( defined $Product && $Product ne "lel" ){
		print "\n Invalid product name \n";
		exit;
	}
	if ( defined $Product && $Product eq "lel"){
		if (! -d $prd_ver ){
			print "\n Invalid version name \n";
			exit;
		}
	}
	if ( defined $Module && ! -d $mod && ! -d $mod_ver ){
		print "\n Invalid module name and/or version \n";
		exit;
	}

	local $tnp_proj="$HOME/proj/$Project".1;
	if ( defined $Project && -l $tnp_proj ){
		local $tmp_prj_path=`ls -l $HOME/proj/$Project.1 | cut -f2 -d"@" | cut -f3 -d" "`;
		if (! -d $tmp_prj_path ){
			print "\n Invalid project name \n";
			exit;
		}
	}
	if ( defined $Variant && ( $ProdType eq "enb6" || $ProdType eq "enb7" )){
		open (INPUTFILE, "< $CCPROJECTHOME/product/lel/$Version/config/product_variants") || die "Cannot open file $HOME/product/lel/$Version/config/product_variants";
		@var_list = <INPUTFILE>;
		close INPUTFILE;
		local @tmp_var=grep {$Variant} @var_list;
		if ( scalar(@tmp_var) < 1 ){
			print "\n Invalid variant name \n";
		}
	}
}

sub FreezeForAmdocs6{
	local $log_path="$HOME/log.product/log.lel/log.". $Version;
	chdir $log_path or die "Directory path $HOME/log.product/log.lel/log.$Veriosn doesn't exist \n";
	chomp($_ = qx!ls -lrt build_product.log.* | tail -1!);
	$TS = (split /_/, (split /\./, (split /[" "]/, $_)[19])[3])[0];
	$Full_TS = (split /\./, (split /[" "]/, $_)[20])[3];
	
        if ( !-d $path ){
                print "Creating ccLogFreeze \n";
                mkdir -p $path, 0755;
        }

	local @tmp_arr;
	
	if (defined $Product){
		if ( ! -e "$CCPROJECTHOME/bin/show_str.pl" ){
			local $local_proj_list;
			local $modbo="lel_". $Version ."_modbo.dat";
			print "MODBO:". $modbo;
			chomp($_= qx!cat $CCPROJECTHOME/product/$Product/$Version/config/$modbo | cut -f2 -d" "!);
			foreach $md($_){
				chomp($local_proj_list= qx!cat $CCPROJECTHOME/module/$md/$Version/config/module_profile | grep PROJ | cut -f2 -d"="!);
				foreach $prj($local_proj_list){
					chomp($local_bb= qx!cat $CCPROJECTHOME/proj/$prj/proj_profile | grep BB | cut -f2 -d"="!);
					foreach $bb($local_bb){
						$filler="filler1:filler2:filler3:$prj:$bb:$Version";
						push(@tmp_arr,$filler);
					}
				}
			}
		}else{
			@tmp_arr=`$show_str -P $Product -v $Version -t $Variant`;
		}
	}else{
		if ( $Module ne "" ){
			$tmp_show_str="$show_str -M $Module -v $Version -t $Varinat";
			@tmp_arr=`$tmp_show_str`;
			@tmp_arr = `$CCPROJECTHOME/bin/show_str.pl -M $Module -v $Version -t $Variant`; 
		}else{
			if ( defined $Project ){
				@tmp_arr= `$CCPROJECTHOME/bin/show_str.pl -p $Project -v $Version`;
			}else{
				&Usage;
				exit(1);
			}
		}
	}
	chdir $path or die "No such path exist \n";
	foreach $var(@tmp_arr){
		@tmp_var=split /:/ , $var;
		
		$path = "$tmp_var[4].$tmp_var[5]/$TS/$tmp_var[3].$tmp_var[4]";
		system "mkdir -p $path";
		
		local $local_source_file="$HOME/log.$tmp_var[3]/log.$tmp_var[4]/hbuild.log.$Full_TS";
		$local_desc_file=$path ."/hbuild.log";
		print "LOCAL SOURCE PATH=>". $local_source_file ."\n"; 
		copy ( $local_source_file, $local_desc_file);
		if ( $! != "" ){
			print "Error:". $! ."\n $local_source_file \n";
		}
	}
}



sub FreezeForAmdocs7{
	print "Inside the FreezeForAmdocs7 \n";
	local $local_proj;
	local $log_path="$HOME/log.product/log.lel/log.". $Version;
	chdir $log_path or die "Directory path $HOME/log.product/log.lel/log.$Veriosn doesn't exist \n";
	chomp($_ = qx!ls -lrt build_product.log.* | tail -1!);
	$TS = (split /_/, (split /\./, (split /[" "]/, $_)[20])[3])[0];
	$Full_TS = (split /\./, (split /[" "]/, $_)[20])[3];
	
        if ( !-d $path ){
                print "Creating ccLogFreeze \n";
                system("mkdir $path");
        }
	print "ccLogFreeze create \n";
	local @tmp_arr;
	local $local_show_str="$CCPROJECTHOME/bin/show_str.pl";
	if (defined $Product){
		if ( ! -e $local_show_str ){
			local @local_proj_list;
			local $modbo="lel_". $Version ."_modbo.dat";
			if (!-e $CCPROJECTHOME/product/$Product/$Version/config/$modbo ) {
				print "cant locate $CCPROJECTHOME/product/$Product/$Version/config/$modbo file\n";
				exit;
			}
			chomp(@_= qx!cat $CCPROJECTHOME/product/$Product/$Version/config/$modbo | cut -f2 -d" "!);
			print "modules = @_";
			foreach $md(@_){
				chomp(@local_proj_list7 = qx!cat $CCPROJECTHOME/module/$md/$Version/config/module_profile | grep -v PROJ | grep -v Base |cut -f1 -d" "!);
				foreach $prj(@local_proj_list7){
					$prj=$prj ."V". $Variant;
					print "prj = $prj";
					$local_proj="$CCPROJECTHOME/proj/$prj/proj_profile";
					if ( -f $local_proj ){
						chomp(@local_bb7 = qx!cat $CCPROJECTHOME/proj/$prj/proj_profile | grep -v BB | grep -v SubProjects | cut -f1 -d" "!);
						foreach $bb(@local_bb7){
							$filler="filler1:filler2:filler3:$prj:$bb:$Version";
							push(@tmp_arr,$filler);
						}
					}else{
						print $local_proj ."doesn't exist \n";
					}
				}
			}
		}else{
			@tmp_arr=`$CCPROJECTHOME/bin/show_str.pl -P $Product -v $Version -t $Variant`;
		}
	}else{
		print "Checking MODULE". $Module ." \n";
		if ( $Module ne "" ){
			print "Checking the existing of show_str.pl \n";
			if ( ! -e $local_show_str ){
				chomp(@_= qx!cat $CCPROJECTHOME/module/$Module/$Version/config/module_profile | grep -v PROJ | grep -v Base| cut -f1 -d" "!);
				for $prj(@_){
					$prj=$prj ."V". $Variant;
					$local_proj="$CCPROJECTHOME/proj/$prj/proj_profile";
					if ( -f $local_proj ){
						chomp(@local_bb = qx!cat $CCPROJECTHOME/proj/$prj/proj_profile |grep -v BB | grep -v SubProjects | cut -f1 -d" "!);
						foreach $bb(@local_bb){
	                                                $filler="filler1:filler2:filler3:$prj:$bb:$Version";
	                                                push(@tmp_arr,$filler);
	                                        }
					}
				}
			}else{
				@tmp_arr = `$CCPROJECTHOME/bin/show_str.pl -M $Module -v $Version -t $Variant`; 
			}
		}else{
			print "Project:". $Project ."\n";
			local $prj=$Project ."V". $Variant;
			local $local_proj="$CCPROJECTHOME/proj/". $Project ."V". $Variant ."/proj_profile";
			if ( defined $Project && -f $local_proj ){
				if (! -e $local_show_str ){
					chomp(@_ = qx!cat $CCPROJECTHOME/proj/$prj/proj_profile | grep -v BB | grep -v SubProjects | cut -f1 -d" "!);
					foreach $bb(@_){
						print "BBs=>". $bb ."\n";
						$filler="filler1:filler2:filler3:$prj:$bb:$Version";
						print $filler ."\n";
						push(@tmp_arr,$filler);
					} 
				}else{
					@tmp_arr= `$CCPROJECTHOME/bin/show_str.pl -p $Project -v $Version`;
				}
			}else{
				&Usage;
				exit(1);
			}
		}
	}
	print "path = $path\n";
	chdir $path or die "No such path exist \n";
	chomp (@tmp_arr);
	foreach $var(@tmp_arr){
		@tmp_var=split /:/ , $var;
		print "coping the log into $local_desc_file\n";
		local $target_path = "$tmp_var[4]/$tmp_var[5]/$TS";
		system "mkdir -p $target_path";
		local $local_source_file="$HOME/$Version/lel/Audit/proj/log.$tmp_var[3]/log.$tmp_var[4]/hbuild.log.$Full_TS";
		$local_desc_file=$target_path ."/hbuild.log.$Full_TS";
		copy ( $local_source_file, $local_desc_file);
		if ( $! != "" ){
			print "Error:". $! ."\n";
		}
	}

}

sub FreezeForEnsamble{
	print "Inside the Ensamble \n";
	local @tmp_arr;
	local $prj=$Project;
	local $log_path="$CCPROJECTHOME/log.$prj";
	chdir $log_path or die "Directory path ". $log_path ."doesnot exist \n";
	chomp($_ = qx!ls -lrt *build.log* | tail -1!);

	$TS = (split /_/, (split /\./, (split /[" "]/, $_)[23])[2])[0];
	$Full_TS = (split /\./, (split /[" "]/, $_)[23])[2];
	if ( !-d $path ){
                print "Creating ccLogFreeze \n";
                system("mkdir -p $path");
        }
	print "ccLogFreeze create \n";

	local $local_proj_file="$CCPROJECTHOME/proj/$Project/proj_profile";
	if ( -f $local_proj_file ){
		chomp(@_ = qx!cat $local_proj_file | grep -v BB | grep -v SubProjects | cut -f1 -d" "!);
		foreach $bb(@_){
			$filler="filler1:filler2:filler3:$prj:$bb:$Version";
			push(@tmp_arr,$filler); 
		}
	}else{
		print "Cann't procced:". $! ."\n";
		exit(1); 
	}
	
	foreach $var(@tmp_arr){
		@tmp_var=split /:/ , $var;
		local $target_path = "$tmp_var[4].$tmp_var[5]/$TS/$tmp_var[3].$tmp_var[4]";
		chdir $path or die "No such path exist \n";
		system "mkdir -p $target_path";
		if ( defined $cobol ){
			local @arr_lst;
			local $deb_path="$CCPROJECTHOME/proj/$tmp_var[3]/$tmp_var[4]";
			chdir $deb_path or die "No such path exist \n";
			chomp(@arr_lst = qx!find . -name "*.lst"!);
			if ( $! == ""){
				print "$! =>0 \n";
				foreach $file(@arr_lst){
					print $file ."\n";
					$file=`echo $file | cut -f2 -d"/"`;
					local $dest_file=$path ."/". $target_path ."/". $tmp_var[3] ."\.". $tmp_var[4] ."\.". $file;
					print system("ls -lrt $file");
					copy ( $file, $dest_file);
					if ( $! != "" ){
						print "Error:". $! ."\n";
					}
				}
			}
		}
		local $local_source_file="$CCPROJECTHOME/log.$tmp_var[3]/log.$tmp_var[4]/build.log.$Full_TS";
		$local_desc_file=$target_path ."/hbuild.log";
		chdir $path or die "No such path exist \n";
		copy ( $local_source_file, $local_desc_file);
		#if ( $! != "" ){
		#	print "Error:". $! ."\n";
		#}
	}
} 
