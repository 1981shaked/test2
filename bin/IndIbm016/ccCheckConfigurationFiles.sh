#! /usr/local/bin/tcsh -f
##################################################################################################################
# Name   : ccCheckConfigurationFiles.sh 						   
# Purpose:									   	
#	1. Run refresh on Infra files
#	2. Create the SDK link based on the previous link			   
#	3. Ask for permission and then it copies the non XtraC configuration files that are under the data folder   
#	4. Compare Configuration files between two versions 			   
#		(product, comp, module, project)
#	   If a file not found is asking for permission to copy.
#										   	
# Usage / Examples:								   
#	ccCheckConfigurationFiles.sh <product> <Source version> <target version> <variant> 
#	ccCheckConfigurationFiles.sh lel v65_0 v66_0 64		           
#										   
# Dependencies (files and scripts):						   
#		1. $HOME/bin/ccRefreshConfigFile					   
#									           	
# Author:        Nikoletta Sirivianou 						   
# Supervisor:    Einat Wizeman, Tal Gedanken Katz				   
# Created Date:          09/2008						           	
# Updated Date:          02/2009						           	
####################################################################################################################
#Variables Initialization 
set product = $1
set old_ver_bb = $2
set new_ver_bb = $3
set var = $4
set ts = `timestamp`
set answer="Default"

set bb_tmp1 = `echo $old_ver_bb |cut -d _ -f  2-`
set bb_tmp2 = `echo $new_ver_bb |cut -d _ -f  2-`
set old_ver_proj1 = `echo $old_ver_bb | cut -d _ -f 1`$bb_tmp1 #vXXX
set new_ver_proj1 = `echo $new_ver_bb | cut -d _ -f 1`$bb_tmp2 #vXXX
set old_ver_proj = `echo $old_ver_proj1 | cut -d v -f 2` #XXX
set new_ver_proj = `echo $new_ver_proj1 | cut -d v -f 2` #XXX

if ("X${var}" == "X") then
   echo "\n\tError:\n"
   echo "\t\t`basename $0` <product> <source version> <target version> <variant> \n"
   echo "\t\t`basename $0` lel v65_0 v66_0 64\n"
   exit(1)
endif
if ("X${old_ver_bb}" == "X${new_ver_bb}") then
   echo "\n\tError:\n"
   echo "\t\tYour Source version with the Target one are the same.\n"
   exit(1)
endif


if (! -d "$HOME/log/ccChkConf") then
    mkdir -p "$HOME/log/ccChkConf"
endif
set LOG = $HOME/log/ccChkConf/ccChkConf_log.${ts}
touch $LOG

echo "\nChecking Differences between: Source version=$old_ver_bb and Target version=$new_ver_bb"
echo "---------------------------------------------------------------------------"
echo "\nChecking Differences between: Source version=$old_ver_bb and Target version=$new_ver_bb" >> $LOG
echo "---------------------------------------------------------------------------" >> $LOG

###############
# Run Refresh #
###############
echo "\nCurrently running the Refresh on Infra files..."
echo "\n*************************" >> $LOG
echo "*Run Refresh Infra files*" >> $LOG
echo "*************************\n" >> $LOG
$HOME/bin/ccRefreshConfigFile $new_ver_proj $product a >> $LOG
echo "-------------------------"


#######################
# Create the SDK Link #
#######################
if ( -d "$SDKHOME") then
	echo "\nSDK Link"
	echo "-----------"
	cd $SDKHOME
	
	if ("$product" == "lel") then
		set sdkRSource=ABP${old_ver_proj}
		set sdkRTarget=ABP${new_ver_proj}
	else
		set sdkRSource=${product}${old_ver_proj}
		set sdkRTarget=${product}${new_ver_proj}
	endif
	echo "Source SDKRELEASE name:\t $sdkRSource "
	echo "Target SDKRELEASE name:\t $sdkRTarget "
	#Find the source ling
	set linS = `ls -lFad $sdkRSource`
	set linS1 = `echo $linS | cut -d '>' -f 2- | sed "s/ //g"`
	set linSo = `ls -d $sdkRSource`
	set linTa = `echo $linSo | sed "s/$old_ver_proj/$new_ver_proj/g" | sed "s/\///g"`
	#Check for the Target ling if any
	set linT = ""
	if ( -l $sdkRTarget) then	
		set linT = `ls -lFad $sdkRTarget`
		set linT1 = `echo $linT | cut -d '>' -f 2- | sed "s/ //g"`
		set linT2 = `ls -d $sdkRTarget`
		set linT2a = `echo $linT2 | sed "s/\///g"`
	endif
	echo "\nCreating the SDK Link..."
	echo "\n***********************" >> $LOG
        echo "*Creating the SDK Link*" >> $LOG
	echo "***********************\n" >> $LOG
	
	if ( "X${linT}" == "X" ) then
		ln -s $linS1 $linTa
		echo "SDK Link $linTa now is linking to:\t$linS1"  >> $LOG
		echo "-------------------------------------------\n" >> $LOG
	else
		echo "SDK Link $linT2a was linking to:   \t$linT1" >> $LOG
		rm -f $linT2a
		ln -s $linS1 $linT2a
		echo "SDK Link $linT2a now is linking to:\t$linS1"  >> $LOG
                echo "-------------------------------------------\n" >> $LOG
	endif	
