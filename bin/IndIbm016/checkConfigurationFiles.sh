#! /usr/local/bin/tcsh -f
####################################################################################
# Name   : checkConfigurationFiles.sh 						   #
# Purpose:									   #	
#	1. Use the script to updateFile system and do the refresh		   #
#	2. Create the SDK link based on the previous link			   #
#	3. Copy the non XtraC configuration files that are under the data folder   #
#	4. Compare Configuration files between two versions 			   #
#		(product, comp, module, project, bb)				   #
#										   #	
# Usage / Examples:								   #
#	checkConfigurationFiles.sh <product> <old version> <new version> <variant> #
#	checkConfigurationFiles.sh abl v65_0 v65_0_CT 64		           #
#										   #
# Dependencies (files and scripts):						   #
#		1. GetListOfCCEnt						   #
#									           #	
# Author:        Nikoletta Sirivianou 						   #
# Supervisor:    Einat Wizeman, Tal Gedanken Katz				   #
# Date:          09/2008						           #	
####################################################################################

set product = $1
set old_ver_bb = $2
set new_ver_bb = $3
set var = $4

set bb_tmp1 = `echo $old_ver_bb |cut -d _ -f  2-`
set bb_tmp2 = `echo $new_ver_bb |cut -d _ -f  2-`
set old_ver_proj1 = `echo $old_ver_bb | cut -d _ -f 1`$bb_tmp1
set new_ver_proj1 = `echo $new_ver_bb | cut -d _ -f 1`$bb_tmp2
set old_ver_proj = `echo $old_ver_proj1 | cut -d v -f 2` #without the v
set new_ver_proj = `echo $new_ver_proj1 | cut -d v -f 2` #without the v
set prod1 = `echo $HARBROKERNAME | cut -d / -f 2`

if ("X${new_ver_bb}" == "X") then
   echo "\n\tError:\n"
   echo "\t\t`basename $0` <product> <old version> <new version> <variant> \n"
   echo "\t\t`basename $0` abl v65_0 v65_0_CT 64\n"
   exit(1)
endif
if ("X${old_ver_bb}" == "X${new_ver_bb}") then
   echo "\n\tError:\n"
   echo "\t\tYour base version with the new one are the same.\n"
   exit(1)
endif

######################################
# Update file system - Product level #
######################################
#echo "Update file system - Product level"
#hupdateFileSystem -l PRODUCTVER -v $new_ver_bb -va $var

###############
# Run Refresh #
###############
#echo "Run Refresh"
#/opt/CA/harvest7/config/$prod1/bin/refresh -machine $HOST -XML -execute -v $new_ver_proj -P

#######################
# Create the SDK Link #
#######################
#if ( -d "$SDKHOME") then
#	echo "Creating the SDK Link"
#	cd $SDKHOME/$SDKRELEASE
#	set y = `pwd`
#	set re = `echo $SDKRELEASE |sed "s/$old_ver_proj/$new_ver_proj/g"`
#	cd $SDKHOME
#	\rm -f $re
#	ln -s $y $re
#endif

