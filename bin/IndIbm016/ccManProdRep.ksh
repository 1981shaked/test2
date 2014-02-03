#!/usr/bin/ksh 
#
# Name    : ccManProdRep
#
# Purpose: This tool will be used as the main prerequisite build results report that will decide if build passed or failed.
# 	   It creates a report on missing Mandatory Products.
#
#		The input for the tool are files named: <Group>.mand.prod.list
#		Those files will contain a format list of Mandatory Products per Group (Application).
#		All entry in the input files need to match the following 2 rules
#
#		<proj without version>*:<bb>:<product name>:<weight1 0-100 for build mark>,<build criteria weight 0-100>
#
#		Rule 1. Single product: <product name> is <specific product name>
#			e.g: crpr*:crpr7:libcrpr7.so:1,10
#
#		Rule 2. General rule:   <product name> is <source wild char>=<target wild char>
#		        e.g.: gbl*:gbl:*.cpp=*.o:1,1
#
#		Exceptions - Exception will be listed (with a space delimiter) as the 5th filed in general rules.
#			e.g.: cbf*:cbf9vfg:*.c=*.o:2,2:x1.o x2.o
#
#		* The weight1 field will be used to calculate failure % for build mark.
#		* The weight2 field will be used to calculate failure % for build criteria.
#		* You can give each entry a different weight in failure %.
#
#		The report will list Total statistic and statistic for each Group.
#
# Author:  Doron Kapitulnik
# Supervisor: 
#
# Update:  date: 02-MAR-05	User: Doronk	Purpose:  add Module success functionality for copy Module to Storage.
# Update:  date: 13-NOV-07      User: Adi Levi	Purpose:  Modify & fix errors when script run on Sprint project.
#                               			  Main fix is: If input entry is not valid, write problem to report and continue to next entry.
# Update:  date: 13-FEB-08	User: Adi Levi 	Purpose:  New script modified - Use internal line / session variables instead of sending params from outside
#    							  mail also removed. The activating command will can send the e-mail
#    							  Also modify logic of report, changed dynamic tmp output file location
# 							  and fixed bugs that were found in flow. (divide by 0 etc, weight1,2 - only 2 is relevant ...)
#
######################################################################################################### 

if [[ $# < 1 ]]
then
	echo "\nUsage: ccManProdRep.ksh <input file/directory> [-P <product>] [-v v<NN>_<N>] [-bk] [-m <mail addr> ... -m <mail addr>]\n"
	echo "\tInput file/directory will contain relevant <group>.mand.prod.list input files or"
	echo "\tFull file name for handling single input group file\n"
	echo "\t-P <product>\t- Product Name"
	echo "\t-v v<NN>_<N>\t- Version"
	echo "\t-bk \t\t- Check on backup dev proj area"
	echo "\t-m <addr> ...\t- Send mail to e-mail addresses/groups\n"
	exit
fi

InputDir=$1
shift

# Mailx & Version support

Product=""
BACK=""
Ver=""
MailAddrs=""
while [ $# != 0 ]
do
	case $1 in
		"-bk")	BACK="back_"
			shift
			;;
		"-P")	Product=$2
			shift ; shift 
			;;
		"-v")	Ver=$2
			shift ; shift 
			;;
		"-m")	MailAddrs="$MailAddrs $2"
			shift ; shift 
			;;
	esac
done