endif

################################################################
# Copy the files under data that are specific for each version #
################################################################
echo "\nChecking the Configuration files under the data folder"
echo "--------------------------------------------------------"
echo "\n********************************************************" >> $LOG
echo "*Checking the Configuration files under the data folder*" >> $LOG
echo "********************************************************\n" >> $LOG
while ( "X${answer}" != "XY" && "X${answer}" != "XN")
	echo "\tDo you want to copy the configuration files under the data folder? ( Y or N ): "
	set answer=$<
end
if ("X${answer}" == "XY") then
	if (! -d "$HOME/v${old_ver_proj}/$product/data") then
		echo "\nChecking files under $HOME/data"
		echo "\nChecking files under $HOME/data" >> $LOG

		cd $HOME/data
		echo "Copy the .ini files"
		echo "Copy the .ini files" >> $LOG
		foreach x (`ls *${old_ver_proj}V${var}.ini`)
			set y = `echo $x |sed "s/$old_ver_proj/$new_ver_proj/g"`
			if (-f $y) then
				echo "Creating a backup of $y file"
				echo "Creating a backup of $y file" >> $LOG
				cp -f $y ${y}.bk.${ts}
			endif
			cp -f $x $y
			perl -pe "s/$old_ver_bb/$new_ver_bb/g" -pi $y
			perl -pe "s/$old_ver_proj/$new_ver_proj/g" -pi $y
		end
	else
		if (! -d "$HOME/v${new_ver_proj}/$product/data") then
			echo "\nCreating the directory ~/v${new_ver_proj}/$product/data"
			echo "\nCreating the directory ~/v${new_ver_proj}/$product/data" >> $LOG
			mkdir -p "$HOME/v${new_ver_proj}/$product/data"
		else
			echo "\nTaking a backup of the folder ~/v${new_ver_proj}/$product/data"
			echo "\nTaking a backup of the folder ~/v${new_ver_proj}/$product/data" >> $LOG
			cd $HOME/v${new_ver_proj}/$product/
			/usr/bin/tar -cvf ${new_ver_proj}_data.${ts}.tar $HOME/v${new_ver_proj}/$product/data
		endif

		cd $HOME/v${old_ver_proj}/$product/data
		echo "Copy the files from v${old_ver_proj}/$product/data to v${new_ver_proj}/$product/data/"
		echo "Copy the files from v${old_ver_proj}/$product/data to v${new_ver_proj}/$product/data/" >> $LOG
		foreach x (`ls`)
			echo "\t$x"
			set y = `echo $x |sed "s/$old_ver_proj/$new_ver_proj/g"`
			cp -f $x $HOME/v${new_ver_proj}/$product/data/$y
			perl -pe "s/$old_ver_bb/$new_ver_bb/g" -pi $HOME/v${new_ver_proj}/$product/data/$y
			perl -pe "s/$old_ver_proj/$new_ver_proj/g" -pi $HOME/v${new_ver_proj}/$product/data/$y
		end
	endif
	if ( -f cc_local.dat.v${old_ver_proj} ) then
		if (-f cc_local.dat.v${new_ver_proj}) then
			echo "Creating a backup of cc_local.dat.v${new_ver_proj} file"
			echo "Creating a backup of cc_local.dat.v${new_ver_proj} file" >> $LOG
			cp -f cc_local.dat.v${new_ver_proj} cc_local.dat.v${new_ver_proj}.bk.${ts}
		endif
		echo "Copy the cc_local.dat.v${old_ver_proj} to cc_local.dat.v${new_ver_proj} file"
		echo "Copy the cc_local.dat.v${old_ver_proj} to cc_local.dat.v${new_ver_proj} file" >> $LOG
		cp -f cc_local.dat.v${old_ver_proj} cc_local.dat.v${new_ver_proj}
		perl -pe "s/$old_ver_bb/$new_ver_bb/g" -pi cc_local.dat.v${new_ver_proj}
		perl -pe "s/$old_ver_proj/$new_ver_proj/g" -pi cc_local.dat.v${new_ver_proj}
	endif
	if ( -f cc_local.dat.v${old_ver_proj}.${product} ) then
		if (-f cc_local.dat.v${new_ver_proj}.${product}) then
			echo "Creating a backup of cc_local.dat.v${new_ver_proj}.${product} file"
			echo "Creating a backup of cc_local.dat.v${new_ver_proj}.${product} file" >> $LOG
			cp -f cc_local.dat.v${new_ver_proj}.${product} cc_local.dat.v${new_ver_proj}.${product}.bk.${ts}
		endif
		echo "Copy the cc_local.dat.v${old_ver_proj}.${product} to cc_local.dat.v${new_ver_proj}.${product} file"
		echo "Copy the cc_local.dat.v${old_ver_proj}.${product} to cc_local.dat.v${new_ver_proj}.${product} file" >> $LOG
		cp -f cc_local.dat.v${old_ver_proj}.${product} cc_local.dat.v${new_ver_proj}.${product}
		perl -pe "s/$old_ver_bb/$new_ver_bb/g" -pi cc_local.dat.v${new_ver_proj}.${product}
		perl -pe "s/$old_ver_proj/$new_ver_proj/g" -pi cc_local.dat.v${new_ver_proj}.${product}
	endif
	if ( -f name_mask.set_up.v${old_ver_proj} ) then
		if (-f name_mask.set_up.v${new_ver_proj}) then
			echo "Creating a backup of name_mask.set_up.v${new_ver_proj} file"
			echo "Creating a backup of name_mask.set_up.v${new_ver_proj} file" >> $LOG
			cp -f name_mask.set_up.v${new_ver_proj} name_mask.set_up.v${new_ver_proj}.bk.${ts}
		endif
		echo "Copy the name_mask.set_up.v${old_ver_proj} to name_mask.set_up.v${new_ver_proj} file"
		echo "Copy the name_mask.set_up.v${old_ver_proj} to name_mask.set_up.v${new_ver_proj} file" >> $LOG
		cp -f name_mask.set_up.v${old_ver_proj} name_mask.set_up.v${new_ver_proj}
		perl -pe "s/$old_ver_bb/$new_ver_bb/g" -pi name_mask.set_up.v${new_ver_proj}
		perl -pe "s/$old_ver_proj/$new_ver_proj/g" -pi name_mask.set_up.v${new_ver_proj}
	endif
	if ( -d "$HOME/data/Ident/") then
		cd $HOME/data/Ident
		if (-f VerIdentInfo.${new_ver_proj}.ini) then
			echo "Creating a backup of VerIdentInfo.${new_ver_proj}.ini file"
			echo "Creating a backup of VerIdentInfo.${new_ver_proj}.ini file" >> $LOG
			cp -f VerIdentInfo.${new_ver_proj}.ini VerIdentInfo.${new_ver_proj}.ini.bk.${ts}
		endif
		if (-f VerIdentInfo.${old_ver_proj}.ini) then
			echo "Copy the files under data/Ident/"
			echo "Copy the files under data/Ident/" >> $LOG
			cp -f VerIdentInfo.${old_ver_proj}.ini VerIdentInfo.${new_ver_proj}.ini
			perl -pe "s/$old_ver_bb/$new_ver_bb/g" -pi VerIdentInfo.${new_ver_proj}.ini
			perl -pe "s/$old_ver_proj/$new_ver_proj/g" -pi VerIdentInfo.${new_ver_proj}.ini
		endif
	endif
	cd $HOME
