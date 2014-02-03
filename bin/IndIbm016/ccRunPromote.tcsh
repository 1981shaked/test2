#!/usr/local/bin/tcsh 

if ( "$1" == "" || "$2" == "" || "$3" == "" ) then
	goto EXIT
endif

if ( "$4" != "" && "$4" != "-NP" ) then
	goto EXIT
endif

set PROD = "$1"
set VER = "$2"
set VVER = v"$VER"
set VAR = "$3"
set PFlag = "0"

if ( ! -d $HOME/product/$PROD ) then
        echo "\nProduct $PROD doesn't exsit under $HOME/product\n"
        goto EXIT
endif

if ( ! -d $HOME/"$VVER" ) then
        echo "\nVersion $VVER doesn't exist under CC home directory\n"
        goto EXIT
endif

if ( $VAR != "64OG" && $VAR != "64" && $VAR != "32" ) then
        echo "\nThe variant $VAR doesn't exist" 
        goto EXIT
endif

if ( "$4" == "-NP" ) then
        set PFlag = "1"
endif

setenv USER $LOGNAME
setenv user $USER
setenv SHELL /usr/local/bin/tcsh
source /sdkhome/sdk/SDKRoot/.ccmngr_cshrc
source /sdkhome/sdk/SDKRoot/.ccmngr_login


echo "hupdateFileSystem -l PRODUCTVER -p "$PROD" -r "$VVER" -va "$VAR"" 

#  increase the build counter
$HARVESTDIR/bin/refresh -B -machine $HOST -pd "$PROD" -v "$VER"

if ( "$PFlag" == "0" ) then
	# promote the packages to Build Approval state
	$HARVESTDIR/bin/refresh -P -machine $HOST -pd "$PROD" -v "$VER"
endif

# prepare the xml file and run the refresh command
$HARVESTDIR/bin/refresh -XML -machine $HOST -pd "$PROD" -v "$VER" -dnum 10 -execute

#getting the refresh report via e-mail
#$CCPROJECTHOME/bin/refresh_report $1 "" "nbuildreports@amdocs.com"

exit
EXIT:
	echo "\nUsage : ccRunPromote.tcsh <product> <version> <variant> [-NP]"
	echo "Product Name"
	echo "Version Number"
	echo "Variant Number"
	echo "-NP Run build with a refresh & without promote tasks"
   	echo "e.g : ccRunPromote.tcsh lel 750 64OG -NP\n"
	exit