################################################################
# Copy the files under data that are specific for each version #
################################################################
#if (! -d "$HOME/v${old_ver_proj}/$prod1/data") then
#	echo "Copy the files under data that are specific for each version"
#	cd $HOME/data
#	foreach x (`ls *${old_ver_proj}V${var}.ini`)
#		echo $x 
#		set y = `echo $x |sed "s/$old_ver_proj/$new_ver_proj/g"`
#		cp $x $y
#		perl -pe "s/$old_ver_bb/$new_ver_bb/g" -pi $y
#		perl -pe "s/$old_ver_proj/$new_ver_proj/g" -pi $y
#	end
#	if ( -f cc_local.dat.v${old_ver_proj} ) then
#	       cp -f cc_local.dat.v${old_ver_proj} cc_local.dat.v${new_ver_proj}
#		perl -pe "s/$old_ver_bb/$new_ver_bb/g" -pi cc_local.dat.v${new_ver_proj}
#		perl -pe "s/$old_ver_proj/$new_ver_proj/g" -pi cc_local.dat.v${new_ver_proj}
#       endif
#	if ( -f name_mask.set_up.v${old_ver_proj} ) then
#		cp -f name_mask.set_up.v${old_ver_proj}  name_mask.set_up.v${new_ver_proj}
#		perl -pe "s/$old_ver_bb/$new_ver_bb/g" -pi name_mask.set_up.v${new_ver_proj}
#		perl -pe "s/$old_ver_proj/$new_ver_proj/g" -pi name_mask.set_up.v${new_ver_proj}
#	endif
#
#       if ( -d "$HOME/data/Ident/") then
#               echo "Copy the files under data/Ident/ that are specific for each version"
#               cd $HOME/data/Ident
#               cp -f VerIdentInfo.${old_ver_proj}.ini VerIdentInfo.${new_ver_proj}.ini
#               perl -pe "s/$old_ver_bb/$new_ver_bb/g" -pi VerIdentInfo.${new_ver_proj}.ini
#               perl -pe "s/$old_ver_proj/$new_ver_proj/g" -pi VerIdentInfo.${new_ver_proj}.ini
#               cd $HOME
#       endif
#	cd $HOME
#else
#	cd $HOME/v${old_ver_proj}/$prod1/data
#	echo "Copy the files under v${old_ver_proj}/$prod1/data that are specific for each version"
#	foreach x (`ls`)
#		echo $x
#		set y = `echo $x |sed "s/$old_ver_proj/$new_ver_proj/g"`
#		cp $x $HOME/v${new_ver_proj}/$prod1/data/$y
#		perl -pe "s/$old_ver_bb/$new_ver_bb/g" -pi $HOME/v${new_ver_proj}/$prod1/data/$y
#		perl -pe "s/$old_ver_proj/$new_ver_proj/g" -pi $HOME/v${new_ver_proj}/$prod1/data/$y
#	end
#
#	cd $HOME/data
#	echo "Copy the files under data that are specific for each version"
#
#       if ( -f cc_local.dat.v${old_ver_proj} ) then
#              cp -f cc_local.dat.v${old_ver_proj} cc_local.dat.v${new_ver_proj}
#               perl -pe "s/$old_ver_bb/$new_ver_bb/g" -pi cc_local.dat.v${new_ver_proj}
#               perl -pe "s/$old_ver_proj/$new_ver_proj/g" -pi cc_local.dat.v${new_ver_proj}
#       endif
#       if ( -f name_mask.set_up.v${old_ver_proj} ) then
#               cp -f name_mask.set_up.v${old_ver_proj}  name_mask.set_up.v${new_ver_proj}
#               perl -pe "s/$old_ver_bb/$new_ver_bb/g" -pi name_mask.set_up.v${new_ver_proj}
#               perl -pe "s/$old_ver_proj/$new_ver_proj/g" -pi name_mask.set_up.v${new_ver_proj}
#       endif
#	
#	if ( -d "$HOME/data/Ident/") then
#		echo "Copy the files under data/Ident/ that are specific for each version"
#		cd $HOME/data/Ident
#		cp -f VerIdentInfo.${old_ver_proj}.ini VerIdentInfo.${new_ver_proj}.ini
#		perl -pe "s/$old_ver_bb/$new_ver_bb/g" -pi VerIdentInfo.${new_ver_proj}.ini
#		perl -pe "s/$old_ver_proj/$new_ver_proj/g" -pi VerIdentInfo.${new_ver_proj}.ini
#		cd $HOME
#	endif
#endif


if (! -d "$HOME/Diff") then
    mkdir -p "$HOME/Diff"
endif

set LOG = $HOME/Diff/log.Diff.`timestamp`
touch $LOG

set tmpLog1 = $HOME/tmp/tmpLog1
set tmpLog2 = $HOME/tmp/tmpLog2
set tmpLog3 = $HOME/tmp/tmpLog3
set errorInd = ""

########################################
# Check the config files under product #
########################################
echo ""
echo "Checking the config files under product"
cd $HOME/product/$product
foreach x (`ls -a $old_ver_proj1/config/ | grep -v bk`)
	if ( ! -d $x ) then
		set y = `echo $x | cut -d / -f 3`
		touch $tmpLog1 $tmpLog2 $tmpLog3
