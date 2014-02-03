#!/usr/bin/ksh 

####################################################################################
#                                                                                  #
# File Name:ccIcmBuild                                                             #
#                                                                                  #
# Purpose:Run all build products with dependencies                                 #
#                                                                                  #
# Usage : Name:ccIcmBuild < Version Number >  [ -m < mail address > ]              #
#                                                                                  #
# Date: 22/06/2008                                                                 #
#                                                                                  #
# Autor: Eyal Arazi                                                                #
#                                                                                  #
####################################################################################


function LoadArray {
####################  Load the array from the configuration file ##################
	j=1
	Num=$1
	ProdName=$2
	Machine=$3
  	User=$4
	StartBuild=$5
	BuildTime=$6
	BuildDep=$7
	CheckBuild=$8
	BuildStat=$9
	BuildRTime=$10
	BuildSTime=$11
	ProcessID=$12
	while read Line
		do
			Num[$j]=`print $Line | awk -F: '{print $1}'`
			ProdName[$j]=`print $Line | awk -F: '{print $2}'`
			Machine[$j]=`print $Line | awk -F: '{print $3}'`
			User[$j]=`print $Line | awk -F: '{print $4}'`
			StartBuild[$j]=`print $Line | awk -F: '{print $5}'`
			BuildTime[$j]=`print $Line | awk -F: '{print $6}'`
			BuildDep[$j]=`print $Line | awk -F: '{print $7}'`
			CheckBuild[$j]=`print $Line | awk -F: '{print $8}'`
			BuildStat[$j]="0"
			BuildRTime[$j]="0"
			BuildSTime[$j]="0000"
			ProcessID[$j]="0"
			j=$(($j + 1))
		done < $Config_File
#####################################################################################
}
function PrintArray {
#######################  Print The Array Into The File  #############################
	Line_Num=$1
	Array_File=$2
	Num=$3
	ProdName=$4
	Machine=$5
	User=$6
	StartBuild=$7
	BuildTime=$8
	BuildDep=$9
	CheckBuild=$10
	BuildStat=$11
	BuildRTime=$12
	BuildSTime=$13
	ProcessID=$14
	rm -f $Array_File
	touch $Array_File
	j=1
	while ((j <= $Line_Num))
	do
		print "${Num[j]}:${ProdName[$j]}:${Machine[$j]}:${User[$j]}:${StartBuild[j]}:${BuildTime[$j]}:${BuildDep[$j]}:${CheckBuild[$j]}:${BuildStat[$j]}:${BuildRTime[$j]}:${BuildSTime[$j]}:${ProcessID[$j]}" >> $Array_File;
  		(( j = j + 1));
	done
#####################################################################################
}


