#!/usr/local/bin/tcsh 


set VAR = "0"
set NPFlag = "0"
set NRFlag = "0"

if ( "$1" == "-h" ) then
	goto EXIT
endif

set PROD = "$1"
if ( ! -d $HOME/product/$PROD ) then
        echo "\nProduct $PROD doesn't exsit under $HOME/product\n"
        goto EXIT
endif

set VER = "$2"
set VVER = v"$VER"
set VVER1 = `echo $VVER | cut -c1-3`
set VVER2 = `echo $VVER | cut -c4-4`
set VVE_R = `echo $VVER1"_"$VVER2`

if ( ! -d $HOME/"$VVER" ) then
        echo "\nVersion $VVER doesn't exist under CC home directory\n"
        goto EXIT
endif

set VAR = "$3"
set RealVar = `cat $HOME/product/$PROD/$VVER/config/product_variants`
set VARF = "0"
foreach var (`echo $RealVar`)
        if ( "$var" == "$VAR" ) then
                set VARF = "1"
        endif
end
if ( "$VARF" == "0" ) then
        echo "\nThe variant $VAR doesn't exist on $HOME/product/$PROD/$VVER/config/product_variants file\n"
        goto EXIT
endif

if ( "$4" != "-NR" && "$4" != "" && "$4" != "-NP" ) then
        goto EXIT
endif
if ( "$5" != "-NR" && "$5" != "" && "$5" != "-NP" ) then
        goto EXIT
endif

if ( "$4" == "-NP" || "$5" == "-NP" ) then
        set NPFlag = "1"
endif

if ( "$4" == "-NR" || "$5" == "-NR" ) then
        set NRFlag = "1"
endif

setenv USER $LOGNAME
setenv user $USER
setenv SHELL /usr/local/bin/tcsh
source /sdkhome/sdk/SDKRoot/.ccmngr_cshrc
source /sdkhome/sdk/SDKRoot/.ccmngr_login


hupdateFileSystem -l PRODUCTVER -p $1 -r v$2 -va "$3" 

#  increase the build counter

if ( $NPFlag == "0" ) then
		#  increase the build counter
		$HARVESTDIR/bin/refresh -B -machine $HOST -pd $1 -v $2
		# promote the packages to Build Approval state ***"
		$HARVESTDIR/bin/refresh -P -machine $HOST -pd $1 -v $2
endif
if ( $NRFlag == "0" ) then	
	# prepare the xml file and run the refresh command ***"
	$HARVESTDIR/bin/refresh -XML -machine $HOST -pd $1 -v $2 -dnum 2 -execute
endif

#getting the refresh report via e-mail
#$CCPROJECTHOME/bin/refresh_report $1 "" "nbuildreports@amdocs.com"

#OMS####

if ( $1 == "oms" ) then

echo going to remove the sources  now ....
\rm -rf $HOME/bb/cord9*/${VVE_R}

echo going to run UFS.....
hupdateFileSystem -l PRODUCTVER -p $1 -r v${2} -va "64OG"


echo going to run refresh ......
$HARVESTDIR/bin/refresh  -XML -execute -machine $HOST -pd $1  -v $2
$HARVESTDIR/bin/refresh -XML -machine $HOST -pd $1 -v $2 -dnum 10 -execute

\cp -f /clrhome/clr/ccclr/mb_ccclr/bb/gord1core/${VVE_R}/lib/AmdocsCihDatatypes.jar /clrhome/clr/ccclr/mb_ccclr/bb/gord1core/${VVE_R}/lib/AmdocsCihDataTypes.jar




echo "going to link .setting ==> _setting ...."

cd $HOME/bb/cord9utilities/${VVE_R}/EclipseProjects/integration
ln -s _settings .settings

cd $HOME/bb/cord9utilities/${VVE_R}/EclipseProjects/oms_adt
ln -s _settings .settings

cd $HOME/bb/cord9utilities/${VVE_R}/EclipseProjects/oms_aif_project
ln -s _settings .settings

cd $HOME/bb/cord9utilities/${VVE_R}/EclipseProjects/claro_aif_project
ln -s _settings .settings

endif


exit

EXIT:
echo "\nUsage : ccPreBuild <product> <version> <variant> [ -NR ] [ -NP ]"
echo "	Product Name"
echo "	Version Number"
echo "	Variant Number"
echo "	-NR < Run build without a refresh >"
echo "	-NP < Run build without a tasks promote >\n"