endif

set tmpLog1 = $HOME/tmp/tmpLog1
set tmpLog2 = $HOME/tmp/tmpLog2
set tmpLog3 = $HOME/tmp/tmpLog3
/bin/rm -f $tmpLog1 $tmpLog2 $tmpLog3
set errorInd = ""

########################################
# Check the config files under product #
########################################
echo "\nChecking the config files under product"
echo "---------------------------------------"
echo "\n*****************************************" >> $LOG
echo "*Checking the config files under product*" >> $LOG
echo "*****************************************" >> $LOG

echo "-------------------------------------------------------------------------" >> $LOG
echo "Guide:" >> $LOG
echo "The indicated path and file name is from the Target version. " >> $LOG
echo "If the line starts with < means that is the file of the Source version." >> $LOG
echo "If the line starts with > means that is the file of the Target version." >> $LOG
echo "-------------------------------------------------------------------------\n" >> $LOG

cd $HOME/product/$product
foreach x (`ls -a $old_ver_proj1/config/ |  grep -v .harvest.sig`)
	if ( ! -d $x ) then
		set checkMi="N"
		set y = `echo $x | cut -d / -f 3`
		touch $tmpLog1 $tmpLog2 $tmpLog3

		cp -f $HOME/product/$product/v${old_ver_proj}/config/$y $tmpLog1
		perl -pe "s/$old_ver_bb//g" -pi $tmpLog1
		perl -pe "s/$old_ver_proj1//g" -pi $tmpLog1
		perl -pe "s/$old_ver_proj//g" -pi $tmpLog1

		if ( -f  $HOME/product/$product/v${new_ver_proj}/config/$y ) then
			cp -f $HOME/product/$product/v${new_ver_proj}/config/$y $tmpLog2
			perl -pe "s/$new_ver_bb//g" -pi $tmpLog2
			perl -pe "s/$new_ver_proj1//g" -pi $tmpLog2
			perl -pe "s/$new_ver_proj//g" -pi $tmpLog2
		else
			set k = `echo $y | grep -v $old_ver_proj`
			if ("X${k}" == "X") then
				set m = `echo $y | sed "s/$old_ver_proj/$new_ver_proj/g"`
				if ( -f  $HOME/product/$product/v${new_ver_proj}/config/$m ) then
					cp -f $HOME/product/$product/v${new_ver_proj}/config/$m $tmpLog2
					perl -pe "s/$new_ver_bb//g" -pi $tmpLog2
					perl -pe "s/$new_ver_proj1//g" -pi $tmpLog2
					perl -pe "s/$new_ver_proj//g" -pi $tmpLog2
				else
					echo "File: \t~/product/$product/v${new_ver_proj}/config/$m  \tis MISSING from Target version"
					set ans1=""
					while ("X${ans1}" != "XY" && "X${ans1}" != "XN")
						echo "\tDo you want to copy the file $m \tFROM the Source version? ( Y or N ): "
						set ans1=$<
					end
					if ("X${ans1}" == "XY") then
						echo "Copy of: \t\t ~/product/$product/v${new_ver_proj}/config/$m \t\tfile was done from the Source version"  >> $LOG	
						echo "-------------------------------------------------\n" >> $LOG
						cp -f $HOME/product/$product/v${old_ver_proj}/config/$y $HOME/product/$product/v${new_ver_proj}/config/$m
						perl -pe "s/$old_ver_bb/$new_ver_bb/g" -pi $HOME/product/$product/v${new_ver_proj}/config/$m
						perl -pe "s/$old_ver_proj1/$new_ver_proj1/g" -pi $HOME/product/$product/v${new_ver_proj}/config/$m
						perl -pe "s/$old_ver_proj/$new_ver_proj/g" -pi $HOME/product/$product/v${new_ver_proj}/config/$m
						cp -f $HOME/product/$product/v${new_ver_proj}/config/$m $tmpLog2
						perl -pe "s/$new_ver_bb//g" -pi $tmpLog2
						perl -pe "s/$new_ver_proj1//g" -pi $tmpLog2
						perl -pe "s/$new_ver_proj//g" -pi $tmpLog2
					else
						echo "File: \t\t~/product/$product/v${new_ver_proj}/config/$m \tis MISSING from Target version"  >> $LOG
						echo "-------------------------------------------------\n" >> $LOG
						set checkMi="Y"
						set errorInd = "Y"
					endif
				endif
			else
				echo "File:  \t~/product/$product/v${new_ver_proj}/config/$y missing from Target version"
				set ans1=""
				while ("X${ans1}" != "XY" && "X${ans1}" != "XN")
					echo "\tDo you want to copy the file $y from the Source version? ( Y or N ): "
                                        set ans1=$<
                                end
				if ("X${ans1}" == "XY") then
					echo "Copy of: ~/product/$product/v${new_ver_proj}/config/$y file was done from the Source version"  >> $LOG	
					echo "-------------------------------------------------\n" >> $LOG
					cp -f $HOME/product/$product/v${old_ver_proj}/config/$y $HOME/product/$product/v${new_ver_proj}/config/$y
					perl -pe "s/$old_ver_bb/$new_ver_bb/g" -pi $HOME/product/$product/v${new_ver_proj}/config/$y
					perl -pe "s/$old_ver_proj1/$new_ver_proj1/g" -pi $HOME/product/$product/v${new_ver_proj}/config/$y
					perl -pe "s/$old_ver_proj/$new_ver_proj/g" -pi $HOME/product/$product/v${new_ver_proj}/config/$y
					cp -f $HOME/product/$product/v${new_ver_proj}/config/$y $tmpLog2
					perl -pe "s/$new_ver_bb//g" -pi $tmpLog2
					perl -pe "s/$new_ver_proj1//g" -pi $tmpLog2
					perl -pe "s/$new_ver_proj//g" -pi $tmpLog2
				else
					echo "File: \t~/product/$product/v${new_ver_proj}/config/$y \tis MISSING from Target version"  >> $LOG
					echo "-------------------------------------------------\n" >> $LOG
					set checkMi="Y"
					set errorInd = "Y"
				endif
			endif
		endif

		if ( "X${checkMi}" == "XN" ) then
			diff -b $tmpLog1 $tmpLog2 > $tmpLog3
			set anyerr = `cat $tmpLog3|wc -l`
			if ($anyerr > 0) then
				echo "File: \t~/product/$product/v${new_ver_proj}/config/$y" >> $LOG
				echo "----------------------------------------------------" >> $LOG
				cat $tmpLog3 >> $LOG
				echo "----------------------------------------------------\n" >> $LOG
				set errorInd = "Y"
			endif
		endif
		/bin/rm -f $tmpLog1 $tmpLog2 $tmpLog3
        endif