function CheckProcess {
#############################   Check if the build still running  ###################
	ProcessID=$1
	BuildStat=$2
	j=$3
	Process=`ps -e | grep -w ${ProcessID[$j]} | awk -F" " '{print $1","$4}'`
        ProcessRun=`print $Process | awk -F, '{print $1}'`
	Process_defunct=`print $Process | awk -F, '{print $2}' | grep defunct`
	if [[ $ProcessRun != ${ProcessID[$j]} || $Process_defunct != "" ]]
	then
		BuildStat[$j]=2	
        fi
#####################################################################################
}
function CheckDep {
################################   Check build dependence    ########################
	i=$1
	BuildDep=$2
	BuildStat=$3
	Flag=0
	for Arg in `echo ${BuildDep[$i]} | tr ',' ' '`
		do
			if [[ ${BuildStat[$Arg]} = "0" || ${BuildStat[$Arg]} = "1" ]]
			then
				Flag=1
			fi
		done
   	if [[ $Flag = "0" ]]
	then
		BuildStat[$i]=1
	fi
#####################################################################################
}
function CheckBuildDone {
########################## Check If All Build Process Done ##########################
	BuildStat=$1
	Line_Num=$2
	ICM_LOG=$3
	Mail=$4
	Array_File=$5
	Version=$6
	FMail=$7
	Machine=$8
	User=$9
	j=1
	Flag=0
	while ((j <= $Line_Num))
	do
		if [[ ${BuildStat[$j]} = "0" || ${BuildStat[$j]} = "1" ]]
		then
			Flag=1;	
		fi
		(( j = j + 1));
	done
	if [[ $Flag = "0" ]]
	then
		print "\n***** ICM Build Was Done *****\n" >> $ICM_LOG
		if [[ $FMail = "-m" ]]
		then
        		SentMail $Mail $Array_File $Version Machine User
		fi
		exit 
	fi
#####################################################################################
}
function RunBuild {
#############################      Run The Build       ##############################
	ProdName=$1
	Machine=$2
	User=$3
	StartBuild=$4
	BuildSTime=$5
	ProcessID=$6
	j=$7
	ICM_LOG=$8
	BuildSTime[$j]=`/usr/bin/date '+%Y%m%d_%H%M%S'`
	ssh ${User[$j]}@${Machine[$j]} "setenv SHELL /usr/local/bin/tcsh;source /sdkhome/sdk/SDKRoot/.ccmngr_cshrc;source /sdkhome/sdk/SDKRoot/.ccmngr_login;${StartBuild[$j]} " & 
	ProcessID[$j]=$!
	sleep 10
	ProcessRun=`ps -e | awk -F" " '{print $1}' | grep -w ${ProcessID[$j]}`
	if [[ $ProcessRun = ${ProcessID[$j]} ]]
	then
		TimeS=${BuildSTime[$j]}
		Date=`echo $TimeS | awk -F_ '{print $1}'`
                Dyear=`echo $Date | cut -c 1-4`
                Dmounth=`echo $Date | cut -c 5-6`
                Dday=`echo $Date | cut -c 7-8`
                FullDate=`echo $Dday/$Dmounth/$Dyear`
                Time=`echo $TimeS | awk -F_ '{print $2}'`
                Htime=`echo $Time | cut -c 1-2`
                Hmin=`echo $Time | cut -c 3-4`
                FullTime=`echo $Htime:$Hmin`
		print "\nStart build for ${ProdName[$j]} on ${Machine[$j]} at $FullDate $FullTime\n" >> $ICM_LOG
	else
		print "\nError to Start Build For ${ProdName[$j]} on ${Machine[$j]}\n" >> $ICM_LOG
		exit
	fi
#####################################################################################
}
function CheckTime {
#######################    Check If Build Time Is Over      #########################
	ProcessID=$1
	BuildStat=$2
	BuildTime=$3
	BuildRTime=$4
	BuildSTime=$5
	ProcessID=$6
	j=$7
	if [[ ${BuildTime[$j]} != "N" ]]
	then
		ProcessRun=`ps -e | awk -F" " '{print $1}' | grep -w ${ProcessID[$i]}`
		if [[ $ProcessRun = ${ProcessID[$j]} ]]
		then
			HBuild=`print ${BuildTime[j]} | cut -c1-2`
			MBuild=`print ${BuildTime[j]} | cut -c3-4`
			BuildTime=`echo 1 | awk "{ print ( $HBuild * 60 + $MBuild ) }"`
			Real=`/usr/bin/date '+%Y%m%d_%H%M%S'`
			Real_Date=`print $Real | awk -F_ '{print $1}`
			Real_Time=`print $Real | cut -d"_" -f2 | cut -c1-4`
			HReal_Time=`print $Real_Time | cut -c1-2`
			MReal_Time=`print $Real_Time | cut -c3-4`
			Start_Date=`print ${BuildSTime[$j]} | awk -F_ '{print $1}`
			Start_Time=`print ${BuildSTime[$j]} | cut -d"_" -f2 | cut -c1-4`
			HStart_Time=`print $Start_Time | cut -c1-2`
			MStart_Time=`print $Start_Time | cut -c3-4`
			if [[ $Real_Date = $Start_Date ]]
				then
					BuildRTime[$j]=`echo 1 | awk "{ print ( $HReal_Time * 60 + $MReal_Time ) - ( $HStart_Time * 60 + $MStart_Time ) }"`
					echo "${BuildRTime[$j]}"
			else
					BuildRTime[$j]=`echo 1 | awk "{ print ( ( 24 - $HStart_Time ) * 60 - $MStart_Time )  + ( $HReal_Time *60 + $MReal_Time ) }"`
			fi
			Check_Time=`echo 1 | awk "{ print ( $BuildTime - ${BuildRTime[$j]} ) }"`
			if [[ $Check_Time -lt 1 ]]
			then
				BuildStat[$j]=3
			fi
		fi
	fi
#####################################################################################
}
function Check_Arg {
#############################    Check Argument    ##################################
	Version=$1
	Config_File=$2
	FMail=$3
	Mail=$4
	Smail=$5
	if [[ $Version = "-h" || $Version = "" ]]
	then
		print "\nUsage : ccIcmBuild < Version Number > [ -m < Email Address > ] [ -SM ]\n"
		print "[ -SM ] : Send an email for starting ICM build"
		print "Example : ccIcmBuild 750 -m eyalar@amdocs.com\n"
		exit
	fi
	if [[ ! -d $HOME/ccIcmBuild/$Version/config ]]
	then
		print "\nError: The Directory $HOME/ccIcmBuild/$Version/config is missing \n"
		exit
	fi
	if [[ ! -f $Config_File ]]
	then
		print "\nError: The Configuration File $Config_File Is Missing \n"
		exit
	fi
	if [[ $FMail != "" && $FMail != "-m" ]]
	then
		print "\nUsage : ccIcmBuild < Version Number > [ -m < Email Address > ] [ -SM ]\n"
		print "[ -SM ] : Send an email for starting ICM build"
                print "Example : ccIcmBuild 750 -m eyalar@amdocs.com\n"
                exit
        fi
	if [[ $FMail = "-m" && $Mail = "" ]]
	then
                print "\nUsage : ccIcmBuild < Version Number > [ -m < Email Address > ] [ -SM ]\n"
		print "[ -SM ] : Send an email for starting ICM build"
                print "Example : ccIcmBuild 750 -m eyalar@amdocs.com\n"
                exit
        fi
	if [[ $Smail != "-SM" && $Smail != "" ]]
        then
                print "\nUsage : ccIcmBuild < Version Number > [ -m < Email Address > ] [ -SM ]"
                print "[ -SM ] : Send an email for starting ICM build"
                print "Example : ccIcmBuild 750 -m eyalar@amdocs.com\n"
                exit
        fi

#####################################################################################
}
function Check_Build {
############################  Check If Build Pass  ##################################
	CheckBuild=$1
	Machine=$2
	User=$3
	j=$4
	Version=$5
	Result=$6
	if [[ ${CheckBuild[$j]} = "L" ]]
	then
		Build_Path="~/Line/Data/$Version"
		Build_Log=`ssh ${User[$j]}@${Machine[$j]} "ls -tr $Build_Path/ccManProdRep*.rep | tail -1"`
		Result=`ssh ${User[$j]}@${Machine[$j]} "cat $Build_Log | grep Build | grep passed"`
	elif [[ ${CheckBuild[$j]} = "S" ]]
	then	
		Build_Path="~/log/ccManProdRep.ksh"
		Build_Log=`ssh ${User[$j]}@${Machine[$j]} "ls -tr $Build_Path/ccManProdRep*$Version*.rep | tail -1"`
		Result=`ssh ${User[$j]}@${Machine[$j]} "cat $Build_Log | grep Build | grep passed"`
	else
		Result="Build passed"
	fi
#####################################################################################
}

