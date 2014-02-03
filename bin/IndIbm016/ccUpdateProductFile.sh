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
set Task_Ver = "Infra"
set Infra_State = "Infra"
set Build_State = "Build"
set Completed_State = "Completed"
set CO_Process_Name = "CheckOut for Upload"
set CI_Process_Name = "CheckIn for Upload"
set Promote_to_Rev = "Promote to Reviewer Approval"
set Promote_to_B = "Promote to Next State"
set Log_File = $HOME/tmp/UpdateFile.log
set Topic_Name = `pwd | awk -F $CCVER '{print $2}'`
set Task_name = "Update_Build_Files_"`$CCMNGRHOME/bin/timestamp`
set Src_location=`echo $RunDir `
set Broker_name=`echo $BROKERNAME `
set Client_Path=`pwd`
set Usr_Pass="-usr $Target_XC_User -pw $Target_XC_PW" 
set Product_Name=`echo $CCPROD`
set Ver_Name=`echo $CCPRODVER`
set View_Path="\product\${Product_Name}\${Ver_Name}\config"

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

/opt/CA/harvest7/bin/hcp -en "${Task_Ver}" -b $Broker_name $Usr_Pass -st "${Infra_State}" -at $Target_XC_User "${Task_name}"

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

	#-----------------Check out for Upload
	/opt/CA/harvest7/bin/hco -r -up -en "${Task_Ver}" -b $Broker_name $Usr_Pass -st "${Infra_State}" -vp "${View_Path}" -cp "${Client_Path}" -pn "$CO_Process_Name" -p "$Task_name" -s $File_name
	
	if ( $? == 0 ) then
		echo "SUCCESS: checkout" >> ${Log_File}
	else
		echo "ERROR: checkout "
		cat hco.log >> ${Log_File}
	endif
	
	
	#-----------------Moving back the new files - override the checked out files with the new files
  #echo "Overriding files with new files before check in" >> 
	mv -f ${File_name}.update $File_name

	#-----------------Check in for Upload
	/opt/CA/harvest7/bin/hci -nd -if ne -en "${Task_Ver}" -b $Broker_name $Usr_Pass -st "${Infra_State}" -vp "$View_Path" -cp "${Client_Path}" -pn "$CI_Process_Name" -p "$Task_name" -s $File_name
	
	if ( $? == 0 ) then
		echo "SUCCESS: check in "  >> ${Log_File}
	else
		echo "ERROR: check in "
		cat hci.log >> ${Log_File}
	endif

	echo "-------------------------------------------------------------------------"   >> ${Log_File}

end #end of foreach


cd $RunDir
\rm -f h??.log
exit
