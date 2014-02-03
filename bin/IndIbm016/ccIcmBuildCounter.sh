#!/usr/local/bin/tcsh

setenv USER $LOGNAME
setenv user $USER
setenv SHELL /usr/local/bin/tcsh

set VER = $1
set VVER = v"$VER"

if ( ! -d $HOME/"$VVER" ) then
        echo "\nVersion $VVER doesn't exist under CC home directory\n"
        echo "Usage : IcmBuildCounter < Version >"
        echo "e.g.  : IcmBuildCounter 750\n"
        exit
endif
source /sdkhome/sdk/SDKRoot/.ccmngr_cshrc
source /sdkhome/sdk/SDKRoot/.ccmngr_login
sleep 10

$HARVESTDIR/bin/buildCounter Daily $VER 1 
#$HARVESTDIR/bin/buildCounter Daily $VER -1 oms 
#$HARVESTDIR/bin/buildCounter Daily $VER -1 crm
#$HARVESTDIR/bin/buildCounter Daily $VER -1 lel
#$HARVESTDIR/bin/buildCounter Daily $VER -1 amss 