end


#####################################
# Check the config files under comp #
#####################################
echo "\nChecking the config files under comp"
echo "------------------------------------"
echo "\n**************************************" >> $LOG
echo "*Checking the config files under comp*" >> $LOG
echo "**************************************" >> $LOG

echo "-------------------------------------------------------------------------" >> $LOG
echo "Guide:" >> $LOG
echo "The indicated path and file name is from the Target version. " >> $LOG
echo "If the line starts with < means that is the file of the Source version." >> $LOG
echo "If the line starts with > means that is the file of the Target version." >> $LOG
echo "-------------------------------------------------------------------------\n" >> $LOG

cd $HOME/comp
set comp = `cat $HOME/product/$product/${old_ver_proj1}/config/product_profile | grep CompNames | awk -F= '{print $2}'`
foreach w ( $comp )
	if ( ! -f $w ) then
		foreach x (`ls $w/$old_ver_proj1/config/ `)
			if ( ! -d $x ) then
				set checkMi="N"
				set y = `echo $x | cut -d / -f 3`
				touch $tmpLog1 $tmpLog2 $tmpLog3
				cp -f $HOME/comp/$w/v${old_ver_proj}/config/$y $tmpLog1
				perl -pe "s/$old_ver_bb//g" -pi $tmpLog1
				perl -pe "s/$old_ver_proj1//g" -pi $tmpLog1
				perl -pe "s/$old_ver_proj//g" -pi $tmpLog1

				if ( -f  $HOME/comp/$w/v${new_ver_proj}/config/$y ) then
					cp -f $HOME/comp/$w/v${new_ver_proj}/config/$y $tmpLog2
					perl -pe "s/$new_ver_bb//g" -pi $tmpLog2
					perl -pe "s/$new_ver_proj1//g" -pi $tmpLog2
					perl -pe "s/$new_ver_proj//g" -pi $tmpLog2
				else
					set k = `echo $y | grep -v $old_ver_proj`
					if ("X${k}" == "X") then
						set m = `echo $y | sed "s/$old_ver_proj/$new_ver_proj/g"`
						if ( -f  $HOME/comp/$w/v${new_ver_proj}/config/$m ) then
							cp -f $HOME/comp/$w/v${new_ver_proj}/config/$m $tmpLog2
							perl -pe "s/$new_ver_bb//g" -pi $tmpLog2
							perl -pe "s/$new_ver_proj1//g" -pi $tmpLog2
							perl -pe "s/$new_ver_proj//g" -pi $tmpLog2
						else
       		                                       	echo "File: \t~/comp/$w/v${new_ver_proj}/config/$m \tis MISSING from Target version"
							set answer="Default"
							while ("X${answer}" != "XY" && "X${answer}" != "XN")
								echo "\tDo you want to copy the file $m \tFROM the Source version? ( Y or N ): "
								set answer=$<
							end
							if ("X${answer}" == "XY") then	
								echo "Copy of: \t~/comp/$w/v${new_ver_proj}/config/$m file was done from the Source version"  >> $LOG
								echo "----------------------------------------------------\n" >> $LOG
								cp -f $HOME/comp/$w/v${old_ver_proj}/config/$y $HOME/comp/$w/v${new_ver_proj}/config/$m
                                               			perl -pe "s/$old_ver_bb/$new_ver_bb/g" -pi $HOME/comp/$w/v${new_ver_proj}/config/$m
								perl -pe "s/$old_ver_proj1/$new_ver_proj1/g" -pi $HOME/comp/$w/v${new_ver_proj}/config/$m
								perl -pe "s/$old_ver_proj/$new_ver_proj/g" -pi $HOME/comp/$w/v${new_ver_proj}/config/$m
								cp -f $HOME/comp/$w/v${new_ver_proj}/config/$m $tmpLog2
								perl -pe "s/$new_ver_bb//g" -pi $tmpLog2
								perl -pe "s/$new_ver_proj1//g" -pi $tmpLog2
								perl -pe "s/$new_ver_proj//g" -pi $tmpLog2
		                                        else
       		                                        	echo "File: \t~/comp/$w/v${new_ver_proj}/config/$m \tis MISSING from Target version"  >> $LOG
								echo "----------------------------------------------------\n" >> $LOG
                                                		set checkMi="Y"
                                                		set errorInd = "Y"
							endif
						endif
					else
                                                echo "File: \t~/comp/$w/v${new_ver_proj}/config/$y \tis MISSING from Target version"
						set answer="Default"
						while ("X${answer}" != "XY" && "X${answer}" != "XN")
							echo "\tDo you want to copy the file $y \tFROM the Source version? ( Y or N ): "
							set answer=$<
						end
						if ("X${answer}" == "XY") then
							echo "Copy of: \t~/comp/$w/v${new_ver_proj}/config/$y file was done from the Source version"  >> $LOG
							echo "----------------------------------------------------\n" >> $LOG
							cp -f $HOME/comp/$w/v${old_ver_proj}/config/$y $HOME/comp/$w/v${new_ver_proj}/config/$m
							perl -pe "s/$old_ver_bb/$new_ver_bb/g" -pi $HOME/comp/$w/v${new_ver_proj}/config/$y
							perl -pe "s/$old_ver_proj1$new_ver_proj1/g" -pi $HOME/comp/$w/v${new_ver_proj}/config/$y
							perl -pe "s/$old_ver_proj/$new_ver_proj/g" -pi $HOME/comp/$w/v${new_ver_proj}/config/$y
							cp -f $HOME/comp/$w/v${new_ver_proj}/config/$y $tmpLog2
							perl -pe "s/$new_ver_bb//g" -pi $tmpLog2
							perl -pe "s/$new_ver_proj1//g" -pi $tmpLog2
							perl -pe "s/$new_ver_proj//g" -pi $tmpLog2
						else
                                                        echo "File: \t~/comp/$w/v${new_ver_proj}/config/$y \tis MISSING from Target version"  >> $LOG
							echo "----------------------------------------------------\n" >> $LOG
                                                        set checkMi="Y"
                                                        set errorInd = "Y"
						endif
					endif
				endif

				if ( "X${checkMi}" == "XN" ) then
					diff -b $tmpLog1 $tmpLog2 > $tmpLog3
					set anyerr = `cat $tmpLog3|wc -l`
					if ($anyerr > 0) then
						echo "File: \t~/comp/$w/v${new_ver_proj}/config/$y" >> $LOG
						echo "--------------------------------------------------" >> $LOG
						cat $tmpLog3 >>$LOG
						echo "--------------------------------------------------\n" >> $LOG
						set errorInd = "Y"
					endif
				endif	
				/bin/rm -f $tmpLog1 $tmpLog2 $tmpLog3
			endif
		end
	endif