########################        Send Start Build Email     ##########################

function SendStartEmail {
	Mail=$1
        Array_File=$2
        Version=$3
        Machine=$4
        User=$5
	Mail_Log=$HOME/log/ccIcmBuild/$Version/ICM_Mail_LOG.`/usr/bin/date '+%Y%m%d_%H%M%S'`
	touch $Mail_Log
	echo "Hi All\n" >> $Mail_Log
	HARVESTDIR=`ssh ${User[1]}@${Machine[1]} "grep HARVESTDIR ~/data/cc_local.dat" | awk -F= '{print $2}'`
	Icm_Build_Num=`ssh ${User[1]}@${Machine[1]} "setenv SHELL /usr/local/bin/tcsh;source /sdkhome/sdk/SDKRoot/.ccmngr_cshrc;source /sdkhome/sdk/SDKRoot/.ccmngr_login;$HARVESTDIR/bin/buildCounter Daily $Version 0" | grep : | awk -F: '{print $2}'`
	echo "ICM build$Icm_Build_Num started for version $Version , The build will run for all the below products :\n" >> $Mail_Log
	cat $Array_File | awk -F":" '{print $2}' | sort -u >> $Mail_Log
	echo "\nThanks : CC team\n" >> $Mail_Log
	mailx -s "ICM build$Icm_Build_Num started for version $Version" $Mail < $Mail_Log

#####################################################################################
}

