#! /usr/local/bin/tcsh -fx

set ver = $1
set prod = $2
set fs_size = 0

foreach proj (`show_str.pl -P $prod -v $ver | awk -F":" '{print $4}' | sort -n | sort -u`)
	cd $CCWPA ; cd ..
        set my_tmp = `du -sk $proj | awk -F" " '{print $1}' `
#       echo "$my_tmp"
	@ fs_size = $fs_size + $my_tmp 
end

echo "$fs_size"

exit
