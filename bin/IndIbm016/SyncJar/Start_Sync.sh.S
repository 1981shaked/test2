#!/usr/local/bin/tcsh

# basic initialization
#----------------------

source $HOME/.login                     ###


#------------
# Usage
#------------

if ($#argv == 2) then
	set Ver = $1
  set SyncPropertyFile = $2
  set force_hdv = ""
else if ($#argv == 3) then
	set Ver = $1
  set SyncPropertyFile = $2
  set force_hdv = $3
	if ($force_hdv == "force") then 
		if (! -f $HOME/bin/ccQueries.pl ) then
				echo "force option needs $HOME/bin/ccQueries.pl script"
				exit 1
		endif
	endif
else
  echo "\nUsage : $0:t <Version Number> <Properties_file_name> <Build Number - Not Mandatory> \n "
  echo "e.g. : $0:t 702 CRM_810.roperties"
  exit 1
endif

#--------------------------------------
#     Global Initialization          --
#--------------------------------------
### note! SyncJar script and property files must be under same directory ($HOME/bin/SyncJar)  ###
cd $HOME/bin/SyncJar
if (! -f $2) then
	echo "propery file: $2 does not exist "
	exit (1)
endif
set RunDir = `pwd`
set timestamp_task = `timestamp` ###
set date = `echo $timestamp_task |cut -f 1 -d _`
set Task_Ver = "Tasks $Ver"
set Dev_State = "Development"
set Rev_State = "Reviewer Approval"
set Build_State = "Build"
set CO_Process_Name = "CheckOut for Upload"
set CI_Process_Name = "CheckIn for Upload"
set Promote_to_Rev = "Promote to Reviewer Approval"
set Promote_to_B = "Promote to Build"
set Promote_to_BA = "Promote to Build Approval"
set Demote_to_canceled = "Demote to Canceled"
set Keep_Backup = 5

echo "---- START SYNC PROCESS : ${timestamp_task} "
echo "-------------------------------------------------------------------------"

#------------------------------------------
# Creating  log dir and Task summarize.log
#------------------------------------------

set LogDir=$HOME/log/SyncJar/$date
if (! -d $LogDir) then
       echo "\n Creating Log dir in $LogDir "
       mkdir -p $LogDir
endif
set Task_List=$LogDir/Task_List_${timestamp_task}
set Task_List_TMP=$LogDir/Task_List_${timestamp_task}_TMP
if (! -f $Task_List ) then
	touch $Task_List
endif


####################################################
echo "##### loop 1: parsing property file     ######" 
####################################################
foreach line ( `cat $SyncPropertyFile ` )
		set ignore = `echo $line | cut -b 1`	# ignore comment line in property file
		if ( ${ignore} != "#" ) then
				set Source_app=`echo $line | awk -F":" '{print $1}' `
				set Target_app=`echo $line | awk -F":" '{print $2}' `
				set File_name=`echo $line | awk -F":" '{print $3}' `
				eval set Src_location=`echo $line | awk -F":" '{print $4}' `
				set Target_XC_User=`echo $line | awk -F":" '{print $5}' `
				set Target_XC_PW=`echo $line | awk -F":" '{print $6}' `
				set Broker_name=`echo $line | awk -F":" '{print $7}' `
				set View_Path=`echo $line | awk -F":" '{print $8}' `
				set Usr_Pass="-usr $Target_XC_User -pw $Target_XC_PW" 
				set Promote_BA_flag=`echo $line | awk -F":" '{print $9}' `
				set Mail_List=`echo $line | awk -F":" '{print $10}' `
				set connection_string=`echo $line | awk -F":" '{print $11}' `
				set Build_Number=`buildCounter Daily $Ver 0 ${Source_app}| awk '{print $7}'`
				set Src_tmp_dir=${HOME}/SyncJar/${Ver}/${Source_app}/${Target_app}/${Build_Number}
				set Warning_flag_Local  = 0
				cd
				mkdir -p SyncJar                            #------------------------ 
				mkdir -p ${Src_tmp_dir}                     # setting target directory
				/usr/bin/chmod +w ${Src_tmp_dir}/*          #-------------------------
				set Log_File_Name = "${0:t}.V${Ver}.${Build_Number}.${timestamp_task}.${Source_app}_to_${Target_app}"    # the above chmod command will result error msg (chmod: can't access...) when files do not exist -
				set Full_pair_log = "${LogDir}/${Log_File_Name}"                                                         # this err msg can be ignored                                                                     
				if (! -f $Full_pair_log ) then                                                                            #----------------------------------------                                                         
						touch $Full_pair_log                                                                                 # Creating log file (uniq per Sync pair)                                                          
				endif     # end checking if log exist                                                                    #----------------------------------------                                                         
				if (${Src_location} != "") then
						if ( -f ${Src_location}/${File_name} ) then	                                                            
								cp -f ${Src_location}/${File_name} ${Src_tmp_dir}/.         #---------------------------------------
								set cp_cmd_ok=$?                                            # copy file to tmp target directory     
						else                                                            #---------------------------------------
								set cp_cmd_ok=1
						endif  # end checking if file exist
						if ( $cp_cmd_ok != 0 ) then
								set Warning_flag_Local  = 1		
						endif	 
				endif
				if ( ! -d ${Src_tmp_dir} ) then                                                  #--------------------------------------------
						echo " ERROR:  ${Src_tmp_dir} Directory  does not exist"                     #  make sure jars exists in source directory 
						echo " Process Failed and Stoppped Please check log file"                    #--------------------------------------------
						exit(1)
						set fileCount=`ll -f | wc -l`
						if ( ${fileCount} <= 3 ) then
								echo "${Src_tmp_dir} is empty "
								exit (1)
						endif
				endif
				echo "handling $File_name "
				echo "handling $File_name " >> ${Full_pair_log} 
				if ("${Warning_flag_Local}" == 1 ) then
						echo "WARNING: ${Src_location}/${File_name} was not copied to ${Src_tmp_dir}" >> ${Full_pair_log} 
						set Task_name="_Sync_${Source_app}_to_${Target_app}_V${Ver}_bn_${Build_Number}_$timestamp_task"
				else
						cd ${Src_tmp_dir}
						set Task_name="_Sync_${Source_app}_to_${Target_app}_V${Ver}_bn_${Build_Number}_$timestamp_task"
						set exist=`cat $Task_List | grep "$Task_name" | wc -l`
						if ( ${exist} == 0 ) then
								echo "${Task_name}:${Source_app}:${Target_app}:${Broker_name}:${Target_XC_User}:${Target_XC_PW}:error_flag_0:${Promote_BA_flag}:${Mail_List}:" >> $Task_List
				endif
				if ("${Warning_flag_Local}" == 1 )then
						rm -fr $Task_List_TMP
						sed '/^'${Task_name}'/s/error_flag_0/error_flag_1/g' ${Task_List} > ! ${Task_List_TMP}
						mv -f $Task_List_TMP $Task_List	
				endif 
				hcp -en "${Task_Ver}" -b $Broker_name $Usr_Pass -st "${Dev_State}" -at $Target_XC_User "${Task_name}" 
				set cmd_ok=$?
				if ( $cmd_ok == 0 )   then
						echo "SUCCESS: create package"  >> ${Full_pair_log}
				else if ( $cmd_ok == 3 ) then
						echo "Exist: create package"  >> ${Full_pair_log}
				else
						echo "ERROR: create packege"
						less hcp.log >> ${Full_pair_log}
						rm -fr $Task_List_TMP
						sed '/^'${Task_name}'/s/error_flag_0/error_flag_1/g' ${Task_List} > ! ${Task_List_TMP}
						mv -f $Task_List_TMP $Task_List
				endif
				cd ${Src_tmp_dir}
				mv $File_name ${File_name}.new
				alias hco_command 'hco -r -op as -up -en "${Task_Ver}" -b $Broker_name $Usr_Pass -st "${Dev_State}" -vp "/$View_Path" -pn "$CO_Process_Name" -p "$Task_name" $File_name'
				alias good_hco 'echo "SUCCESS: checkout" >> ${Full_pair_log};echo "SUCCESS: checkout";mv -f ${File_name}.new $File_name'
				alias bad_hco 'echo "ERROR: checkout ";less hco.log >> ${Full_pair_log};rm -fr $Task_List_TMP'
				alias hci_command 'echo running hci command ;hci -nd -if ne -en "${Task_Ver}" -b $Broker_name $Usr_Pass -st "${Dev_State}" -vp "/$View_Path" -pn "$CI_Process_Name" -p "$Task_name" -de "Build $Build_Number" $File_name'
				alias good_hci 'echo "SUCCESS: checkin "  >> ${Full_pair_log};echo "SUCCESS: check in "'
				alias bad_hci 'echo "ERROR: checkin" >>${Full_pair_log} ;echo "ERROR: checkin ";less hci.log >> ${Full_pair_log};rm -fr $Task_List_TMP'
				alias hdv_command 'hdv -en "${Task_Ver}" -b $Broker_name $Usr_Pass -st "${Dev_State}" -vp "/$View_Path" $File_name'
				alias good_hdv 'echo "SUCCESS: delete locked version "  >> ${Full_pair_log};echo "SUCCESS: delete locked version "'
				alias bad_hdv 'echo "ERROR: delete locked version" >>${Full_pair_log} ;echo "ERROR: delete locked version ";less hdv.log >> ${Full_pair_log};rm -fr $Task_List_TMP'
				if ($force_hdv != "force") then
						hco_command
						if ( $? == 0 ) then 
								good_hco
								hci_command
								if ( $? == 0 ) then
										good_hci
								else
										bad_hci
										sed '/^'${Task_name}'/s/error_flag_0/error_flag_1/g' ${Task_List} > ! $Task_List_TMP
										mv -f $Task_List_TMP $Task_List
								endif
						else
								bad_hco
								sed '/^'${Task_name}'/s/error_flag_0/error_flag_1/g' ${Task_List} > ! $Task_List_TMP
								mv -f $Task_List_TMP $Task_List
						endif
				endif
				if ($force_hdv == "force") then
						set filelocked=`$HOME/bin/ccQueries.pl -v $Ver -que get_locked_file -con $connection_string|grep $File_name | wc -l`
						if ($filelocked != 0) then
								echo "$File_name is locked, deleting locked version"
								hdv_command
								if ( $? == 0 ) then
										good_hdv
										hco_command
										if ( $? == 0 ) then
												good_hco
												hci_command
												if ( $? == 0 ) then
														good_hci
												else
														bad_hci
														sed '/^'${Task_name}'/s/error_flag_0/error_flag_1/g' ${Task_List} > ! $Task_List_TMP
														mv -f $Task_List_TMP $Task_List
												endif
												echo "-------------------------------------------------------------------------"   >> ${Full_pair_log}
												echo "-------------------------------------------------------------------------"
										else
												bad_hco
												sed '/^'${Task_name}'/s/error_flag_0/error_flag_1/g' ${Task_List} > ! $Task_List_TMP
												mv -f $Task_List_TMP $Task_List
										endif
								else
										bad_hdv
										sed '/^'${Task_name}'/s/error_flag_0/error_flag_1/g' ${Task_List} > !  $Task_List_TMP
										mv -f $Task_List_TMP $Task_List
								endif
						else
								hco_command
								if ( $? == 0 ) then
										good_hco
										hci_command
										if ( $? == 0 ) then
												good_hci
										else
												bad_hci
												sed '/^'${Task_name}'/s/error_flag_0/error_flag_1/g' ${Task_List} > ! $Task_List_TMP
												mv -f $Task_List_TMP $Task_List
										endif
										echo "-------------------------------------------------------------------------"   >> ${Full_pair_log}
										echo "-------------------------------------------------------------------------"
								else
										bad_hco
										sed '/^'${Task_name}'/s/error_flag_0/error_flag_1/g' ${Task_List} > ! $Task_List_TMP
										mv -f $Task_List_TMP $Task_List
								endif   
						endif
				endif
		endif
end       

####################################################
echo "##### loop 2: parsing Task list         ######"  
####################################################
foreach Task_line ( `cat $Task_List ` )

 set Task_name=`echo $Task_line | awk -F":" '{print $1}' `
 set Source_app=`echo $Task_line | awk -F":" '{print $2}' `
 set Target_app=`echo $Task_line | awk -F":" '{print $3}' `
 set Broker_name=`echo $Task_line | awk -F":" '{print $4}' `
 set Target_XC_User=`echo $Task_line | awk -F":" '{print $5}' `
 set Target_XC_PW=`echo $Task_line | awk -F":" '{print $6}' `
 set Usr_Pass="-usr $Target_XC_User -pw $Target_XC_PW" 
 set Error_Flag=`echo $Task_line | awk -F":" '{print $7}' `
 set Promote_BA_flag=`echo $Task_line | awk -F":" '{print $8}' `
 set Mail_List=`echo $Task_line | awk -F":" '{print $9}' `

 #----------------------------------------
 # Creating log file (uniq per Sync pair)
 #----------------------------------------

 set Log_File_Name = "${0:t}.V${Ver}.${Build_Number}.${timestamp_task}.${Source_app}_to_${Target_app}"
 set Full_pair_log = "${LogDir}/${Log_File_Name}"
 if (! -f $Full_pair_log) then
	touch $Full_pair_log
 endif
 
 echo "Promote Task : $Task_name " >> ${Full_pair_log}
 
 if ( -f $HOME/bin/ccQueries.pl )then 
 	set NumOfFiles=`$HOME/bin/ccQueries.pl -v $Ver -que get_files_from_task -opt "$Task_name" | wc -l`
 	if ($NumOfFiles == 0) then
 		hdp -en "$Task_Ver" -b $Broker_name $Usr_Pass -st "${Dev_State}" -pn "${Demote_to_canceled}" "$Task_name"
 		if ($? == 0) then
 			echo "SUCCESS: no files in $Task_name, demoting it to Canceled"  >> ${Full_pair_log}
 		else
 			echo "ERROR: Demote to Canceled"
 			less hdp.log >> ${Full_pair_log}
			rm -fr $Task_List_TMP
			set Error_Flag="error_flag_1"
    	sed '/^'${Task_name}'/s/error_flag_0/'${Error_Flag}'/g' ${Task_List} > ! $Task_List_TMP
    	mv -f $Task_List_TMP $Task_List
 		endif
 	else
 		hpp -en "$Task_Ver" -b $Broker_name $Usr_Pass -st "${Dev_State}" -pn "${Promote_to_Rev}" "$Task_name"
 		if ($? == 0) then 
    	echo "SUCCESS: promote to Reviewer Approval"  >> ${Full_pair_log}
 		else
 			echo "ERROR: promote to Reviewer Approval"
 			less hpp.log >> ${Full_pair_log}
			rm -fr $Task_List_TMP
			set Error_Flag="error_flag_1"
    	sed '/^'${Task_name}'/s/error_flag_0/'${Error_Flag}'/g' ${Task_List} > ! $Task_List_TMP
    	mv -f $Task_List_TMP $Task_List
 		endif
 		hpp -en "$Task_Ver" -b $Broker_name $Usr_Pass -st "${Rev_State}"  "${Promote_to_B}" "$Task_name"
 		if ($? == 0) then 
    	echo "SUCCESS: promote to Build"  >> ${Full_pair_log}
 		else
    	echo "ERROR: promote to Build"
    	less hpp.log >> ${Full_pair_log}
			rm -fr $Task_List_TMP
			set Error_Flag="error_flag_1"
			sed '/^'${Task_name}'/s/error_flag_0/'${Error_Flag}'/g' ${Task_List} > ! $Task_List_TMP
    	mv -f $Task_List_TMP $Task_List
 		endif
 		if ( "${Promote_BA_flag}" != "0" ) then
 			hpp -en "${Task_Ver}" -b $Broker_name $Usr_Pass -st "${Build_State}"  "${Promote_to_BA}" "$Task_name"
 			if ($? == 0) then 
 				echo "SUCCESS: promote to Build Approval"  >> ${Full_pair_log}
 			else
 				echo "ERROR: promote to Build Approval"
 				less hpp.log >> ${Full_pair_log} 
				rm -fr $Task_List_TMP
				set Error_Flag="error_flag_1"
				sed '/^'${Task_name}'/s/error_flag_0/'${Error_Flag}'/g' ${Task_List} > ! $Task_List_TMP
    		mv -f $Task_List_TMP $Task_List
 			endif 
 		endif
 	endif
 else
 	hpp -en "$Task_Ver" -b $Broker_name $Usr_Pass -st "${Dev_State}" -pn "${Promote_to_Rev}" "$Task_name"
 	if ($? == 0) then 
   	echo "SUCCESS: promote to Reviewer Approval"  >> ${Full_pair_log}
 	else
   	echo "ERROR: promote to Reviewer Approval"
   	less hpp.log >> ${Full_pair_log}
     rm -fr $Task_List_TMP
     set Error_Flag="error_flag_1"
     sed '/^'${Task_name}'/s/error_flag_0/'${Error_Flag}'/g' ${Task_List} > ! $Task_List_TMP
     mv -f $Task_List_TMP $Task_List
 		endif
		hpp -en "$Task_Ver" -b $Broker_name $Usr_Pass -st "${Rev_State}"  "${Promote_to_B}" "$Task_name"
 		if ($? == 0) then 
    	echo "SUCCESS: promote to Build"  >> ${Full_pair_log}
 		else
      echo "ERROR: promote to Build"
      less hpp.log >> ${Full_pair_log}
      rm -fr $Task_List_TMP
      set Error_Flag="error_flag_1"
      sed '/^'${Task_name}'/s/error_flag_0/'${Error_Flag}'/g' ${Task_List} > ! $Task_List_TMP
      mv -f $Task_List_TMP $Task_List
 		endif            
	 	if ( "${Promote_BA_flag}" != "0" ) then 
    	hpp -en "${Task_Ver}" -b $Broker_name $Usr_Pass -st "${Build_State}"  "${Promote_to_BA}" "$Task_name"
      if ($? == 0) then 
      	echo "SUCCESS: promote to Build Approval"  >> ${Full_pair_log}
      else
      	echo "ERROR: promote to Build Approval"
        less hpp.log >> ${Full_pair_log} 
        rm -fr $Task_List_TMP
        set Error_Flag="error_flag_1"
        sed '/^'${Task_name}'/s/error_flag_0/'${Error_Flag}'/g' ${Task_List} > ! $Task_List_TMP
        mv -f $Task_List_TMP $Task_List
      endif 
 		endif
	endif
endif
 
 #---------------------------
 # Remove old directories
 #---------------------------
 
 set Search_dir=${HOME}/SyncJar/${Ver}/${Source_app}/${Target_app}/
 touch $Search_dir/Remove_List
 set count_ll=`ls -tr $Search_dir | wc -l`
 if ( $count_ll >  $Keep_Backup ) then
 	set count_rem = `expr $count_ll - $Keep_Backup`
 	foreach line (`ls -rt $Search_dir`)
 		echo $line >> $Search_dir/Remove_List
 	end
	  foreach line (`more $Search_dir/Remove_List | head "-"$count_rem`)
	  	 rm -fR $Search_dir/$line
	  end
 else
 	echo no need to remove old backups , there are less than $Keep_Backup
 endif
 
 rm -f $Search_dir/Remove_List
 
 #----------------------
 # Sending mail status  
 #----------------------
 
 echo "Sending mail status  ${Source_app} - ${Target_app} "
 if ("${Error_Flag}" == "error_flag_0") then
 	set Mail_Subject="Sync V${Ver} ${Source_app} - ${Target_app} #${Build_Number} : SUCCESS"
 else if ("${Error_Flag}" == "error_flag_1") then
 	set Mail_Subject="Sync V${Ver} ${Source_app} - ${Target_app} #${Build_Number} : ERROR"
 else
 	set Mail_Subject="Sync V${Ver} ${Source_app} - ${Target_app} #${Build_Number} : UNKNOWN"
 endif
 
 echo Mail_Subject     :${Mail_Subject}
 echo Mail_List        :${Mail_List}
 echo Full_pair_log    :${Full_pair_log}
 
 mailx -s " ${Mail_Subject} "  ${Mail_List} < ${Full_pair_log}
 
echo "-------------------------------------------------------------------------"
echo "-------------------------------------------------------------------------"   >> ${Full_pair_log}
 
endif     # ignore
end       # foreach
 
echo "----  END  SYNC PROCESS :" `timestamp`
echo "--------------------------- END SYNC PROCESS ----------------------------"  >> ${Full_pair_log}
                     
cd $RunDir

