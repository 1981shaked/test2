#! /usr/local/bin/tcsh -fx

set ver = $1
set prod = $2
set fs_size = 0
set bb_ver = v`echo $ver | cut -c1-2`_`echo $ver | cut -c3` 
foreach bb (`show_str.pl -P $prod -v v$ver | awk -F":" '{print $5}' | sort -n | sort -u`)
        set my_tmp = `du -sk ${HOME}/bb/$bb/$bb_ver | awk -F" " '{print $1}' `
#       echo "$my_tmp"
	@ fs_size = $fs_size + $my_tmp 
end

echo "$fs_size"

exit
