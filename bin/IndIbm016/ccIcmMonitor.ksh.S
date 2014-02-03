#!/usr/bin/ksh

Ver=$1

if [[ $Ver = "-h" || $Ver = "" ]]
        then
                print "\nUsage : ccIcmMonitor < Version Number >\n"
                print "Example : ccIcmMonitor 750\n"
                exit
fi
if [[ ! -d $HOME/ccIcmBuild/$Ver ]]
        then
                print "\nError: The version $Ver is missing under the directory $HOME/ccIcmBuild/ \n"
                exit
fi

Array_File="$HOME/ccIcmBuild/$Ver/config/Array_File"
Temp_log=$HOME/ccIcmBuild/$Ver/config/Temp_log
Array_File_Stat="$HOME/ccIcmBuild/$Ver/config/Array_File_Stat"
touch $Array_File_Stat

until ((2==1))
do
	rm -f $Array_File_Stat
	cp $Array_File $Array_File_Stat
	if [[ -f $Array_File_Stat ]] then	
		rm -f $Temp_log
		touch $Temp_log
		echo "                                                    " >> $Temp_log
		echo "                                                    " >> $Temp_log
		echo "                                           +---------------------+" >> $Temp_log
		echo "                                           |  ICM Build Monitor  |" >> $Temp_log
                echo "                                           +---------------------+" >> $Temp_log
		echo "                                                    " >> $Temp_log
                echo "+=====+==========+============+==========+======================+==========+==========+============+============+" >>$Temp_log
                echo "| Num | Product  |   Machine  | Account  |       Command        | Depended |  Status  | Start Date | Start Time |" >>$Temp_log
                echo "+=====+==========+============+==========+======================+==========+==========+============+============+" >>$Temp_log
		while read Arg
		do
			   Num=`echo $Arg | awk -F: '{print $1}'`
			   Prod=`echo $Arg | awk -F: '{print $2}'`
                           Machine=`echo $Arg | awk -F: '{print $3}'`
		           User=`echo $Arg | awk -F: '{print $4}'`
			   Depend=`echo $Arg | awk -F: '{print $7}'`
		           Status=`echo $Arg | awk -F: '{print $9}'`	
			   Command=`echo $Arg | awk -F: '{print $5}' | awk -F" " '{print $1}' | awk -F"/" '{print $7}'`
		           if [[ $Status = "0" ]] then
				Status="Waiting"
		           elif [[ $Status = "1" ]] then			
				Status="Started"
			   elif [[ $Status = "2" ]] then                 
                                Status="Finished"
			   elif [[ $Status = "3" ]] then                 
                                Status="Failed"
			   fi
			   TimeS=`echo $Arg | awk -F: '{print $11}'`
			   if [[ $TimeS = "0000" ]] then
			    	TimeS="00000000_000000"
			   fi
			   	Date=`echo $TimeS | awk -F_ '{print $1}'`
			   	Dyear=`echo $Date | cut -c 1-4`
			   	Dmounth=`echo $Date | cut -c 5-6`
			  	 Dday=`echo $Date | cut -c 7-8`
			  	 FullDate=`echo $Dday/$Dmounth/$Dyear`
			   	Time=`echo $TimeS | awk -F_ '{print $2}'`
			  	 Htime=`echo $Time | cut -c 1-2`
			   	Hmin=`echo $Time | cut -c 3-4`
			   	FullTime=`echo $Htime:$Hmin`
			   echo "$Num" "$Prod" "$Machine" "$User" "$Command" "$Depend" "$Status" "$FullDate" "$FullTime" | awk '{printf "|  %-2s |  %-7s | %-10s | %-3s | %-20s |    %-5s | %-8s | %-8s |    %-5s   |\n",$1,$2,$3,$4,$5,$6,$7,$8,$9}' >> $Temp_log
			done < $Array_File
			echo "+=====+==========+============+==========+======================+==========+==========+============+============+" >>$Temp_log
	fi
	clear
	cat $Temp_log
	sleep 7
done
