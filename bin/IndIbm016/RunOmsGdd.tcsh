#!/usr/local/bin/tcsh -f

setenv USER $LOGNAME
setenv user $USER
setenv SHELL /usr/local/bin/tcsh

set VER = "$1"
set VVER = v"$VER"

if ( $VER == "" || $VER == "-h" ) then
	echo
	echo "Usage : RunOmsGdd < Version Number >"
	echo
        exit 
endif


if ( ! -d $HOME/"$VVER" ) then
	echo
        echo "Version $VVER doesn't exist under CC home directory"
	echo
        exit
endif

source /sdkhome/sdk/SDKRoot/.ccmngr_cshrc
source /sdkhome/sdk/SDKRoot/.ccmngr_login


$HARVESTDIR/bin/refresh -XML -machine $HOST -pd oms -v $VER -dnum 10 -execute

$HARCCHOME/bin/hbuild -p ordgdd${VER} -v $VER -vrt 64OG -type Daily
$HARCCHOME/bin/hbuild -p osecgdd${VER} -v $VER -vrt 64OG -type Daily

$SDKHOME/$SDKRELEASE/tools/build/bin/CCSwitch -v $VVER -pd oms -vrt 64OG