end

#######################################
# Check the config files under module #
#######################################
echo "\nChecking the config files under module"
echo "---------------------------------------"
echo "\n****************************************" >> $LOG
echo "*Checking the config files under module*" >> $LOG
echo "****************************************" >> $LOG

echo "-------------------------------------------------------------------------" >> $LOG
echo "Guide:" >> $LOG
echo "The indicated path and file name is from the Target version. " >> $LOG
echo "If the line starts with < means that is the file of the Source version." >> $LOG
echo "If the line starts with > means that is the file of the Target version." >> $LOG
echo "-------------------------------------------------------------------------\n" >> $LOG

cd $HOME/module
set modules = `show_str.pl -P $product -v $old_ver_proj1 | awk -F: '{print $2}'|uniq`
sleep 5
foreach w ( $modules )
	if ( ! -f $w ) then
		foreach x (`ls $w/$old_ver_proj1/config/`)
			if ( ! -d $x ) then
				set checkMi="N"
				set y = `echo $x | cut -d / -f 3`
				touch $tmpLog1 $tmpLog2 $tmpLog3
				cp -f $HOME/module/$w/v${old_ver_proj}/config/$y $tmpLog1
				perl -pe "s/$old_ver_bb//g" -pi $tmpLog1
				perl -pe "s/$old_ver_proj1//g" -pi $tmpLog1
				perl -pe "s/$old_ver_proj//g" -pi $tmpLog1

				if ( -f  $HOME/module/$w/v${new_ver_proj}/config/$y ) then
					cp -f $HOME/module/$w/v${new_ver_proj}/config/$y $tmpLog2
					perl -pe "s/$new_ver_bb//g" -pi $tmpLog2
					perl -pe "s/$new_ver_proj1//g" -pi $tmpLog2
					perl -pe "s/$new_ver_proj//g" -pi $tmpLog2
				else
					set k = `echo $y | grep -v $old_ver_proj`
					if ("X${k}" == "X") then
						set m = `echo $y | sed "s/$old_ver_proj/$new_ver_proj/g"`
						if ( -f  $HOME/module/$w/v${new_ver_proj}/config/$m ) then
							cp -f $HOME/module/$w/v${new_ver_proj}/config/$m $tmpLog2
							perl -pe "s/$new_ver_bb//g" -pi $tmpLog2
							perl -pe "s/$new_ver_proj1//g" -pi $tmpLog2
							perl -pe "s/$new_ver_proj//g" -pi $tmpLog2
						else
                                                        echo "File: \t~/module/$w/v${new_ver_proj}/config/$m \tis MISSING from Target version" 
                                                        set answer="Default"
                                                        while ("X${answer}" != "XY" && "X${answer}" != "XN")
                                                                echo "\tDo you want to copy the file $m \tFROM Source version? ( Y or N ): "
                                                                set answer=$<
                                                        end
                                                        if ("X${answer}" == "XY") then
                                                                echo "Copy of: \t~/module/$w/v${new_ver_proj}/config/$m file was done from the Source version"  >> $LOG
								echo "--------------------------------------------------\n" >> $LOG
                                                                cp -f $HOME/module/$w/v${old_ver_proj}/config/$y $HOME/module/$w/v${new_ver_proj}/config/$m
                                                                perl -pe "s/$old_ver_bb/$new_ver_bb/g" -pi $HOME/module/$w/v${new_ver_proj}/config/$m
                                                                perl -pe "s/$old_ver_proj1/$new_ver_proj1/g" -pi $HOME/module/$w/v${new_ver_proj}/config/$m
                                                                perl -pe "s/$old_ver_proj/$new_ver_proj/g" -pi $HOME/module/$w/v${new_ver_proj}/config/$m
                                                                cp -f $HOME/module/$w/v${new_ver_proj}/config/$m $tmpLog2
                                                                perl -pe "s/$new_ver_bb//g" -pi $tmpLog2
                                                                perl -pe "s/$new_ver_proj1//g" -pi $tmpLog2
                                                                perl -pe "s/$new_ver_proj//g" -pi $tmpLog2
							else
                                                                echo "File: \t$HOME/module/$w/v${new_ver_proj}/config/$m \tis MISSING from Target version"  >> $LOG
								echo "--------------------------------------------------\n" >> $LOG
                                                                set checkMi="Y"
                                                                set errorInd = "Y"
                                                        endif
						endif
					else
                                                echo "File: \t~/module/$w/v${new_ver_proj}/config/$y \tis MISSING from Target version"
						set answer="Default"
						while ("X${answer}" != "XY" && "X${answer}" != "XN")
							echo "\tDo you want to copy the file $y \tFROM Source version? ( Y or N ): "
							set answer=$<
						end
						if ("X${answer}" == "XY") then
							echo "Copy of: \t~/module/$w/v${new_ver_proj}/config/$y file was done from the Source version"  >> $LOG
							echo "--------------------------------------------------\n" >> $LOG
							cp -f $HOME/module/$w/v${old_ver_proj}/config/$y $HOME/module/$w/v${new_ver_proj}/config/$y
							perl -pe "s/$old_ver_bb/$new_ver_bb/g" -pi $HOME/module/$w/v${new_ver_proj}/config/$y
                                                        perl -pe "s/$old_ver_proj1/$new_ver_proj1/g" -pi $HOME/module/$w/v${new_ver_proj}/config/$y
                                                        perl -pe "s/$old_ver_proj/$new_ver_proj/g" -pi $HOME/module/$w/v${new_ver_proj}/config/$y
							cp -f $HOME/module/$w/v${new_ver_proj}/config/$y $tmpLog2
							perl -pe "s/$new_ver_bb//g" -pi $tmpLog2
							perl -pe "s/$new_ver_proj1//g" -pi $tmpLog2
							perl -pe "s/$new_ver_proj//g" -pi $tmpLog2
						else
                                                        echo "File: \t~/module/$w/v${new_ver_proj}/config/$y \tis MISSING from the Source version"  >> $LOG
							echo "--------------------------------------------------\n" >> $LOG
                                                        set checkMi="Y"
                                                        set errorInd = "Y"
                                                endif
					endif
				endif

				if ( "X${checkMi}" == "XN" ) then
					diff -b $tmpLog1 $tmpLog2 > $tmpLog3
					set anyerr = `cat $tmpLog3|wc -l`
					if ($anyerr > 0) then
						echo "File: \t~/module/$w/v${new_ver_proj}/config/$y" >> $LOG
						echo "--------------------------------------------------------" >> $LOG
						cat $tmpLog3 >>$LOG
						echo "------------------------------------------------------\n" >> $LOG
						set errorInd = "Y"
					endif
				endif
				/bin/rm -f $tmpLog1 $tmpLog2 $tmpLog3
			endif
		end
	endif