LINE_BASE=${LINE_BASE:=0}
if [[ $LINE_BASE = 0 ]]
then

	CC_MASTER=$CCPROJECTHOME

	# Product

	LINE_PROD_NAME=${CCPRODUCT:=X}
	if [[ $LINE_PROD_NAME = "X" ]]
	then
		LINE_PROD_NAME=${CCPROD:=X}
	fi

	if [[ $Product != "" ]]
	then
		LINE_PROD_NAME=$Product
	fi

	LINE_XTRAC_PROD=$LINE_PROD_NAME

	# Version, Variant

	sp_suffix=`echo $CCPROJ | sed 's/_1$//' | sed 's/V64OG//g' | sed 's/V64//g' | sed 's/V32//g' | sed 's/[0-9][a-zA-DF-Z]//g' | sed 's/[a-zA-DF-Z_]//g'`
	if [[ $Ver != "" ]]
	then
		suffix=`echo $Ver | cut -c2-3,5`
		Line_Proj_Var=`echo $CCPROJ | sed "s/^.*$sp_suffix//"`
	else
		suffix=$sp_suffix
		Line_Proj_Var=`echo $CCPROJ | sed "s/^.*$suffix//"`
	fi
	Line_Def_Var=`echo $Line_Proj_Var | sed s/^V//`

	# Variant (In case Product is sent)

	if [[ -s $HOME/product/$LINE_XTRAC_PROD/v$suffix/config/product_variants ]]
	then
		Line_Proj_Var=`tail -1 $HOME/product/$LINE_XTRAC_PROD/v$suffix/config/product_variants | sed "s/^/V/"`
	fi
		
	#############################################
	
	cc_ver=v`echo $suffix | cut -c1-2`_`echo $suffix | cut -c3`
	LINE_LOG=$CC_MASTER/Line/Data
	LINE_DATA_HOME=$LINE_LOG/$suffix
	LINE_BIN=$CC_MASTER/Line/v01
	build_number=0
	if [[ -x $HARVESTSERVERDIR/bin/buildCounter ]]
	then
		build_number=`$HARVESTSERVERDIR/bin/buildCounter Daily $suffix 0 $LINE_PROD_NAME | awk '{print $NF}'`
	elif [[ -f $CC_MASTER/data/Ident/buildCounter.$cc_ver ]]
	then
		build_number=`grep "[0-9]" $CC_MASTER/data/Ident/buildCounter.$cc_ver | head -1 | awk '{print $1}'`
	fi

	mkdir -p $LINE_DATA_HOME
	cd $LINE_DATA_HOME
	#if [[ ! -s set_prod ]]
	#then
		rm -f bbs.inf bbs.app set_prod
		touch bbs.inf
		$HOME/bin/show_str.pl -P $LINE_XTRAC_PROD -v $cc_ver | awk -F: '{print "sp -P "$1" -v X -c X -r "$3" -m "$2" -p "$4" -b "$5}' | sed "s/$Line_Proj_Var//g" > set_prod
		$HOME/bin/show_str.pl -P $LINE_XTRAC_PROD -v $cc_ver | awk -F: '{print $4,$5,$6}' | sed "s/$Line_Proj_Var//g" | sed 's/$/ '$LINE_PROD_NAME'/g' > bbs.app
		#wc -l set_prod bbs.app
	#fi

elif [[ $Ver != "" ]]
then

	suffix=`echo $Ver | cut -c2-3,5`
	cc_ver=v`echo $suffix | cut -c1-2`_`echo $suffix | cut -c3`
	LINE_DATA_HOME=$LINE_LOG/$suffix
	build_number=0
	if [[ -x $HARVESTSERVERDIR/bin/buildCounter ]]
	then
		build_number=`$HARVESTSERVERDIR/bin/buildCounter Daily $suffix 0 $LINE_PROD_NAME | awk '{print $NF}'`
	fi

fi

InputFiles=`find $InputDir -name "*mand.prod.list"`
if [[ $InputFiles = "" ]]
then
	echo "Error: No *.mand.prod.list input file is found under $InputDir"
	exit
fi

## Initializations

TmpFile=$LINE_DATA_HOME/ccManProdRep.$LINE_PROD_NAME.tmp
RepFile=$LINE_DATA_HOME/ccManProdRep.$LINE_PROD_NAME.rep
rm -f $TmpFile $RepFile
touch $TmpFile $RepFile

rm -f $LINE_DATA_HOME/ProdList.$LINE_PROD_NAME.*

BuildFailFlag=0

TFailed=0 ; TCheck=0
TFailedW1=0 ; TCheckW1=0
TFailedW2=0 ; TCheckW2=0

## Loop over input files

