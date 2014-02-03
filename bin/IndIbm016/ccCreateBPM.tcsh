#! /usr/local/bin/tcsh -f

echo "Creating bmp_files.txt"
set bmp_list_file = "$CCWSCA/bmp_files.txt"

if (-f $bmp_list_file) then 
        /usr/bin/rm -f $bmp_list_file
endif

/usr/bin/find $HOME/bb/cord9maps/$CCVER/. -type f -name "*.bpm" > $bmp_list_file 
#echo "$HOME/bb/gord1core/$CCVER/bpamaps/general/Milestone.bpm" >> $bmp_list_file