end

############################################################################
# Check the files under proj Filesystem that are specific for each version #
############################################################################
echo "\nChecking the files under proj area"
echo "----------------------------------"
echo "\n************************************" >> $LOG
echo "*Checking the files under proj area*" >> $LOG
echo "************************************" >> $LOG

echo "-------------------------------------------------------------------------" >> $LOG
echo "Guide:" >> $LOG
echo "The indicated path and file name is from the Target version. " >> $LOG
echo "If the line starts with < means that is the file of the Source version." >> $LOG
echo "If the line starts with > means that is the file of the Target version." >> $LOG
echo "-------------------------------------------------------------------------\n" >> $LOG

cd $HOME/proj/$CCPROJ
cd ..
foreach x ( `ls -d *${old_ver_proj}V${var}` )
	set y = `echo $x | sed "s/${old_ver_proj}/${new_ver_proj}/g"`
	foreach w (proj_profile .project.setup make.def)
		touch $tmpLog1 $tmpLog2 $tmpLog3
		if ( -f  ${x}/${w}) then
			cp -f $x/$w $tmpLog1
			perl -pe "s/$old_ver_bb//g" -pi $tmpLog1
			perl -pe "s/$old_ver_proj1//g" -pi $tmpLog1
			perl -pe "s/$old_ver_proj//g" -pi $tmpLog1

			if ( -f  ~/proj/${y}/${w} ) then
				cp -f ~/proj/${y}/${w} $tmpLog2
				perl -pe "s/$new_ver_bb//g" -pi $tmpLog2
				perl -pe "s/$new_ver_proj1//g" -pi $tmpLog2
				perl -pe "s/$new_ver_proj//g" -pi $tmpLog2
			else
				echo "File: \t~/proj/${y}/${w} \tis MISSING"
				set answer="Default"
				while ("X${answer}" != "XY" && "X${answer}" != "XN")
					echo "\tDo you want to copy the file $w \tFROM Source version? ( Y or N ): "
					set answer=$<
				end
				if ("X${answer}" == "XY") then
					echo "Copy of: \t~/proj/${y}/${w} file was done from the Source version"  >> $LOG
					echo "--------------------------------------------------\n" >> $LOG
					cp -f $HOME/proj/${x}/${w} $HOME/proj/${y}/${w}
					perl -pe "s/$old_ver_bb/$new_ver_bb/g" -pi $HOME/proj/${y}/${w}
					perl -pe "s/$old_ver_proj1/$new_ver_proj1/g" -pi $HOME/proj/${y}/${w}
					perl -pe "s/$old_ver_proj/$new_ver_proj/g" -pi $HOME/proj/${y}/${w}
					cp -f $HOME/proj/${y}/${w} $tmpLog2
					perl -pe "s/$new_ver_bb//g" -pi $tmpLog2
					perl -pe "s/$new_ver_proj1//g" -pi $tmpLog2
					perl -pe "s/$new_ver_proj//g" -pi $tmpLog2
				else
					echo "File: \t~/proj/${y}/${w} \tis MISSING from Source version"  >> $LOG
					echo "--------------------------------------------------\n" >> $LOG
					set checkMi="Y"
					set errorInd = "Y"
				endif
			endif

			if ( "X${checkMi}" == "XN" ) then
				diff -b $tmpLog1 $tmpLog2 > $tmpLog3
				set anyerr = `cat $tmpLog3|wc -l`
				if ($anyerr > 0) then
					echo "File: \t~/proj/${y}/${w}" >> $LOG
					echo "--------------------------------------------------------" >> $LOG
					cat $tmpLog3 >>$LOG
					echo "------------------------------------------------------\n" >> $LOG
					set errorInd = "Y"
				endif
			endif
		else
			echo "Project from Source version: \t$x has NO $w \tfile"
			if ( -f  ~/proj/${y}/${w} ) then
				echo "Project from Target version: \t$y has $w \tfile"
			else
				echo "Project from Target version: \t$y has NO $w \tfile"
			endif
		endif
		/bin/rm -f $tmpLog1 $tmpLog2 $tmpLog3
	end

	if ( "X${product}" != "Xecare" ) then
		if ( "X${product}" != "XCRM" ) then
			echo "\nChecking the profile.mcu links"
			echo "-------------------------------"
			echo "\n********************************" >> $LOG
			echo "*Checking the profile.mcu links*" >> $LOG
			echo "********************************" >> $LOG

			if ( -l  $x/profile.mcu ) then
				#set linS = `ll $x/profile.mcu`
				set linS = `ls -lFa $x/profile.mcu`
				set linS1 = `echo $linS | cut -d '>' -f 2- | sed "s/ //g"` 
				set linS2 = `echo $linS1| sed "s/$old_ver_proj/$new_ver_proj/g"` 
				
				#set linT = `ll $y/profile.mcu`
				set linT = `ls -lFa $y/profile.mcu`
				set linT1 = `echo $linT | cut -d '>' -f 2- | sed "s/ //g"` 
				set linT2 = `ls $y/profile.mcu`
				if ( -l $y/profile.mcu ) then
					echo "Link: \t~/proj/${y}/profile.mcu \twas linking to: \t$linT1" >> $LOG
					rm -f $linT2
					ln -s $linS2 $HOME/proj/${y}/profile.mcu
					echo "Link: \t~/proj/${y}/profile.mcu \tis now linking to: \t$linS2 " >> $LOG
					echo "------------------------------------------------------------\n" >> $LOG
				else
					echo "Link: \t~/proj/${y}/profile.mcu \twas MISSING from Target version"
					echo "Link: \t~/proj/${y}/profile.mcu \tis now linking to: \t$linS2"
					echo "Link: \t~/proj/${y}/profile.mcu \twas MISSING from Target version" >> $LOG
					echo "Link: \t~/proj/${y}/profile.mcu \tis now linking to: \t$linS2" >> $LOG
					echo "------------------------------------------------------------\n" >> $LOG
					ln -s $linS2 $HOME/proj/${y}/profile.mcu
				endif
			else
				echo "Project from Source version: \t$x has NO profile.mcu"
			endif
		endif
	endif
end
cd $HOME

###############################
# Printing the results if any #
###############################
if ($errorInd == "Y") then
        echo "\n\nDifferences were found"
        echo "Please check the logfile for FULL details:"
        echo "\t$LOG\n"
else
        echo "\n\nNo differences were found"
	echo "Please check the logfile for FULL details:"
	echo "\t$LOG\n"
endif