for Input_File in $InputFiles
do

	FileName=`basename $Input_File`
	GroupName=`echo $FileName | cut -d '.' -f 1`

	echo "--------------------------------------------------" >> $TmpFile
	echo " $FileName Statistics" >> $TmpFile
	echo "--------------------------------------------------\n" >> $TmpFile

	MaxTW2=`grep Fbuild $Input_File | cut -d= -f 2`
	if [[ $MaxTW2 -eq "" ]]
	then
	  	echo "Error : Fbuild value must to be set on $FileName file" >> $TmpFile
	  	continue
	fi

	Check=0 ; Failed=0
	CheckW1=0 ; FailedW1=0
	CheckW2=0 ; FailedW2=0

	## Loop over input file entries

	for Entry in `cat $Input_File | grep -v "^#" | grep -v ^CC= | grep -v ^CCPROJECTHOME= | sed 's/ //g'`
	do

		# Check number of filed separated with : delimiter
		NumFields=`echo $Entry | awk -F: '{print NF}'`
		if [[ $NumFields -lt 3 || $NumFields -gt 5 ]]
		then
			echo "Invalid Entry: $Entry\t Invalid number of filed - $NumFields" >> $TmpFile
			continue
		fi

		#1 - Proj
		if [[ `echo $Entry | cut -d: -f 1 | sed 's/V..//g' | sed 's/[3,5,7,9,A-Z,a-z,_]//g'` != "*" ]]
		then
			echo "Invalid Entry: $Entry\t Proj field should not have the version in it." >> $TmpFile
			continue
		fi
		Proj=`echo $Entry | cut -d: -f 1 | sed 's/OG//' | sed 's/V..//g' | sed "s/*/$suffix/g"`
		if [[ ! -d $CC_MASTER/proj/$BACK$Proj$Line_Proj_Var ]]
		then
			echo "Invalid Entry: $Entry\t Invalid project - $Proj" >> $TmpFile
			continue
		fi

		#2 - Bb
		Bb=`echo $Entry | cut -d: -f 2`
		if [[ `grep -w $Bb $LINE_DATA_HOME/set_prod | awk '{print $(NF - 2)}' | grep -c -w $Proj` -eq 0 ]]
		then
			echo "Invalid Entry: $Entry\t $Bb does not belong $Proj bbs" >> $TmpFile
			continue
		fi

		#3 - file/s
		File=`echo $Entry | cut -d: -f 3`
		if [[ `echo $File | grep = | wc -c` -ne 0 ]]
		then
			file_source=`echo $File | cut -d= -f 1`
			no_start_wildcard=`echo $file_source | sed 's/^*//'`
			no_wildcard=`echo $file_source | sed 's/*//g'`
			if [[ $no_start_wildcard != $no_wildcard ]]
			then
				echo "Invalid Entry: $Entry\t Invalid use of Wild cards - You can only start with wild card" >> $TmpFile
				continue
			fi
			file_target=`echo $File | cut -d= -f 2`
			no_start_wildcard=`echo $file_target | sed 's/^*//'`
			no_wildcard=`echo $file_target | sed 's/*//g'`
			if [[ $no_start_wildcard != $no_wildcard ]]
			then
				echo "Invalid Entry: $Entry\t Invalid use of Wild cards - You can only start with wild card" >> $TmpFile
				continue
			fi
		elif [[ `echo $File | grep '*' | wc -c` -ne 0 ]]
		then
			echo "Invalid Entry: $Entry\t Invalid use of Wild cards - You can use it only with = sign" >> $TmpFile
			continue
		fi

		#4 - weight
		Weight=`echo $Entry | cut -d: -f 4`
		Weight1=`echo $Weight | cut -d, -f 1`
		Weight2=`echo $Weight | cut -d, -f 2`
	
		if [[ $Weight1 != "" ]]
		then
			if [[ `echo $Weight1 | sed 's/[0-9]//g' | wc -c` -ne 1 || $Weight1 -gt 100 || $Weight1 -lt 0 ]]
			then
				echo "Invalid Entry: $Entry\t Invalid Weight - $Weight1 - expect a number 0-100" >> $TmpFile
				continue
			fi
		else
			Weight1=1
		fi

		if [[ $Weight2 != "" ]]
		then
			if [[ `echo $Weight2 | sed 's/[0-9]//g' | wc -c` -ne 1 || $Weight2 -gt 100 || $Weight2 -lt 0 ]]
			then
				echo "Invalid Entry: $Entry\t Invalid Weight - $Weight2 - expect a number 0-100" >> $TmpFile
				continue
			fi
		else
			Weight2=1
		fi

		#5 - exceptions - in wild char rules only
		Exceptions=""
		if [[ `echo $File | grep -c "="` -eq 1 ]]
		then
			Exceptions=`echo $Entry | cut -d: -f 5-`
		fi

		# Create project product list if not created yet
		ProjProdFile=$LINE_DATA_HOME/ProdList.$LINE_PROD_NAME.$Proj
		if [[ ! -f $ProjProdFile ]]
		then
			find $CC_MASTER/proj/$BACK$Proj$Line_Proj_Var/. -type f | awk -F"/" '{print $NF}' > $ProjProdFile
		fi
		
		if [[ `echo $Exceptions | grep -c "="` -eq 1 ]] # Wildchar Entry
		then

			Name=`echo $Exceptions | cut -d '=' -f 1`
			Source=`echo $Exceptions | cut -d '=' -f 1 | sed "s/^.*\*//g"`
			Target=`echo $Exceptions | cut -d '=' -f 2 | sed "s/^.*\*//g"`

			for SourceFN in `find $CC_MASTER/bb/$Bb/$cc_ver -name "$Name"`
			do
				FileName=`basename $SourceFN`
				TargetName=`echo $FileName | sed "s/$Source$/$Target/g"`
				echo $TargetName >> $ProjProdFile
			done

		else
			echo $Exceptions >> $ProjProdFile
		fi

		if [[ `echo $File | grep -c "="` -eq 1 ]] # Wildchar Entry
		then

			Name=`echo $File | cut -d '=' -f 1`
			Source=`echo $File | cut -d '=' -f 1 | sed 's/*//g'`
			Target=`echo $File | cut -d '=' -f 2 | sed 's/*//g'`

			for SourceFN in `find $CC_MASTER/bb/$Bb/$cc_ver -name "$Name"`
			do

				Check=`expr $Check + 1`
				CheckW1=`expr $CheckW1 + $Weight1`
				CheckW2=`expr $CheckW2 + $Weight2`

				FileName=`basename $SourceFN`
				# Dealing with x9 gdd files
				if [[ `echo $FileName | grep -c x9.xml.table` -eq 1 ]]
				then
					FileName=`echo $FileName | sed 's/.x9//g'`
				fi
				TargetName=`echo $FileName | sed "s/$Source$/$Target/g"`
				if [[ `grep -c $TargetName $ProjProdFile` -eq 0 ]]
				then
					echo "Failed: $Proj $TargetName" >> $TmpFile
					Failed=`expr $Failed + 1`
					FailedW1=`expr $FailedW1 + $Weight1`
					FailedW2=`expr $FailedW2 + $Weight2`
				fi

			done

		else

			Check=`expr $Check + 1`
			CheckW1=`expr $CheckW1 + $Weight1`
			CheckW2=`expr $CheckW2 + $Weight2`

			if [[ `grep $File $ProjProdFile | grep -c -w $File` -eq 0 ]]
			then
				echo "Failed: $Proj $File" >> $TmpFile
				Failed=`expr $Failed + 1`
				FailedW1=`expr $FailedW1 + $Weight1`
				FailedW2=`expr $FailedW2 + $Weight2`
			fi

		fi

	done

	if [[ $FailedW2 -lt $MaxTW2 ]]
	then
	        echo "\nModule $GroupName passed\n" >> $TmpFile
	else
		echo "\n$FailedW2 >= $MaxTW2"
	        echo "\nModule $GroupName failed\n" >> $TmpFile
	        BuildFailFlag=1 
	fi

	Prec1=0
	if [[ $CheckW1 -gt 0 ]]
	then
		Prec1=`echo 1 | awk "{print $FailedW1 / $CheckW1 * 100}"`
	fi

	Prec2=0
	if [[ $CheckW2 -gt 0 ]]
	then
		Prec2=`echo 1 | awk "{print $FailedW2 / $CheckW2 * 100}"`
	fi

	echo "Files Checked: $Check ($CheckW1 mark, $CheckW2 weight)." >> $TmpFile
	echo "Files Failed : $Failed ($FailedW1 mark, $FailedW2 weight).\n" >> $TmpFile
	echo "Build Mark Failed: $Prec1% - $FailedW1/$CheckW1." >> $TmpFile
	echo "Build Criteria Weight Failed: $Prec2% - $FailedW2/$CheckW2. Threshold: $MaxTW2.\n" >> $TmpFile

	TFailed=`expr $TFailed + $Failed`
	TFailedW1=`expr $TFailedW1 + $FailedW1`
	TFailedW2=`expr $TFailedW2 + $FailedW2`
	TCheck=`expr $TCheck + $Check`
	TCheckW1=`expr $TCheckW1 + $CheckW1`
	TCheckW2=`expr $TCheckW2 + $CheckW2`

