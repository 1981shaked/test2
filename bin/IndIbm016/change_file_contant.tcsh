#! /usr/local/bin/tcsh -f

if ($#argv == 3) then
	set oldstr = $1
	set newstr = $2
	set file_name = $3
else
	echo "\nUsage : $0:t <Old value> <New value> <Full File name>\n "
	echo "e.g. : $0:t  str1 str2 /jsthome/jst/ccjst/mb_ccjst/bb/cecr3gdd/v77_0/mpgn3_AllowanceMig.c"
	exit 1
endif

set Log_File = $HOME/tmp/"change_file_contant.log" 
echo "Creating a log file $HOME/tmp/change_file_contant.log"

if ( -f $Log_File) then
	\rm -f  $Log_File
endif

touch $Log_File

echo "The file $file_name will be changed now" >> $Log_File
perl -pe "s/$oldstr/$newstr/g" -pi $file_name >> $Log_File

exit
