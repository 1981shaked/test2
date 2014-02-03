#!/bin/ksh
#
# findClass.ksh
#
# Usage: findClass.ksh <class string> 
# 
#################################

export string=$1

for  file in $(find . -type f -name "*[ej]ar")

do
	echo $file
	jar -tvf $file|grep ${string}
done
