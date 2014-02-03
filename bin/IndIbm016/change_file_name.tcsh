#! /usr/local/bin/tcsh -f

if ($#argv == 3) then
	set oldstr = $1
	set newstr = $2
	set search_directory = $3
else
	echo "\nUsage : $0:t <Old value> <New value> <Full path>\n "
	echo "e.g. : $0:t 9 3 /jsthome/jst/ccjst/mb_ccjst/bb/cecr3gdd/v77_0"
	exit 1
endif

set Log_File = /tmp/"change_file_name.log" 
echo "Creating a log file change_file_name.log under $HOME/tmp"

if ( -f $Log_File) then
	\rm -f  $Log_File
endif

touch $Log_File

foreach file (`find $search_directory -type f -name "*${oldstr}*"`)
	set filename=`basename $file`
	set newname=`echo $filename | sed "s/$oldstr/$newstr/"`
	set dirname=`dirname $file`
	echo "Coping $filename to $newname under $dirname"
	echo "Coping $filename to $newname under $dirname" >> $Log_File
	mv $dirname/$filename $dirname/$newname
end

exit