#		echo $x
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
					echo "Product $product has no $m for the $new_ver_bb version"
				endif
			else
				echo "Product $product has no $y for the $new_ver_bb version"
			endif
		endif

		diff -b $tmpLog1 $tmpLog2 > $tmpLog3
		set anyerr = `cat $tmpLog3|wc -l`
		if ($anyerr > 0) then
			echo "In product - Check the $y  file " >> $LOG
			echo "Difference between the $old_ver_bb and the $new_ver_bb " >> $LOG
			cat $tmpLog3 >>$LOG
			echo ---------------------------- >>$LOG
			echo "" >>$LOG
			set errorInd = "Y"
		endif
		/bin/rm -f $tmpLog1 $tmpLog2 $tmpLog3
        endif
end


#####################################
# Check the config files under comp #
#####################################
echo ""
echo "Checking the config files under comp"
cd $HOME/comp/$product
foreach x (`ls $old_ver_proj1/config/ `)
	if ( ! -d $x ) then
		set y = `echo $x | cut -d / -f 3`
		touch $tmpLog1 $tmpLog2 $tmpLog3
#		echo $x
		cp -f $HOME/comp/$product/v${old_ver_proj}/config/$y $tmpLog1
		perl -pe "s/$old_ver_bb//g" -pi $tmpLog1
		perl -pe "s/$old_ver_proj1//g" -pi $tmpLog1
		perl -pe "s/$old_ver_proj//g" -pi $tmpLog1

		if ( -f  $HOME/comp/$product/v${new_ver_proj}/config/$y ) then
			cp -f $HOME/comp/$product/v${new_ver_proj}/config/$y $tmpLog2
			perl -pe "s/$new_ver_bb//g" -pi $tmpLog2
			perl -pe "s/$new_ver_proj1//g" -pi $tmpLog2
			perl -pe "s/$new_ver_proj//g" -pi $tmpLog2
		else
			set k = `echo $y | grep -v $old_ver_proj`
			if ("X${k}" == "X") then
				set m = `echo $y | sed "s/$old_ver_proj/$new_ver_proj/g"`
				if ( -f  $HOME/comp/$product/v${new_ver_proj}/config/$m ) then
					cp -f $HOME/comp/$product/v${new_ver_proj}/config/$m $tmpLog2
					perl -pe "s/$new_ver_bb//g" -pi $tmpLog2
					perl -pe "s/$new_ver_proj1//g" -pi $tmpLog2
					perl -pe "s/$new_ver_proj//g" -pi $tmpLog2
				else
					echo "Comp has no $m for the $new_ver_bb version"
				endif
			else
				echo "Comp has no $y for the $new_ver_bb version"
			endif
		endif

		diff -b $tmpLog1 $tmpLog2 > $tmpLog3
		set anyerr = `cat $tmpLog3|wc -l`
		if ($anyerr > 0) then
			echo "In comp - Check the $y  file " >> $LOG
			echo "Difference between the $old_ver_bb and the $new_ver_bb " >> $LOG
			cat $tmpLog3 >>$LOG
			echo ---------------------------- >>$LOG
			echo "" >>$LOG
			set errorInd = "Y"
		endif
		/bin/rm -f $tmpLog1 $tmpLog2 $tmpLog3
	endif
end

#######################################
# Check the config files under module #
#######################################
echo ""
echo "Checking the config files under module"
cd $HOME/module
foreach w (`ls -d * | grep -v tar`)
#	echo $w
	foreach x (`ls $w/$old_ver_proj1/config/ |grep -v old`)
		if ( ! -d $x ) then
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
						echo "Module $w - has no $m for the $new_ver_bb version"
					endif
				else
					echo "Module $w has no $y for the $new_ver_bb version"
				endif
			endif

			diff -b $tmpLog1 $tmpLog2 > $tmpLog3
			set anyerr = `cat $tmpLog3|wc -l`
			if ($anyerr > 0) then
				echo "In module $w - Check the $y  file " >> $LOG
				echo "Difference between the $old_ver_bb and the $new_ver_bb " >> $LOG
				cat $tmpLog3 >>$LOG
				echo ---------------------------- >>$LOG
				echo "" >>$LOG
				set errorInd = "Y"
			endif
			/bin/rm -f $tmpLog1 $tmpLog2 $tmpLog3
		endif
	end
