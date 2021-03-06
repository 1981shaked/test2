#!/usr/local/bin/tcsh

setenv USER $LOGNAME
setenv user $USER
setenv SHELL /usr/local/bin/tcsh
source /sdkhome/sdk/SDKRoot/.ccmngr_cshrc
source /sdkhome/sdk/SDKRoot/.ccmngr_login

if ($#argv != 3) then
   echo "Example: run_Promote <product> <version> <variant>"
   echo "Example: run_Promote lel 750 64OG"
   exit (1)
endif
echo running UFS now
hupdateFileSystem -l PRODUCTVER -p $1 -r v$2 -va "$3" 
#/clrhome/clr/ccclr/mb_ccclr/bin/SyncJar/Start_Sync.sh 800 /clrhome/clr/ccclr/mb_ccclr/bin/SyncJar/ABP_CRM_800.properties force

#  increase the build counter
#$HARVESTDIR/bin/refresh -B -machine $HOST -pd $1 -v $2
echo "$HARVESTDIR/bin/buildCounter Daily 800 1 crm"
$HARVESTDIR/bin/buildCounter Daily 800 1 crm

# promote the packages to Build Approval state
$HARVESTDIR/bin/refresh -P -machine $HOST -pd crm -v 800

# prepare the xml file and run the refresh command
$HARVESTDIR/bin/refresh -XML -machine $HOST -pd $1 -v $2 -dnum 10 -execute

#getting the refresh report via e-mail
#$CCPROJECTHOME/bin/refresh_report $1 "" "nbuildreports@amdocs.com"

#build commnad
/sdkhome/sdk/SDKRoot/CRM800/tools/build/bin/hbuild_product -n crm -v v800 -t 64OG -b Module -DB -SM -SW Module -AsItIs > $HOME/log/crm.crontab.v800.`timestamp`