done

if [[ $HOST = "indhp002" ]]
then
	echo "CCMSS Link: http://indhp002:58808/\n" >> $RepFile
elif [[ $HOST = "indsun001" ]]
then
	echo "CCMSS Link: http://ilhp001:58808/\n" >> $RepFile
fi

echo "============================================================" >> $RepFile
echo "$LINE_PROD_NAME v$suffix $HOST build $build_number - Summary Statistics." >> $RepFile
echo "============================================================\n" >> $RepFile

## By this printed string the build decides if build failed. Please do not change this print format
if [[ "$BuildFailFlag" = 1 ]]
then
	echo "Build failed (if one module failed all build failed)\n" >> $RepFile
else
	echo "Build passed\n" >> $RepFile
	BuildFailFlag=1 
fi

grep ^Module $TmpFile >> $RepFile

TPrec1=0
if [[ $TCheckW1 -gt 0 ]]
then
	TPrec1=`echo 1 | awk "{print $TFailedW1 / $TCheckW1 * 100}" | cut -d. -f 1`
fi

TPrec2=0
if [[ $TCheckW2 -gt 0 ]]
then
	TPrec2=`echo 1 | awk "{print $TFailedW2 / $TCheckW2 * 100}" | cut -d. -f 1`
fi

#FullTotal=`echo 1 | awk "{print 100 - $TPrec1}" | cut -d. -f 1`
#TPrec1=`echo $TPrec1 | awk -F. '{print $1}'`
#echo "\nTotal Build Mark $FullTotal%" >> $RepFile
echo "\nTotal Build Mark `expr 100 - $TPrec1`%\n" >> $RepFile
echo "Files Checked: $TCheck ($TCheckW1 mark, $TCheckW2 weight)." >> $RepFile
echo "Files Failed : $TFailed ($TFailedW1 mark, $TFailedW2 weight).\n" >> $RepFile
echo "Total Build Mark Failed: $TPrec1% - $TFailedW1/$TCheckW1." >> $RepFile
echo "Total Build Criteria Weight Failed: $TPrec2% - $TFailedW2/$TCheckW2.". >> $RepFile
echo "\n============================================================\n" >> $RepFile

