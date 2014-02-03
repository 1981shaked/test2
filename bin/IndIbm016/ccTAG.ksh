#!/usr/bin/ksh
#
#########################################################################################################
#
# Name: ccTAG
# Purpose: create C and E TAG files for vi / emacs / findSym.
# 
# General Flow: 1. run tag on Deb area files
#               2. run tag on SCA area files
#	 	3. sort and format output.
#
# Assumptions: 1. ctags and etags installed on server and in $PATH.
#
# Author: Doron Kapitulnik 
# Supervisor:
#
# Update: date:	       User:		Purpose:
# Update: 18-FEB-08    Adi Levy        	Changes / Modification for using Line variables (Use session version variables)
#
#########################################################################################################

if [[ $1 = "-h" ]]
then
	echo "\nUsage: `basename $0` [-h] [-v v<NN>_<N>] {-P <Product> | -M <Module> | -p <project>} [-T <c|e>]\n"
	echo "\t-v v<NN>_<N>\t- Version"
	echo "\t-P <Product>\t- Product Name"
	echo "\t-M <Module>\t- Module Name"
	echo "\t-p <project>\t- Project Name"
	echo "\t-T [c|e]\t- For catgs/etags activity only. default: both.\n"
	exit
fi

# Version support

Ver=""
Product=""
Module=""
Project=""
Type=""
while [ $# != 0 ]
do
	case $1 in
		"-v")	Ver=$2
			shift ; shift 
			;;
		"-P")	Product=$2
			shift ; shift 
			;;
		"-M")	Module=$2
			shift ; shift 
			;;
		"-p")	Project=$2
			shift ; shift 
			;;
		"-T")	Type=$2
			if [[ $Type != "c" && $Type != "e" ]]
			then
				echo "\nTAG (-T) should be c | e only.\n"
				exit
			fi
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

	# Variant (In case Product is sent)

	if [[ -s $HOME/product/$LINE_XTRAC_PROD/v$suffix/config/product_variants ]]
	then
		Line_Proj_Var=`tail -1 $HOME/product/$LINE_XTRAC_PROD/v$suffix/config/product_variants | sed 's/^/V/`
	fi

	cc_ver=v`echo $suffix | cut -c1-2`_`echo $suffix | cut -c3`
	LINE_LOG=$CC_MASTER/Line/Data
	LINE_DATA_HOME=$LINE_LOG/$suffix
	LINE_BIN=$CC_MASTER/Line/v01

	mkdir -p $LINE_DATA_HOME
	cd $LINE_DATA_HOME
	if [[ ! -s set_prod ]]
	then
		rm -f bbs.inf bbs.app set_prod
		touch bbs.inf
		$HOME/bin/show_str.pl -P $LINE_XTRAC_PROD -v $cc_ver | awk -F: '{print "sp -P "$1" -v X -c X -r "$3" -m "$2" -p "$4" -b "$5}' | sed "s/$Line_Proj_Var//g" > set_prod
		$HOME/bin/show_str.pl -P $LINE_XTRAC_PROD -v $cc_ver | awk -F: '{print $4,$5,$6}' | sed "s/$Line_Proj_Var//g" | sed 's/$/ '$LINE_PROD_NAME'/g' > bbs.app
		#wc -l set_prod bbs.app
	fi

elif [[ $Ver != "" ]]
then

	suffix=`echo $Ver | cut -c2-3,5`
	cc_ver=v`echo $suffix | cut -c1-2`_`echo $suffix | cut -c3`
	LINE_DATA_HOME=$LINE_LOG/$suffix

fi

/usr/bin/rm -rf $LINE_DATA_HOME/ccTAG

Tags="ctags etags"

if [[ $Type = "c" ]]
then
	Tags="ctags"
elif [[ $Type = "e" ]]
then
	Tags="etags"
fi

