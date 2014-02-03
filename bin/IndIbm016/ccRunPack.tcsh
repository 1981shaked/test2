#!/usr/local/bin/tcsh 

set Version = $1
set BuildNum = $2

if ( "$Version" == "-h" || "$Version" == "" ) then
                echo "\nUsage : Run_Pack < Version Number > [ < Build Number > ]"
		echo "Build Number - for incremental mode, Depending on signature file per build number"
                echo "Example : Run_Pack 750 122 \n"
                exit
endif

if ( ! -d $HOME/product/lel/v$Version ) then
                echo "\nError: The version v$Version is missing under $HOME/product/lel/ \n"
                exit
endif

setenv X2I_HOME "$HOME/Packager/"
setenv SERVER_HOME "$HOME/Packager/MEDIATION_HOME"
setenv MANIFEST_DIR "$HOME/Packager/manifests"
setenv INPUT_DIR "$HOME/Packager/CRC"
setenv README "$HOME/Packager/manifests"
setenv TMP "$HOME/tmp"
#setenv BUILD_NUM "168"
setenv BUILD_NUM `$HARVESTDIR/bin/buildCounter Daily $Version 0 lel | awk -F: '{print $2}' | awk -F" " '{print $1}'`
setenv SIG_PATH "$HOME/Personal/Eyal/"
setenv PACK_FILES "$HOME/Personal/Eyal/$Version/$BuildNum"
setenv NEW_PACK_FILES "$HOME/Personal/Eyal/$Version/${BUILD_NUM}"
setenv SIG_FILE_NAME "signature.zip"
if ( $BuildNum == "" ) then
	setenv JAR_FILE_NAME "LEL_Build_${Version}_Full_${BUILD_NUM}"
else
	setenv JAR_FILE_NAME "LEL_Build_${Version}_${BuildNum}_${BUILD_NUM}"
endif
source /sdkhome/sdk/SDKRoot/.ccmngr_cshrc
source /sdkhome/sdk/SDKRoot/.ccmngr_login

if ( $BuildNum != "" ) then
	if ( ! -d ${PACK_FILES} ) then
        	echo "\nError: The build number path ${PACK_FILES} is missing \n"
        	exit
	endif
	if ( ! -f ${PACK_FILES}/${SIG_FILE_NAME} ) then
		echo "\nError : The signature file name ${SIG_FILE_NAME} is missing under ${PACK_FILES}\n"
		exit
	else
		echo "\n**** Running In Incremental Mode ****\n"
		do_sp c3cm${Version}V64OG
		mkdir -p ${PACK_FILES}
		rm -f ${SIG_PATH}/signature.zip
		cp ${PACK_FILES}/${SIG_FILE_NAME} ${SIG_PATH}
		${X2I_HOME}/bin/apkPackager.ksh -prod_file ${MANIFEST_DIR}/Lel_Product_Definition.xml -alias ${MANIFEST_DIR}/LEL_Alias.properties -signature_location ${SIG_PATH}/signature.zip -signature_file ${NEW_PACK_FILES}/${SIG_FILE_NAME} -readme ${README}/Readme.txt -crc_prp ${INPUT_DIR}/crc.prp -temp_dir ${TMP} -output_package ${NEW_PACK_FILES}/${JAR_FILE_NAME}
	endif
else
	echo "\n**** Running In Full Mode ****\n"
	if ( -f ${SIG_PATH}/signature.zip ) then
		rm -f ${SIG_PATH}/signature.zip
	endif
	mkdir -p ${PACK_FILES}
	${X2I_HOME}/bin/apkPackager.ksh -run_mode full -prod_file ${MANIFEST_DIR}/Lel_Product_Definition.xml -alias ${MANIFEST_DIR}/LEL_Alias.properties -signature_file ${NEW_PACK_FILES}/${SIG_FILE_NAME} -readme ${README}/Readme.txt -crc_prp ${INPUT_DIR}/crc.prp -temp_dir ${TMP} -output_package ${NEW_PACK_FILES}/${JAR_FILE_NAME}
endif

touch ${NEW_PACK_FILES}/PermittedModules.prp
echo "#permitted module list" >> ${NEW_PACK_FILES}/PermittedModules.prp
foreach module (`cat $HOME/product/lel/v${Version}/config/lel_v${Version}_modbo.dat | awk -F" " '{print $2}' | uniq`)
        echo $module >> ${NEW_PACK_FILES}/PermittedModules.prp
end
cp ${INPUT_DIR}/crc.prp ${NEW_PACK_FILES}