if [[ $ARCH = "SunOS" ]]
then
	cat $TmpFile >> $RepFile
else
	cat -r $TmpFile >> $RepFile
fi

rm -f $TmpFile $LINE_DATA_HOME/ProdList.$LINE_PROD_NAME.*

# Copy additional backup of the report to old standard report location
mkdir -p $HOME/log/ccManProdRep.ksh
cp -f $RepFile $HOME/log/ccManProdRep.ksh/ccManProdRep.$LINE_XTRAC_PROD.$suffix.rep

mailx_flag=
if [[ $ARCH = "HP-UX" ]]
then
	mailx_flag="-m"
fi

# ------------------------------------------------------
# Finding html report for attaching to mandatory product
# ------------------------------------------------------
# Not every product has this html. Maybe only SDK products
# only for 7.5 SDK this html is located under Audit/prd/...
# ------------------------------------------------------

html_attm=BuildReport_${LINE_PROD_NAME}_${suffix}_Build_${build_number}.html
touch $html_attm

last_build_dir=`ls -rtd $HOME/v$suffix/$LINE_XTRAC_PROD/Audit/prd/$Line_Def_Var/* | tail -1`
if [[ $last_build_dir != "" ]]
then
	cd $last_build_dir
	html_report_file=`ls -1tr *.html | tail -1`
	if [[ $ARCH = "HP-UX" ]]
	then
		ux2dos $html_report_file | uuencode $html_attm > $html_attm
	else
		unix2dos $html_report_file | uuencode $html_attm > $html_attm
	fi
fi

if [[ $MailAddrs = "" ]]
then
	cat $RepFile $html_attm
else
	#cat $RepFile $html_attm | mailx -r "$USER" -s "$LINE_PROD_NAME version v$suffix build $build_number on $HOST" $mailx_flag $MailAddrs
	cat $RepFile $html_attm | mailx -r "$suffix $LINE_PROD_NAME" -s "$LINE_PROD_NAME - `basename $0` v$suffix $HOST build $build_number." $mailx_flag $MailAddrs
	rm -f $html_attm
fi

