#!/usr/local/bin/tcsh -f

#------------
# Usage
#------------

set Run_Promote = "no"

if ($#argv == 3) then
        set File_List = $1
        set Target_XC_User = $2
        set Target_XC_PW = $3
else
        echo "\nUsage : $0:t <File_name> <Xtrac user> <Xtrac password> <Package_name> <Promote>\n "
        echo "e.g. : $0:t build.xml,build_ccrm9Integration.xml emmal unix11"
        exit 1
endif

echo $1

#--------------------------------------
#         Global Initialization          
#--------------------------------------
 
set RunDir = `/usr/bin/pwd`
set timestamp = `$CCMNGRHOME/bin/timestamp`
set Task_Ver = "Tasks $CCPRODVERNUM" #for example 750
set Dev_State = "Development"
set Rev_State = "Reviewer Approval"
set Build_State = "Build"
set CO_Process_Name = "CheckOut for Upload"
set CI_Process_Name = "CheckIn for Upload"
set Promote_to_Rev = "Promote to Reviewer Approval"
set Promote_to_B = "Promote to Next State"
set Promote_to_BA = "Promote to Build Approval"
set Log_File = $HOME/tmp/UpdateFile.log
set Topic_Name = `pwd | awk -F $CCVER '{print $2}'`
set Task_name = "Update_Build_Files_"`$CCMNGRHOME/bin/timestamp`
set Src_location=`echo $RunDir `
set Broker_name=`echo $BROKERNAME `
set View_Path=`echo $CCBB `$Topic_Name
set Usr_Pass="-usr $Target_XC_User -pw $Target_XC_PW" 

#--------------------------------------------------
#            Defining the log file
#--------------------------------------------------

if ( -f ${Log_File}) then
	\rm -f  ${Log_File}
endif

touch ${Log_File}

echo "The task name is $Task_name"

#--------------------------------------------------
#                 Creating package 
#--------------------------------------------------

/opt/CA/harvest7/bin/hcp -en "${Task_Ver}" -b $Broker_name $Usr_Pass -st "${Dev_State}" -at $Target_XC_User "${Task_name}"

set cmd_ok=$?
 
if ( $cmd_ok == 0 )   then
	echo "SUCCESS: create package"  >> ${Log_File}
else if ( $cmd_ok == 3 ) then
	echo "Exist: create package"  >> ${Log_File}
else
	echo "ERROR: create packege"
	cat hcp.log >> ${Log_File}
endif

foreach File_name (`echo $File_List | sed 's/,/ /g'`)

	#-----------------Moving the file aside (before checkout)
	mv $File_name ${File_name}.update

	#-----------------Check Out
	/opt/CA/harvest7/bin/hco -r -op as -up -en "${Task_Ver}" -b $Broker_name $Usr_Pass -st "${Dev_State}" -vp "/$View_Path" -pn "$CO_Process_Name" -p "$Task_name" $File_name
	if ( $? == 0 ) then
		echo "SUCCESS: checkout" >> ${Log_File}
	else
		echo "ERROR: checkout "
		cat hco.log >> ${Log_File}
	endif

	#-----------------Moving back the new files - override the checked out files with the new files
	# echo "Overriding files with new files before check in" >> 
	mv -f ${File_name}.update $File_name

	#-----------------Check In
	/opt/CA/harvest7/bin/hci -nd -if ne -en "${Task_Ver}" -b $Broker_name $Usr_Pass -st "${Dev_State}" -vp "/$View_Path" -pn "$CI_Process_Name" -p "$Task_name" $File_name
	if ( $? == 0 ) then
		echo "SUCCESS: check in "  >> ${Log_File}
	else
		echo "ERROR: check in "
		cat hci.log >> ${Log_File}
	endif

	echo "-------------------------------------------------------------------------"   >> ${Log_File}

end #end of foreach

#######################################################
#                 Promote to Reviewer Approval
#######################################################

echo "Promote Task to Reviewer Approval: $Task_name "
echo "Promote Task : $Task_name " >> ${Log_File}

/opt/CA/harvest7/bin/hpp -en "$Task_Ver" -b $Broker_name $Usr_Pass -st "${Dev_State}" -pn "${Promote_to_Rev}" "$Task_name"

if ($? == 0) then 
  echo "SUCCESS: promote to Reviewer Approval"  >> ${Log_File}
else
	echo "ERROR: promote to Reviewer Approval"
  cat hpp.log >> ${Log_File}
endif

########################################################
# 						    Promote to Build
########################################################

echo "Promote to Build"

/opt/CA/harvest7/bin/hpp -en "$Task_Ver" -b $Broker_name $Usr_Pass -st "${Rev_State}" "${Promote_to_B}" "$Task_name"
if ($? == 0) then 
	echo "SUCCESS: promote to Build"  >> ${Log_File}
else
	echo "ERROR: promote to Build"
	cat hpp.log >> ${Log_File}
endif 


echo "Promote to Build Approval"

/opt/CA/harvest7/bin/hpp -en "$Task_Ver" -b $Broker_name $Usr_Pass -st "Build" "${Promote_to_BA}" "$Task_name"
if ($? == 0) then
        echo "SUCCESS: promote to Build Approval"  >> ${Log_File}
else
        echo "ERROR: promote to Build Approval"
        cat hpp.log >> ${Log_File}
endif


cd $RunDir
\rm -f h??.log
exit