###################   Send Email & Create ICM report for UMB    #####################
function SentMail {
	Mail=$1
	Array_File=$2
	Version=$3
	Machine=$4
	User=$5
	ProdFailed=""
	Flag="0"
	IcmResult="Passed"
	ALL_PROD=""
	Mail_Log=$HOME/log/ccIcmBuild/$Version/ICM_Mail_LOG.`/usr/bin/date '+%Y%m%d_%H%M%S'`
	touch $Mail_Log
	echo "Hi All\n" >> $Mail_Log
	HARVESTDIR=`ssh ${User[1]}@${Machine[1]} "grep HARVESTDIR ~/data/cc_local.dat" | awk -F= '{print $2}'`
	Icm_Build_Num=`ssh ${User[1]}@${Machine[1]} "setenv SHELL /usr/local/bin/tcsh;source /sdkhome/sdk/SDKRoot/.ccmngr_cshrc;source /sdkhome/sdk/SDKRoot/.ccmngr_login;$HARVESTDIR/bin/buildCounter Daily $Version 0" | grep : | awk -F: '{print $2}'`
	Icm_Build_Num=`echo $Icm_Build_Num`
	echo "ICM build number $Icm_Build_Num was finished , below all products results & builds numbers :\n" >> $Mail_Log
	List=`cat $Array_File | awk -F":" '{print $2":"$3":"$4}' | sort -u`
	for Arg in `echo $List`
		do
			PROD=`echo $Arg | awk -F: '{print $1}'`
			ALL_PROD=`echo $ALL_PROD $PROD"`
			CPU=`echo $Arg | awk -F: '{print $2}'`
			USER=`echo $Arg | awk -F: '{print $3}'`
			HARVESTDIR=`ssh $USER@$CPU "grep HARVESTDIR ~/data/cc_local.dat" | awk -F= '{print $2}'`
			Build_Num=`ssh $USER@$CPU "setenv SHELL /usr/local/bin/tcsh;source /sdkhome/sdk/SDKRoot/.ccmngr_cshrc;source /sdkhome/sdk/SDKRoot/.ccmngr_login;$HARVESTDIR/bin/buildCounter Daily $Version 0 $PROD" | grep : | awk -F: '{print $2}'`
			Build_Num=`echo $Build_Num`
			ManProdFile=`ssh $USER@$CPU "ls ~/log/ccManProdRep.ksh | grep $Version | grep $PROD | tail -1"`
			Result=`ssh $USER@$CPU "cat ~/log/ccManProdRep.ksh/$ManProdFile | grep Build | grep passed"`
			if [[ $Result != "Build passed" ]]
			then
				Result="Build Failed"
				Flag="0"
				ProdFailed="$ProdFailed $PROD"
				IcmResult="Failed"
			fi
			Mark=`ssh $USER@$CPU "cat ~/log/ccManProdRep.ksh/$ManProdFile | grep Total | grep Build | grep Mark | grep -v Failed"`
			echo "$Result for product $PROD , $Mark , Build Number Is : ${Icm_Build_Num}_${Build_Num}\n" >> $Mail_Log
		done
	echo "\nUMB link : http://hpbl802:58808/" >> $Mail_Log
	echo "\nThanks : CC team\n" >> $Mail_Log
	ICM_BUILD_NUM=`echo $Icm_Build_Num`
	mailx -s "ICM version $Version build #$ICM_BUILD_NUM on ${Machine[1]}" $Mail < $Mail_Log
	Sbuild=`cat $Array_File | awk -F":" '{print $11}' | head -1`
	Ebuild=`cat $Array_File | awk -F":" '{print $11}' | tail -1`
	TimeStamp=`/usr/bin/date '+%Y%m%d_%H%M%S'`
	UMB_Dir="$HOME/CCMSS/icm/v$Version/64OG/$Sbuild/BuildInfo/"
	mkdir -p $UMB_Dir
	UMB_File="Build_Info_v${Version}_icm_${CCVARIANT}.txt"
	touch $UMB_Dir/$UMB_File
	echo Machine=${Machine[1]} >> $UMB_Dir/$UMB_File
	echo Product=icm >> $UMB_Dir/$UMB_File
	echo Core_Product=ICM >> $UMB_Dir/$UMB_File
	echo Version=v$Version >> $UMB_Dir/$UMB_File
	echo Release=N/A >> $UMB_Dir/$UMB_File
	echo Variant=64OG >> $UMB_Dir/$UMB_File
	echo Build_Number=$ICM_BUILD_NUM >> $UMB_Dir/$UMB_File
	echo Build_Product_Start_Time=$Sbuild >> $UMB_Dir/$UMB_File
	echo Build_Product_End_Time=$Ebuild >> $UMB_Dir/$UMB_File
	echo Build_Product_Status=Finished >> $UMB_Dir/$UMB_File
	echo Mandatory_Products_Result=$IcmResult >> $UMB_Dir/$UMB_File
	echo Exe_Failure=N/A >> $UMB_Dir/$UMB_File
	echo Jars_Failure=N/A >> $UMB_Dir/$UMB_File
	echo Shared_Libraries_Failure=N/A >> $UMB_Dir/$UMB_File
	echo Compilation_Failure=N/A >> $UMB_Dir/$UMB_File
	echo Total_Errors_Number=N/A >> $UMB_Dir/$UMB_File
	echo Total_Warnings_Number=N/A >> $UMB_Dir/$UMB_File
	echo Running_Modules= >> $UMB_Dir/$UMB_File
	echo Failed_Modules=$ProdFailed >> $UMB_Dir/$UMB_File
	echo Finished_Modules=$ALL_PROD >> $UMB_Dir/$UMB_File
	echo Gdd_Build_Result=N/A >> $UMB_Dir/$UMB_File
	echo Duplicated_Main_Symbol_Result=N/A >> $UMB_Dir/$UMB_File
	echo Duplicate_Flds_Result=N/A >> $UMB_Dir/$UMB_File
	echo Umb_Request_Id=N/A >> $UMB_Dir/$UMB_File
#####################################################################################
}
#############################          Main        ##################################