end

############################################################################
# Check the files under proj Filesystem that are specific for each version #
############################################################################
cd $HOME/proj/$CCPROJ
cd ..
echo ""
echo "Checking the files under proj area"
foreach x ( `ls -d *${old_ver_proj}V${var}` )
	set y = `echo $x | sed "s/${old_ver_proj}V${var}//g"`
	foreach w (proj_profile .project.setup make.def profile.mcu)
		touch $tmpLog1 $tmpLog2 $tmpLog3
		if ( -f  $x/$w && -f  ~/proj/${y}${new_ver_proj}V${var}/$w ) then
			cp -f $x/$w $tmpLog1
			perl -pe "s/$old_ver_bb//g" -pi $tmpLog1
			perl -pe "s/$old_ver_proj1//g" -pi $tmpLog1
			perl -pe "s/$old_ver_proj//g" -pi $tmpLog1

			cp -f ~/proj/${y}${new_ver_proj}V${var}/$w $tmpLog2
			perl -pe "s/$new_ver_bb//g" -pi $tmpLog2
			perl -pe "s/$new_ver_proj1//g" -pi $tmpLog2
			perl -pe "s/$new_ver_proj//g" -pi $tmpLog2

			diff -b $tmpLog1 $tmpLog2 > $tmpLog3
			set anyerr = `cat $tmpLog3|wc -l`
			if ($anyerr > 0) then
				echo "In project $x - Check the $w" >> $LOG
				echo "Difference between the $old_ver_bb and the $new_ver_bb " >> $LOG
				cat $tmpLog3 >>$LOG
				echo ---------------------------- >>$LOG
				echo "" >>$LOG
				set errorInd = "Y"
			endif
		else
			echo "Project $x OR Project ${y}${new_ver_proj}V${var} has no $w "
		endif
		/bin/rm -f $tmpLog1 $tmpLog2 $tmpLog3
	end
end
cd $HOME

###################################
# Check the config files under bb #
###################################
echo ""
echo "Checking the config files under bb"
cd $HOME/bb
foreach x ( `GetListOfCCEnt -pd $product -v $old_ver_proj1 -bb`)
	echo $x
      	touch $tmpLog1 $tmpLog2 $tmpLog3 
	if ( -f $HOME/bb/$x/$old_ver_bb/bb_profile ) then
		cp -f $HOME/bb/$x/$old_ver_bb/bb_profile $tmpLog1
		perl -pe "s/$old_ver_bb//g" -pi $tmpLog1
		perl -pe "s/$old_ver_proj1//g" -pi $tmpLog1
		perl -pe "s/$old_ver_proj//g" -pi $tmpLog1
	else
		echo "BB $x has no bb_profile for the $old_ver_bb version"
	endif

	if ( -f  $HOME/bb/$x/$new_ver_bb/bb_profile ) then
		cp -f $HOME/bb/$x/$new_ver_bb/bb_profile $tmpLog2
		perl -pe "s/$new_ver_bb//g" -pi $tmpLog2
		perl -pe "s/$new_ver_proj1//g" -pi $tmpLog2
		perl -pe "s/$new_ver_proj//g" -pi $tmpLog2
	else
		echo "BB $x has no bb_profile for the $new_ver_bb version"
	endif
	
	diff -b $tmpLog1 $tmpLog2 > $tmpLog3
	set anyerr = `cat $tmpLog3|wc -l`
	if ($anyerr > 0) then
		echo "In BB $x - Check the bb_profile file " >> $LOG
		echo "Difference between the $old_ver_bb and the $new_ver_bb " >> $LOG
		cat $tmpLog3 >>$LOG
		echo ---------------------------- >>$LOG
		echo "" >>$LOG
		set errorInd = "Y"
	endif
	/bin/rm -f $tmpLog1 $tmpLog2 $tmpLog3 
end

###############################
# Printing the results if any #
###############################
if ($errorInd == "Y") then
        echo "\n***** Error was found*****\n"
        echo "See the logfile for details:"
        echo "\t$LOG\n"
else
        echo "\n***** No errors were found *****\n"
endif

