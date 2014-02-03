#! /usr/local/bin/tcsh -f

set ver = $1
set fs_size = 0

foreach proj (`ls -d *$1*`)
        set my_tmp = `du -sk $proj | awk -F" " '{print $1}' `
#       echo "$my_tmp"
	@ fs_size = $fs_size + $my_tmp 
end

echo "$fs_size"

exit
