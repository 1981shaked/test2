#!/bin/ksh
#
# findJar.ksh
#
# Usage: findJar.ksh <jar name> 
# 
#################################

export jarfile=$1

for earfile in $(find . -type f -name "*.ear")

do
	echo "==============================="
	echo $earfile
	jar tvf $earfile |grep ${jarfile}
	echo "==============================="
done
