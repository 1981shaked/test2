#!/usr/local/bin/tcsh 

setenv USER $LOGNAME
setenv user $USER
setenv SHELL /usr/local/bin/tcsh

if ($#argv != 3) then
   echo "\nExample: ccPostBuild < Product > < Version > < Variant >"
   echo "Example: ccPostBuild lel 790 64OG\n"
   exit (1)
endif

set PROD = $1
set VER = $2
set VVER = v"$VER"
set VVER1 = `echo $VVER | cut -c1-3`
set VVER2 = `echo $VVER | cut -c4-4`
set VVE_R = `echo $VVER1"_"$VVER2`


set VAR = "$3"
set RealVar = `cat $HOME/product/$PROD/$VVER/config/product_variants`

set VARF = "0"
foreach var (`echo $RealVar`)
        if ( $var == $VAR ) then
                set VARF = "1"
        endif
end
if ( $VARF == "0" ) then
        echo "\nThe variant $VAR doesn't exist on $HOME/product/$PROD/$VVER/config/product_variants file\n"
        exit
endif



if ( ! -d $HOME/product/$PROD ) then
	echo "\nError: The product $PROD is missing under $HOME/product/\n"
        exit
endif
if ( ! -d $HOME/product/$PROD/v$VER ) then
                echo "\nError: The version v$VER is missing under $HOME/product/$PROD/ \n"
                exit
endif

source /sdkhome/sdk/SDKRoot/.ccmngr_cshrc
source /sdkhome/sdk/SDKRoot/.ccmngr_login

#$HOME/bin/CCMSS_BuildStatus.pl -type PROD -v $VER -entity $PROD

if ( $PROD == "lel" ) then 
	$HOME/bin/ccTAG.ksh -P $PROD -v $VVE_R -t $VAR
endif
if ( $PROD == "oms" ) then

echo "copy OMS jar to CRM for RT"
\cp -f ${HOME}/bb/gord1core/${VVE_R}/lib/AmdocsOrderingCihClientKit.jar ${HOME}/proj/c9crm${VER}${CCVARIANT_DELIMITER}${CCVARIANT}/lib
\cp -f ${HOME}/proj/c9ord${VER}${CCVARIANT_DELIMITER}${CCVARIANT}/lib/OrderingClientCust.jar ${HOME}/proj/c9crm${VER}${CCVARIANT_DELIMITER}${CCVARIANT}/lib
\cp -f ${HOME}/proj/c9ord${VER}${CCVARIANT_DELIMITER}${CCVARIANT}/lib/OrderingClient.jar ${HOME}/proj/c9crm${VER}${CCVARIANT_DELIMITER}${CCVARIANT}/lib
\cp -f ${HOME}/bb/cord9connectors/${VVE_R}/omsconnectors.jar ${HOME}/proj/c9crm${VER}${CCVARIANT_DELIMITER}${CCVARIANT}/lib
\cp -f ${HOME}/bb/cord9impl/${VVE_R}/lib/e2c_oms_api.jar ${HOME}/proj/c9crm${VER}${CCVARIANT_DELIMITER}${CCVARIANT}/lib

echo "Update ClfyBap.ear for RT"
cd ${HOME}/proj/c9crm${VER}${CCVARIANT_DELIMITER}${CCVARIANT}/lib
jar -uvf ClfyBap.ear omsconnectors.jar
jar -uvf ClfyBap.ear e2c_oms_api.jar

echo "Running switch for CRM "
$CCMNGRHOME/bin/CCSwitch -v $VVER -pd crm -vrt $VAR

endif



if ( $PROD == "amss" ) then
#	$HOME/bin/ccPRODzip $VER $PROD
endif

harpromote -B $BROKERNAME -H "Tasks $VER" -ST "Build Approval" -PN "Promote to Build Review" -A