##### Define Variables ######
Version=$1
FMail=$2
Mail=$3
Smail=$4
Config_File="$HOME/ccIcmBuild/$Version/config/Config_ICM"
Array_File="$HOME/ccIcmBuild/$Version/config/Array_File"
ICM_LOG="$HOME/log/ccIcmBuild/$Version/ICM_LOG".`/usr/bin/date '+%Y%m%d_%H%M%S'`
Check_Arg "$Version" "$Config_File" "$FMail" "$Mail" "$Smail"
mkdir -p $HOME/log/ccIcmBuild/$Version
touch $ICM_LOG
ICM_Flag=0
Line_Num=`cat $Config_File | grep ":" | wc -l`
i=0
#############################

LoadArray Num ProdName Machine User StartBuild BuildTime BuildDep CheckBuild BuildStat BuildSTime BuildRTime ProcessID
PrintArray "$Line_Num" "$Array_File" Num ProdName Machine User StartBuild BuildTime BuildDep CheckBuild BuildStat BuildRTime BuildSTime ProcessID

if [[ $Smail = "-SM" ]]
then
        SendStartEmail $Mail $Array_File $Version Machine User
fi

until ((ICM_Flag==1))
do
	i=$(($i + 1))
	if [[ $i -gt $Line_Num ]]	
	then
		i=1
	fi
	if [[ ${BuildDep[$i]} = "0" && ${BuildStat[$i]} = "0" ]]
	then
		BuildStat[$i]=1
		RunBuild ProdName Machine User StartBuild BuildSTime ProcessID $i $ICM_LOG
		PrintArray "$Line_Num" "$Array_File" Num ProdName Machine User StartBuild BuildTime BuildDep CheckBuild BuildStat BuildRTime BuildSTime ProcessID
	fi
	if [[ ${BuildStat[$i]} = "1" ]]
	then
		CheckProcess ProcessID BuildStat $i
		if [[ ${BuildStat[$i]} = "2" ]]
		then
			Check_Build CheckBuild Machine User $i $Version $Result
			if [[ $Result != "Build passed" ]]
			then
				print "Build Failed for ${ProdName[$i]} on ${Machine[$i]}, ICM Build Stop Now\n" >> $ICM_LOG
				exit
			else
				print "Build Pass for ${ProdName[$i]} on ${Machine[$i]}\n" >> $ICM_LOG
			fi
				PrintArray "$Line_Num" "$Array_File" Num ProdName Machine User StartBuild BuildTime BuildDep CheckBuild BuildStat BuildRTime BuildSTime ProcessID
		fi
	fi
	if [[ ${BuildDep[$i]} != "0" && ${BuildStat[$i]} = "0" ]]
	then
		CheckDep $i BuildDep BuildStat
		if [[ ${BuildStat[$i]} = "1" ]]
		then
			RunBuild ProdName Machine User StartBuild BuildSTime ProcessID $i $ICM_LOG
			PrintArray "$Line_Num" "$Array_File" Num ProdName Machine User StartBuild BuildTime BuildDep CheckBuild BuildStat BuildRTime BuildSTime ProcessID
		fi
	fi
	if [[ ${BuildStat[$i]} = "1" ]]
	then
		CheckTime ProcessID BuildStat BuildTime BuildRTime BuildSTime ProcessID $i
		if [[ ${BuildStat[$i]} = "3" ]]
		then
			print "Build Time For ${ProdName[$i]} on ${Machine[$i]} Is Over\n" >> $ICM_LOG 
			PrintArray "$Line_Num" "$Array_File" Num ProdName Machine User StartBuild BuildTime BuildDep CheckBuild BuildStat BuildRTime BuildSTime ProcessID
		fi
	fi
	CheckBuildDone BuildStat "$Line_Num" "$ICM_LOG" "$Mail" "$Array_File" "$Version" "$FMail" Machine User
done
