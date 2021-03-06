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

hupdateFileSystem -l PRODUCTVER -p $1 -r v$2 -va "$3" 

#  increase the build counter
$HARVESTDIR/bin/refresh -B -machine $HOST -pd $1 -v $2

# promote the packages to Build Approval state
#$HARVESTDIR/bin/refresh -P -machine $HOST -pd $1 -v $2

# prepare the xml file and run the refresh command
#$HARVESTDIR/bin/refresh -XML -machine $HOST -pd $1 -v $2 -dnum 10 -execute

#getting the refresh report via e-mail
#$CCPROJECTHOME/bin/refresh_report $1 "" "nbuildreports@amdocs.com"

#build commnad
/sdkhome/sdk/SDKRoot/CRM${2}/tools/build/bin/hbuild_product -n $1 -v v${2} -t $3  -b Module -DB -SM -SW Module -AsItIs > $HOME/log/crm.crontab.v${2}.`timestamp`