for tg in $Tags
do

	TagHome=$LINE_DATA_HOME/ccTAG/$tg; /usr/bin/mkdir -p $TagHome
	HTagInputFiles=$TagHome/h_input_files.tmp
	PTagInputFiles=$TagHome/p_input_files.tmp

	PROJ_List=`grep -w $LINE_XTRAC_PROD $LINE_DATA_HOME/set_prod | awk '{print $13}' | sort -u`

	if [[ $Project != "" ]]
	then
		PROJ_List=`grep -w $LINE_XTRAC_PROD $LINE_DATA_HOME/set_prod | grep ' -p '$Project' ' | awk '{print $13}' | sort -u`
	elif [[ $Module != "" ]]
	then
		PROJ_List=`grep -w $LINE_XTRAC_PROD $LINE_DATA_HOME/set_prod | grep ' -m '$Module' ' | awk '{print $13}' | sort -u`
	fi

	for Proj in $PROJ_List
	do

		Proj=$Proj$Line_Proj_Var
		echo "Working on $Proj"

		TagFile=$TagHome/$Proj.tmp ; /usr/bin/touch $TagFile
		TagTmp=$TagHome/dummy.c ; /usr/bin/touch $TagTmp

		if [[ $tg = "ctags" ]]
		then
			TagFlags="-w -T -d --global --members"
		else
			TagFlags=$TagTmp
		fi

		### Tag all DEB and CNT area files (h & ph).
		for Area in cnt `grep -w $Proj $LINE_DATA_HOME/bbs.inf $LINE_DATA_HOME/bbs.app | awk '{print $2}' | sort -u`
		do
			echo "	Creating $tg on $Area DEB"
			ProjArea=$CC_MASTER/proj/$Proj/$Area
			find $ProjArea -follow \( -name *.h  \) -print > $HTagInputFiles
			find $ProjArea -follow \( -name *.ph \) -print > $PTagInputFiles
			if [[ -s $HTagInputFiles ]]
			then
				/usr/local/bin/$tg $TagFlags -a -f $TagFile `cat $HTagInputFiles`
			fi
			if [[ -s $PTagInputFiles ]]
			then
				/usr/local/bin/$tg $TagFlags -a -f $TagFile `cat $PTagInputFiles`
			fi
		done
	done

	### Tag for all files in SCA

	BB_List=`grep -w $LINE_XTRAC_PROD $LINE_DATA_HOME/set_prod | awk '{print $NF}' | sort -u`

	if [[ $Project != "" ]]
	then
		BB_List=`grep -w $LINE_XTRAC_PROD $LINE_DATA_HOME/set_prod | grep ' -p '$Project' ' | awk '{print $NF}'`
	elif [[ $Module != "" ]]
	then
		BB_List=`grep -w $LINE_XTRAC_PROD $LINE_DATA_HOME/set_prod | grep ' -m '$Module' ' | awk '{print $NF}'`
	fi

	for Bb in $BB_List
	do

		BbVer=`grep -w $Bb $LINE_DATA_HOME/bbs.inf $LINE_DATA_HOME/bbs.app | head -1 | awk '{print $3}'`
		echo "Working on $Bb SCA"

		TagFile=$TagHome/$Bb.tmp ; /usr/bin/touch $TagFile
		## Cobol files - cbl & pco
		if [[ $tg = "ctags" ]]
		then

			find $CC_MASTER/bb/$Bb/$BbVer -name "*.cbl" -o -name "*.pco" | sed 's/^.*\/\(.*\)\.[cp][bc][lo]$/\1	&	\/PROGRAM-ID\/;"	f/' > $TagFile
		
			## msg (mcu) files
			for MsgFile in `find $CC_MASTER/bb/$Bb/$BbVer -name "*.msg"` 
			do
				Prefix=`grep -e '\.FACILITY' -e '\.facility' $MsgFile | grep '^ *\.' | sed 's/.*PREFIX=\([A-Z]*\)_*.*/\1/;s/.*prefix=\([A-Z]*\)_*.*/\1/;s/\.*\.FACILITY[^A-Z_]*\([A-Z]*\)_*.*$/\1/;s/.*\.facility[^A-Z_]*\([A-Z]*\)_*.*$/\1/' | tail -1`_
				grep -n '^[A-Z]' $MsgFile | sed "s:\([0-9]*\)\:\([A-Z0-9_]*\).*:$Prefix\2	$MsgFile	\1;"\""	d:" >> $TagFile
			done
			InputFiles=`find $CC_MASTER/bb/$Bb/$BbVer -follow \( -name *.c -o -name *.h -o -name *.clib -o -name *.cnt -o -name *.ppc -o -name *.ph -o -name *.msg -o -name *.rw                -o -name *.pco -o -name *.cpp -o -name *.java \) -print`
			if [[ $InputFiles != "" ]]
			then
				/usr/local/bin/$tg $TagFlags -a -f $TagFile $InputFiles
			fi

		fi
		if [[ $tg = "etags" ]]
		then
			InputFiles=`find $CC_MASTER/bb/$Bb/$BbVer -follow \( -name *.c -o -name *.h -o -name *.clib -o -name *.cnt -o -name *.ppc -o -name *.ph -o -name *.msg -o -name *.rw -o -name *.cbl -o -name *.pco -o -name *.cpp -o -name *.java \) -print`
			if [[ $InputFiles != "" ]]
			then
				$tg $TagFlags -a -f $TagFile $InputFiles
			fi			
		fi
	done

	TagOutputDir=$CC_MASTER/data/TAG/$tg ; mkdir -p $TagOutputDir
	TagOutputFile=$TagOutputDir/$cc_ver.$tg 
	if [[ -f $TagOutputFile ]]
	then 
		/usr/bin/mv -f $TagOutputFile $TagOutputFile.BCK
	fi
	/usr/bin/touch $TagOutputFile
	
	if [[ $tg = "ctags" ]]
	then
		UltraOutputFile=$TagOutputDir/$cc_ver.$tg.Ultra 
		if [[ -f $UltraOutputFile ]]
		then 
			/usr/bin/mv -f $UltraOutputFile $UltraOutputFile.BCK
		fi
		/usr/bin/touch $UltraOutputFile
		
		sort $TagHome/*.tmp -o $TagOutputFile
		sed "s?$CC_MASTER?Z:\/CC?g" $TagOutputFile > $UltraOutputFile
	else
		cat $TagHome/*.tmp >> $TagOutputFile
	fi

done

#/usr/bin/rm -rf $LINE_DATA_HOME/ccTAG

