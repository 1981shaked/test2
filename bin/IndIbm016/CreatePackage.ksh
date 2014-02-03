#!/bin/ksh
		
		
#################################################################################		
# Name		:  CreatePackage.ksh		                     	        #		
#                                                                               #		
# Purpose      	:                                                               #		
# Parameters	: see Usage                                                     #		
#                                                                               #		
# Written by  	: Michael Goldgamer                                             #		
#                                                                               #		
# Date		:                                                               #		
#                                                                               #		
# Changes history:                                                              #
# Started: 18-Jun-2006                                                          #		
#################################################################################		


if [ ! "${CCPROJECTHOME}" ] ; then
	print "ERROR: Environment variable CCPROJECTHOME is not defined"
	exit 1
fi
		
#####################		
# DEFINITION & INIT #		
#####################		

export MACHINE="$ARCH"

if [[ "$MACHINE" = "AIX" ]] ; then
        export JAVA_HOME=/usr/java5 
        export PATH=${JAVA_HOME}/bin:$PATH
fi

SCRIPT_NAME=${0##*/}		
SCRIPT_DIR=${0%/*}		
RUN_PWD=`pwd`		
CURRENT_DIR=$PWD		
SIG=signature.zip	
# Run modes		
# Acceptable tar versions		
GNU_TAR="/usr/local/bin/tar"		
REGULAR_TAR="/usr/bin/tar"	


JUST_PRINT="off"
DEBUG="off"

TIMESTAMP=`/usr/bin/date '+%Y%m%d_%H%M%S'`

if [[ ! -d ${HOME}/tmp ]]; then
	mkdir ${HOME}/tmp
fi

LOG_FILE="${HOME}/tmp/CreatePackage.${TIMESTAMP}.log"
touch ${LOG_FILE}
#print "Main log file: ${LOG_FILE}"
	
##################################################		
#             F U N C T I O N S                  #		
##################################################		
		
###########################################################################		
# Purpose: Print messages to stdout and to log file                       #		
###########################################################################		
Output()		
{		
	DATESTRING=`date "+%Y-%m-%d %H:%M:%S"`		
	debugLevel=$1 		
 		
 #	if [[ $DEBUG_MODE = true || $debugLevel != "DEBUG" ]] ; then
		echo "$DATESTRING -${debugLevel}- $2"		
		echo "$DATESTRING -${debugLevel}- $2" >> ${LOG_FILE}		
#	fi
}		
		
#################################################################################		
#The function name:Usage()                                                      #		
#The Output:  print the usage                                                   #		
#The Input:  NO input                                                           #		
################################################################################# 		
Usage()                                                		
{		
   print "
   Purpose: 
   Create RT, SDK or SDK_API package of ABP. The package may be packed as Full or Incremental, based on previously released packages.
   Four files should be produced by the packager:
   	Package itself - e.g. amdocs_sdk_ABP6.0.7.0_64_Itanium.sh
   	New signature file - e.g. amdocs_sdk_ABP6.0.7.0_64_Itanium_hpx404_signature.zip
   	Permitted modules (license) file - e.g. amdocs_sdk_ABP6.0.7.0_64_PermittedModules.prp
   	List of affected files - e.g. amdocs_sdk_ABP6.0.7.0_64OG_HP-UX_hpx404_affected.txt
   
   Usage:
   ${SCRIPT_NAME} -pack_type <sdk/rt> -prod_ver <product version to pack> -major_prod_ver <major product version> -variant <product variant> -prod_name <product name> -out_dir <destination directory> -run_mode <full/xml> -patch_ver <target patch version> [-dep_patch_ver <dep patch versions>] -dest_ver <dest version directory> -is_lm <on/off> -checkin <on/off> -pack_src <on/off> [-debug on] [-just_print on]
   
-pack_type	Mandatory. Package type to be created. may be \"rt\" (RunTime) or \"sdk\" (SDK) or \"sdk_api\" {SDK Api}
		or \"sdk_trb32\" {SDK Trb32}.
		Multiple pack_type is supported. E.g \"-pack_type rt,sdk\"
-prod_ver	Mandatory. The version of the product, which need to be packed.  Example: \"600_SP_7\".
-major_prod_ver	Mandatory. The major version of the product to be packed. Example:  \"600\".
-variant	Mandatory. The Variant of the product, which need to be packed. Example: \"64O2\".
-prod_name	Mandatory. The product name. Example: \"abp\".
-out_dir	Mandatory. Destination directory where the package will be created. In case of creating partial (not GA) patch, prior to running the
		script, this directory should contain Readme.txt file and previous signature.zip file. When the script finishes, it will contain the
		package	itself, new signature file, affected files list, log and other temporary files.
-run_mode	Mandatory. Packager run mode. May be \"full\" or \"xml\". 
		In \"xml\" mode will generate all service files like signature, affected but not create the target package itself.
		In \"full\" mode will also create the target package.
-patch_ver	Mandatory. Data that describes the destination patch package in format: Major.Minor.ServicePack.PatchBundle.HotFix
		Example 1: for creating patch \"ABP600 ServicePack 7 PatchBundle 2 HotFix 1\" use this:
			-patch_ver 6.0.7.2.1
		Example 2: for creating package \"ABP600 ServicePack 8\" use this:
			-patch_ver 6.0.8.0
-dep_patch_ver	Optional. Data that describes the dependency of the destination patch in format: Major.Minor.ServicePack.PatchBundle.HotFix
		Switching this flag on forces the packager to run in incremental mode, so it will create a partial patch which based on some older one.
		In this case, appropriate signature file (signature.zip) should be copied into \"\-out_dir\" prior to start packing.
		Example: for creating patch based on \"ABP600 ServicePack 5 PatchBundle 7\" use this:
			-dep_patch_ver 6.0.5.7
-dest_ver	Mandatory. Destination version of the product as it will appear in SDKRoot/<ProdName><dest_ver> after extracting.
		Example:  For creating package which will be extracted as SDKRoot/ABP6.0.5.0 use this:
			-dest_ver 6.0.5.0
-checkin	Mandatory. CheckIn newly generated signature file to XtraC (Infra/Infra), and promote the XtraC package to state \"Build\".
		May be \"on\" or \"off\".
		Example: -checkin on
-is_lm		Mandatory. Pack LM or non-LM variant of the product. May be \"on\" or \"off\".
		Example:  -is_lm off
-debug		Optional. Prints extended debug information during the packing. May be \"on\" or not specified at all.
		Example:  -debug on
-pack_src	Mandatory for \"-pack_type sdk\". Pack the source files, the build products were created from. The flag is only relevant for \"-pack_type sdk\".
		May be \"on\" or \"off\" for \"-pack_type sdk\". For other -pack_tape-s this flag will be ignored so it may be not provided at all.
		Example:  -pack_src on
-just_print	Optional. Simulates creating of a package, but does not create one, just prints the command to be run.
		May be \"on\" or not specified at all.
		Example:  -just_print on
   "		
   echo "$PARAM_ERROR_MSG"		
		
		
   print "\nExample 1. Create full SDK package and checkin new signature file to XtraC. Pack with JVM inside. Pack source files:"
   print "$SCRIPT_NAME -pack_type sdk -prod_ver 600_SP_5 -major_prod_ver 600 -variant 64 -prod_name abp -patch_ver 6.0.5.0 -out_dir /packhome/pack/Packoutput/6.0.5.0 -run_mode full -checkin on -is_lm off -dest_ver 6.0.5.0 -pack_src on"
   
   print "\nExample 2. Generate signatures and affected files for Incremental SDK and RT packages , but do not create a package itself, do not checkin the signature. Do not pack source files:"
   print "$SCRIPT_NAME -pack_type sdk,rt -prod_ver 600_SP_5 -major_prod_ver 600 -variant 64 -prod_name abp -patch_ver 6.0.5.0.1 -dep_patch_ver 6.0.5.0 -out_dir /packhome/pack/Packoutput/6.0.5.0.1 -run_mode xml -checkin off -is_lm on -dest_ver 6.0.5.0 -pack_src off"
   
   print "\nExample 3. Create full RT package. Prints extended debug information during the packing:"
   print "$SCRIPT_NAME -pack_type rt -prod_ver 600_SP_5 -major_prod_ver 600 -variant 64O2 -prod_name abp -patch_ver 6.0.5.7 -out_dir /packhome/pack/Packoutput/6.0.5.7 -run_mode full -checkin off -is_lm off -dest_ver 6.0.5.7"
   
   print "\nExample 4. Simulate creating of incremental RT patch package, just print the command to be run:"
   print "$SCRIPT_NAME -pack_type rt -prod_ver 600_SP_5 -major_prod_ver 600 -variant 64O2 -prod_name abp -patch_ver 6.0.5.7.2 -dep_patch_ver 6.0.5.7.1 -out_dir /packhome/pack/Packoutput/6.0.5.7.2 -run_mode full -just_print on -checkin off -is_lm off -dest_ver 6.0.5.0"
   
   print "\nExample 5. Create full SDK API package:"
   print "$SCRIPT_NAME -pack_type sdk_api -prod_ver 600_SP_5 -major_prod_ver 600 -variant 64 -prod_name abp -patch_ver 6.0.5.0 -out_dir /packhome/pack/Packoutput/6.0.5.0 -run_mode full -checkin off -is_lm off -dest_ver 6.0.5.0"

   print "\nExample 6. Create full SDK TRB32 package:"
   print "$SCRIPT_NAME -pack_type sdk_trb32 -prod_ver 600_SP_5 -major_prod_ver 600 -variant 32 -prod_name abp -patch_ver 6.0.5.0 -out_dir /packhome/pack/Packoutput/6.0.5.0 -run_mode full -checkin off -is_lm off -dest_ver 6.0.5.0"
   
   print "\nExample 7. Create full RT and SDK packages. Checkin the signatures to XtraC."
   print "$SCRIPT_NAME -pack_type rt,sdk -prod_ver 600_SP_5 -major_prod_ver 600 -variant 64 -prod_name abp -patch_ver 6.0.5.0 -out_dir /packhome/pack/Packoutput/6.0.5.0 -run_mode full -checkin on -is_lm off -dest_ver 6.0.5.0 -pack_src off"
   print "\n"
   exit 1 		
}

#################################################################################		
#The function name:exitFunc()                                                   #		
#The Output:  0-for success,1-for failur.                                       #		
#The Input:  0 or 1                                                             #		
#################################################################################  		
exitFunc()		
{ 		
	status=$1		
	Output "Exiting with status $status   [${SCRIPT_NAME}]"		
	exit $status;	
} 	


# Find missing parameters for flags		
CompareAgainstFlags()		
{		
	CURRENT_FLAG=$1		
	PARAM=$2		
	for flag in $flagsArray ; do		
		if [[ (-$flag = "$PARAM") || (-z "$PARAM") ]] ; then		
			BAD_PARAM=$CURRENT_FLAG		
			PARAM_ERROR_MSG="Parameter missing for flag $BAD_PARAM !"		
			Usage				
		else		
			BAD_PARAM=""		
		fi		
	done		
			
}		

checkPackagerParam()
{
	if [[ "$DEBUG" = "on" ]]; then
		echo "PACK_TYPE = $PACK_TYPE"
		echo "PROD_VER = $PROD_VER"
		echo "MAJOR_PROD_VER = $MAJOR_PROD_VER"
		echo "VARIANT = $VARIANT"
		echo "PATCH_VER = $PATCH_VER"
		echo "DEP_PATCH_VER = $DEP_PATCH_VER"
		echo "DEST_VER = $DEST_VER"
		echo "OUT_DIR_FLAG = $OUT_DIR_FLAG"
		echo "PRODUCT_NAME = $PRODUCT_NAME"
		echo "CHECKIN = $CHECKIN"
		echo "RUN_MODE = $RUN_MODE"
		echo "DEBUG = $DEBUG"
		echo "JUST_PRINT = $JUST_PRINT"
		echo "IS_LM = $IS_LM"
		echo "PACK_SRC = $PACK_SRC"
	fi

	if [[ "${OSNAME}" = "HP-ITANIUM" ]]; then
		if [[ "$MAJOR_PROD_VER" = "600" ]]; then
     			export PLATFORM="Itanium"
			export RUNPLATFORM="Itanium"
     		else
     		   	export PLATFORM="Itanium"
			export RUNPLATFORM="HP-UX"
		fi
	else
     		export PLATFORM="$ARCH"
		export RUNPLATFORM="$ARCH"
	fi

	if [[ ! -d "$OUT_DIR_FLAG" ]]; then
		Output ERROR "Destination directory $OUT_DIR_FLAG does not exist. Check \"-out dir\" argument."
 	 	exitFunc 1 
	fi
	
	if [[ "$CHECKIN" != "on" && "$CHECKIN" != "off" ]]; then
		Output ERROR "You must provide flag \"-checkin\" with one of the following parameters \"on/off\""
		Output ERROR "e.g. \"-checkin on\""
 		exitFunc 1
 	fi
 	
 	if [[ "$DEST_VER" = "" ]]; then
		Output ERROR "Flag -dest_ver is mandatory. Please provide \"-dest_ver <dest_version_number>\""
		Output ERROR "	example: -dest_ver 6.0.8.0 "
 		exitFunc 1
 	fi
 	
 	if [[ "$IS_LM" != "on" && "$IS_LM" != "off" ]]; then
		Output ERROR "Flag -is_lm is mandatory. Please provide \"-is_lm on\" or \"-is_lm off\""
 		exitFunc 1
 	elif [[ "$IS_LM" = "on" ]]; then
 		export PELM_PROJ_SUFFIX="lmapi"
 		LM_PREFIX="LM"
 		LM_UND_PREFIX="_LM"
 		#echo "\n-------- !!! Packing LM variant of the product !!! ----------"
 		#echo "PELM_PROJ_SUFFIX = $PELM_PROJ_SUFFIX\n"
 	else
 		export PELM_PROJ_SUFFIX="api"
 		LM_PREFIX=""
 		#echo "\n-------- !!! Packing non-LM variant of the product !!! ----------"
 		#echo "PELM_PROJ_SUFFIX = $PELM_PROJ_SUFFIX\n"
 	fi
 	
	startTmpVer=`echo $PROD_VER | cut -c 1-2`
	endTmpVer=`echo $PROD_VER | cut -c 3-100`
	BbVer="v${startTmpVer}_${endTmpVer}"
	startTmpMajorVer=`echo $MAJOR_PROD_VER | cut -c 1-2`
	endTmpMajorVer=`echo $MAJOR_PROD_VER | cut -c 3-100`
	export bbMajorVer="v${startTmpMajorVer}_${endTmpMajorVer}"
	
	
	export X2IRTVariant=$VARIANT
	
	export patchVersion=$PATCH_VER
	export patchVersionSDK=`echo $DEST_VER | awk -F\. '{print $1 "." $2 "." $3 "." $4}'` 
	export patchVersionRT=`echo $DEST_VER | awk -F\. '{print $1 "." $2 "." $3 "." $4}'` 
	export patchVersionSDK_API=`echo $DEST_VER | awk -F\. '{print $1 "." $2 "." $3 "." $4}'` 
	export patchVersionSDK_TRB32=`echo $DEST_VER | awk -F\. '{print $1 "." $2 "." $3 "." $4}'` 
	depPatchVersion=$DEP_PATCH_VER

	export ProductName=$PRODUCT_NAME
	export ProductVer="v$PROD_VER"
	export PROD_NAME=`echo $PRODUCT_NAME | perl -pe 'tr/[a-z]/[A-Z]/'`  

	
	export IS_HOME=/InstallShield11
	
	# This variable should come from cc_local.dat
	#export X2I_HOME_AP=/sdkhome/sdk/x2ihome/AmdocsPackager
	#>less cc_locat.dat
	#X2I_HOME_AP /sdkhome/sdk/x2ihome/AmdocsPackager
	#export X2I_HOME=/sdkhome/sdk/x2ihome/AmdocsPackager
	
	#export X2I_HOME=${CCPROJECTHOME}/bb/gpack/${bbMajorVer}/bpack
	#export X2I_HOME_BP=${CCPROJECTHOME}/bb/gpack/${bbMajorVer}/bpack
	### only for test period:
	export X2I_HOME=${CCPROJECTHOME}/bb/gpack/${bbMajorVer}/bpack
	export X2I_HOME_BP=${CCPROJECTHOME}/bb/gpack/${bbMajorVer}/bpack
	
	#Prepare variables used in *_MergedAlias.properties
	#export MY_CC_HOME="${CCPROJECTHOME}"
	export BBVer="${BbVer}"
	export ProductMajorVerNum="${MAJOR_PROD_VER}"
	export ProductVerNum="${PROD_VER}"

	export SDK_LABEL="${PROD_NAME}${patchVersionSDK}_${LM_PREFIX}${VARIANT}"
	export SDK_LABEL_LONG="${PROD_NAME}${patchVersion}_${LM_PREFIX}${VARIANT}"
	export RT_LABEL="${PROD_NAME}${patchVersionRT}_${LM_PREFIX}${VARIANT}"
	export RT_LABEL_LONG="${PROD_NAME}${patchVersion}_${LM_PREFIX}${VARIANT}"
	export SDK_TRB32_LABEL="${PROD_NAME}${patchVersionSDK_TRB32}_${LM_PREFIX}${VARIANT}"
	export SDK_TRB32_LABEL_LONG="${PROD_NAME}${patchVersion}_${LM_PREFIX}${VARIANT}"
	export SDK_API_LABEL="${PROD_NAME}${patchVersionSDK_API}_${LM_PREFIX}${VARIANT}"
	export SDK_API_LABEL_LONG="${PROD_NAME}${patchVersion}_${LM_PREFIX}${VARIANT}"

	if [[ "$PACK_TYPE" = "sdk" ]]; then
		export OUT_DIR="${OUT_DIR_FLAG}/SdkPatchDir${LM_UND_PREFIX}"
		if [[ ! -d $OUT_DIR ]]; then
			mkdir $OUT_DIR
		else
			rm -rf $OUT_DIR/* 
		fi
		if [[ "$MAJOR_PROD_VER" = "600" ]]; then
			ProductManifestFile=${CCPROJECTHOME}/bb/gmanifests/${BbVer}/product/SDK_Product_Definition.xml
			ProductAliasestFile=${CCPROJECTHOME}/bb/gmanifests/${BbVer}/product/SDK_MergedAlias.properties
		else  ## for v650 and higher
			ProductManifestFile=${CCPROJECTHOME}/product/${ProductName}/v${PROD_VER}/pack/SDK_Product_Definition.xml
			ProductAliasestFile=${CCPROJECTHOME}/product/${ProductName}/v${PROD_VER}/pack/SDK_MergedAlias.properties
		fi
		X2IOutPkg="${OUT_DIR}/amdocs_sdk_${SDK_LABEL_LONG}_${PLATFORM}"
		#print X2IOutPkg = $X2IOutPkg
		X2ICRCPrp="${CCPROJECTHOME}/bb/gpack/${bbMajorVer}/bpack/crc.prp"
		X2IReadMe="${OUT_DIR}/Readme.txt"
		PrevSignature="${OUT_DIR}/signature.zip"
		NewSignature="${OUT_DIR}/amdocs_sdk_${SDK_LABEL_LONG}_${PLATFORM}_${HOST}_signature.zip"
		AffectedList="${OUT_DIR}/amdocs_sdk_${SDK_LABEL_LONG}_${PLATFORM}_${HOST}_affected.txt"
		SourceFilesDir="${OUT_DIR_FLAG}/src"
		SourceFilesTar="${SourceFilesDir}/amdocs_${PROD_NAME}${patchVersion}_sources.tar"
		export X2ISdkVariant="${VARIANT}"
		PerModFile="${OUT_DIR}/amdocs_${PACK_TYPE}_${SDK_LABEL_LONG}_PermittedModules.prp"
		export XTRAC_PACK_NAME="SIG_sdk_${SDK_LABEL_LONG}_${PLATFORM}_${HOST}_${TIMESTAMP}"
     
	elif [[ "$PACK_TYPE" = "rt" ]]; then
		export OUT_DIR="${OUT_DIR_FLAG}/RtPatchDir${LM_UND_PREFIX}"
		if [[ ! -d $OUT_DIR ]]; then
			mkdir $OUT_DIR
		else
			rm -rf $OUT_DIR/* 
		fi
		if [[ "$MAJOR_PROD_VER" = "600" ]]; then
			ProductManifestFile=${CCPROJECTHOME}/bb/gmanifests/${BbVer}/product/RT_Product_Definition.xml
			ProductAliasestFile=${CCPROJECTHOME}/bb/gmanifests/${BbVer}/product/RT_MergedAlias.properties
		else
			ProductManifestFile=${CCPROJECTHOME}/product/${ProductName}/v${PROD_VER}/pack/RT_Product_Definition.xml
			ProductAliasestFile=${CCPROJECTHOME}/product/${ProductName}/v${PROD_VER}/pack/RT_MergedAlias.properties
		fi
		X2IOutPkg="${OUT_DIR}/amdocs_rt_${RT_LABEL_LONG}_${PLATFORM}"
		#print X2IOutPkg = $X2IOutPkg
		X2ICRCPrp="${CCPROJECTHOME}/bb/gpack/${bbMajorVer}/bpack/crc.prp"
		X2IReadMe="${OUT_DIR}/Readme.txt"
		PrevSignature="${OUT_DIR}/signature.zip"
		NewSignature="${OUT_DIR}/amdocs_rt_${RT_LABEL_LONG}_${PLATFORM}_${HOST}_signature.zip"
		AffectedList="${OUT_DIR}/amdocs_rt_${SDK_LABEL_LONG}_${PLATFORM}_${HOST}_affected.txt"
		export X2IRtVariant="${VARIANT}"
		PerModFile="${OUT_DIR}/amdocs_${PACK_TYPE}_${RT_LABEL_LONG}_PermittedModules.prp"
		export XTRAC_PACK_NAME="SIG_rt_${RT_LABEL_LONG}_${PLATFORM}_${HOST}_${TIMESTAMP}"
	elif [[ "$PACK_TYPE" = "sdk_trb32" ]]; then
		export OUT_DIR="${OUT_DIR_FLAG}/Trb32PatchDir${LM_UND_PREFIX}"
		if [[ ! -d $OUT_DIR ]]; then
			mkdir $OUT_DIR
		else
			rm -rf $OUT_DIR/* 
		fi
		if [[ "$MAJOR_PROD_VER" = "600" ]]; then
			ProductManifestFile=${CCPROJECTHOME}/bb/gmanifests/${BbVer}/product/SDK_SERVER_TRB_Definition.xml 
			ProductAliasestFile=${CCPROJECTHOME}/bb/gmanifests/${BbVer}/product/SDK_MergedAlias.properties
		else
			ProductManifestFile=${CCPROJECTHOME}/product/${ProductName}/v${PROD_VER}/pack/SDK_SERVER_TRB_Definition.xml
			ProductAliasestFile=${CCPROJECTHOME}/product/${ProductName}/v${PROD_VER}/pack/SDK_MergedAlias.properties
		fi
		X2IOutPkg="${OUT_DIR}/amdocs_sdk_trb32_${SDK_TRB32_LABEL_LONG}_${PLATFORM}"
		#print X2IOutPkg = $X2IOutPkg
		X2ICRCPrp="${CCPROJECTHOME}/bb/gpack/${bbMajorVer}/bpack/crc.prp"
		X2IReadMe="${OUT_DIR}/Readme.txt"
		PrevSignature="${OUT_DIR}/signature.zip"
		NewSignature="${OUT_DIR}/amdocs_sdk_trb32_${SDK_TRB32_LABEL_LONG}_${PLATFORM}_${HOST}_signature.zip"
		AffectedList="${OUT_DIR}/amdocs_sdk_trb32_${SDK_LABEL_LONG}_${PLATFORM}_${HOST}_affected.txt"
		export X2IRtVariant="${VARIANT}"
		PerModFile="${OUT_DIR}/amdocs_${PACK_TYPE}_${SDK_TRB32_LABEL_LONG}_PermittedModules.prp"
		export XTRAC_PACK_NAME="SIG_sdk_trb32_${SDK_TRB32_LABEL_LONG}_${PLATFORM}_${HOST}_${TIMESTAMP}"
		export X2ISdkVariant=$VARIANT
	elif [[ "$PACK_TYPE" = "sdk_api" ]]; then
		export OUT_DIR="${OUT_DIR_FLAG}/ApiPatchDir${LM_UND_PREFIX}"
		if [[ ! -d $OUT_DIR ]]; then
			mkdir $OUT_DIR
		else
			rm -rf $OUT_DIR/* 
		fi
		if [[ "$MAJOR_PROD_VER" = "600" ]]; then
			ProductManifestFile=${CCPROJECTHOME}/bb/gmanifests/${BbVer}/product/SDK_Api_Product_Definition.xml
			ProductAliasestFile=${CCPROJECTHOME}/bb/gmanifests/${BbVer}/product/SDK_MergedAlias.properties
		else
			ProductManifestFile=${CCPROJECTHOME}/product/${ProductName}/v${PROD_VER}/pack/SDK_Api_Product_Definition.xml
			ProductAliasestFile=${CCPROJECTHOME}/product/${ProductName}/v${PROD_VER}/pack/SDK_MergedAlias.properties
		fi
		X2IOutPkg="${OUT_DIR}/amdocs_sdk_api_${SDK_API_LABEL_LONG}_${PLATFORM}"
		#print X2IOutPkg = $X2IOutPkg
		X2ICRCPrp="${CCPROJECTHOME}/bb/gpack/${bbMajorVer}/bpack/crc.prp"
		X2IReadMe="${OUT_DIR}/Readme.txt"
		PrevSignature="${OUT_DIR}/signature.zip"
		NewSignature="${OUT_DIR}/amdocs_sdk_api_${SDK_API_LABEL_LONG}_${PLATFORM}_${HOST}_signature.zip"
		AffectedList="${OUT_DIR}/amdocs_sdk_api_${SDK_LABEL_LONG}_${PLATFORM}_${HOST}_affected.txt"
		export X2IRtVariant="${VARIANT}"
		PerModFile="${OUT_DIR}/amdocs_${PACK_TYPE}_${SDK_API_LABEL_LONG}_PermittedModules.prp"
		export XTRAC_PACK_NAME="SIG_sdk_api_${SDK_API_LABEL_LONG}_${PLATFORM}_${HOST}_${TIMESTAMP}"
		export X2ISdkVariant=$VARIANT
	else
		Output ERROR "Error, check -pack_type argument"		
		exitFunc 1
	fi
	
		
	#print "ProductManifestFile = $ProductManifestFile"
	#print "ProductAliasestFile = $ProductAliasestFile"
	
	
	if [[ "${DEP_PATCH_VER}" != "" ]]
	then 		
		#print "The Readme file: ${X2IReadMe} is empty or doesn't exist"		
		print "Creating a Readme file: ${X2IReadMe}. A Readme file is mandatory in case of creating partial (not GA) package."		
  		print "Package ${PATCH_VER} depends on ${DEP_PATCH_VER}" | tee ${X2IReadMe}
  		if [[ -f ${CCPROJECTHOME}/product/${ProductName}/v${PROD_VER}/pack/amdocs_${PACK_TYPE}_${PROD_NAME}${DEP_PATCH_VER}_${LM_PREFIX}${VARIANT}_${PLATFORM}_${HOST}_signature.zip ]] ; then 
  			Output INFO "Copying previous signature file ${CCPROJECTHOME}/product/${ProductName}/v${PROD_VER}/pack/amdocs_${PACK_TYPE}_${PROD_NAME}${DEP_PATCH_VER}_${LM_PREFIX}${VARIANT}_${PLATFORM}_${HOST}_signature.zip to ${OUT_DIR}/signature.zip"
  			cp -f ${CCPROJECTHOME}/product/${ProductName}/v${PROD_VER}/pack/amdocs_${PACK_TYPE}_${PROD_NAME}${DEP_PATCH_VER}_${LM_PREFIX}${VARIANT}_${PLATFORM}_${HOST}_signature.zip ${OUT_DIR}/signature.zip
  		else
  			Output ERROR "Signature file ${CCPROJECTHOME}/product/${ProductName}/v${PROD_VER}/pack/amdocs_${PACK_TYPE}_${PROD_NAME}${DEP_PATCH_VER}_${LM_PREFIX}${VARIANT}_${PLATFORM}_${HOST}_signature.zip of the dependency patch does not exist."	
  			Output ERROR "Exiting..."
  			exitFunc 1
  		fi
	fi 	
	
	#If partial patch (not GA) will be created then we will require previous signature.zip file
	if [[ "$DEP_PATCH_VER" != "" && -z "$PrevSignature" ]]; then
		print "Previous signature file, which is mandatory for partial patch (not GA) packing, is empty ot not exist"
	fi
	
}

runxAmdocsPackager()		
{ 
	if [[ ! -d ${OUT_DIR}/Log ]]; then
        	mkdir ${OUT_DIR}/Log
	fi
	if [[ ! -d ${OUT_DIR}/Tmp ]]; then
        	mkdir ${OUT_DIR}/Tmp
	fi
	
	RUNCOMMAND="${X2I_HOME_BP}/bin/apkPackager.ksh -patchVersion $patchVersion -run_mode $RUN_MODE -prod_file ${ProductManifestFile} -alias ${ProductAliasestFile} -platform ${RUNPLATFORM} -output_package ${X2IOutPkg} -log_dir ${OUT_DIR}/Log  -temp_dir ${OUT_DIR}/Tmp  -crc_prp ${X2ICRCPrp} -signature_file ${NewSignature}"
	
	if [[ "${DEP_PATCH_VER}" != "" ]] ; then
		RUNCOMMAND="${RUNCOMMAND} -readme ${X2IReadMe} -signature_location ${PrevSignature} -depPatchVersion ${DEP_PATCH_VER}"
	fi
	if [[ "${DEBUG}" = "on" ]]; then
		RUNCOMMAND="${RUNCOMMAND} -debug on"
	fi
	
	if [[ "$JUST_PRINT" != "on" ]]; then
		Output INFO "Running command ${RUNCOMMAND}"
		eval $RUNCOMMAND
		
		#if [[ ! -z "${NewSignature}" ]]; then
			#Output INFO "Backup newly created signature file "
			#cp -pf ${NewSignature} ${NewSignature}.${TIMESTAMP}
			#ls -l ${NewSignature} ${NewSignature}.${TIMESTAMP}
		#fi
		
		#Creating file PermittedModules.prp for current package:
		rm -f ${PerModFile}
		ls ${OUT_DIR}/Tmp/affected/*.affected | awk -F\/ '{print $NF}' | sed 's/\.affected//' > ${PerModFile}
		
	else
		print "Running command ${RUNCOMMAND}"
	fi
	
	if [[ ! -z "${NewSignature}" && -f "${NewSignature}" ]]; then
		IS_SIGNATURE_CREATED="yes"
	fi
}

checkInSignature ()
{
if [[ ! -z "${NewSignature}" && -f "${NewSignature}" ]]; then
 	HCP_LOG="${OUT_DIR}/Log/hcp.log.${TIMESTAMP}"
 	HCO_LOG="${OUT_DIR}/Log/hco.log.${TIMESTAMP}"
	HCI_LOG="${OUT_DIR}/Log/hci.log.${TIMESTAMP}"
	HPP_LOG="${OUT_DIR}/Log/hpp_to_build.log.${TIMESTAMP}"
	HPP_TO_COMPLET_LOG="${OUT_DIR}/Log/hpp_to_completed.log.${TIMESTAMP}"
	HPP_TO_PUBLIC_LOG="${OUT_DIR}/Log/hpp_to_public.log.${TIMESTAMP}"
	SignFileXC="${NewSignature}"
	SignFileNameXC=`basename $SignFileXC`
	
	HCP_STATUS="0"
	HCO_STATUS="0"
	HCI_STATUS="0"
	HPP_STATUS="0"
	
	if [[ ! -d "${CCPROJECTHOME}/product/${ProductName}/v${PROD_VER}/pack" ]] ; then
		print "${CCPROJECTHOME}/product/${ProductName}/v${PROD_VER}/pack not FOUND! Creating this..."
		mkdir -p ${CCPROJECTHOME}/product/${ProductName}/v${PROD_VER}/pack
	fi
	
	if [[ -f "${CCPROJECTHOME}/product/${ProductName}/v${PROD_VER}/pack/${SignFileNameXC}" ]] ; then
		chmod 444 ${CCPROJECTHOME}/product/${ProductName}/v${PROD_VER}/pack/${SignFileNameXC}
	fi
	
	#Form Command for creating package in XTraC/Infra/Infra
	HCP_COMMAND="hcp ${XTRAC_PACK_NAME} -b ${HARBROKERNAME} -usr ${HAR_WB_USER} -pw ${HAR_WB_PASSWD} -st \"Infra\" -pn \"Create Infra Package\" -en Infra -o ${HCP_LOG}"
	
	#Form Command for CheckOut signature file from XTraC/Infra/Infra
	HCO_COMMAND='hco -b ${HARBROKERNAME} -usr ${HAR_WB_USER} -pw ${HAR_WB_PASSWD} -up -cp ${CCPROJECTHOME}/product/${ProductName}/v${PROD_VER}/pack -vp \product\\${ProductName}\\${ProductVer}\\pack -p "${XTRAC_PACK_NAME}" -pn "CheckOut for Upload" -st "Infra" -en "Infra" -o ${HCO_LOG} $SignFileNameXC'
	
	#Form Command for CheckingIn signature file to XTraC/Infra/Infra
	HCI_COMMAND='hci -b ${HARBROKERNAME} -usr ${HAR_WB_USER} -pw ${HAR_WB_PASSWD} -cp ${CCPROJECTHOME}/product/${ProductName}/v${PROD_VER}/pack -vp "\product\\${ProductName}\\${ProductVer}\\pack" -pn "CheckIn for Upload" -p ${XTRAC_PACK_NAME} -ur -nd -st "Infra" -en "Infra" -o ${HCI_LOG} $SignFileNameXC'

	#Form Command for Promoting Package from Infra to Build
	HPP_COMMAND="hpp -b ${HARBROKERNAME} -usr ${HAR_WB_USER} -pw ${HAR_WB_PASSWD} -en \"Infra\" -st \"Infra\" -pn \"Promote to Build\" ${XTRAC_PACK_NAME} -o ${HPP_LOG}"
	
	#Form Command for Promoting Package from Build to Completed
	HPP_TO_COMPLET_COMMAND="hpp -b ${HARBROKERNAME} -usr ${HAR_WB_USER} -pw ${HAR_WB_PASSWD} -en \"Infra\" -st \"Build\" -pn \"Promote to Completed\" ${XTRAC_PACK_NAME} -o ${HPP_TO_COMPLET_LOG}"
		
	#Form Command for Promoting Package from Build to Completed
	HPP_TO_PUBLIC_COMMAND="hpp -b ${HARBROKERNAME} -usr ${HAR_WB_USER} -pw ${HAR_WB_PASSWD} -en \"Infra\" -st \"Completed\" -pn \"Promote to Public\" ${XTRAC_PACK_NAME} -o ${HPP_TO_PUBLIC_LOG}"


	Output INFO "\nCreating Infra package \"${XTRAC_PACK_NAME}\" in XtraC and CheckIn new signature file."
	Output INFO "HCP_COMMAND=$HCP_COMMAND"	
	if [[ "$JUST_PRINT" != "on" ]];then
		Output INFO "..."
		eval $HCP_COMMAND
		cat $HCP_LOG
		cat $HCP_LOG >> ${LOG_FILE}
	fi
	if [[ `grep "Created Change Package\: ${XTRAC_PACK_NAME}" ${HCP_LOG}` != "" ]]; then
		HCP_STATUS="1"
		#print "HCP_STATUS = $HCP_STATUS"
	fi 
	

	if [[ "$JUST_PRINT" != "on" ]];then
		if [[ "${HCP_STATUS}" = "1" ]]; then
			print "\nTrying to CheckOut signature file ${SignFileXC} from package \"${XTRAC_PACK_NAME}\" to ${CCPROJECTHOME}/product/${ProductName}/v${PROD_VER}/pack"
			print "HCO_COMMAND=$HCO_COMMAND"
			Output INFO "..."
			chmod 555 ${SignFileXC}
			eval $HCO_COMMAND
			cat $HCO_LOG
			cat $HCO_LOG >> ${LOG_FILE}
			#cp -f ${NewSignature} ${SignFileXC}
			if [[ `grep "Checkout has been executed successfully" ${HCO_LOG}` != "" ]]; then
				HCO_STATUS="1"
				#print "HCO_STATUS = $HCO_STATUS"
			fi
			Output INFO "Copy newly created signature file to ${CCPROJECTHOME}/product/${ProductName}/v${PROD_VER}/pack before checkout"
			cp -pf ${SignFileXC} ${CCPROJECTHOME}/product/${ProductName}/v${PROD_VER}/pack/${SignFileNameXC}
		else
			Output INFO "Package \"${XTRAC_PACK_NAME}\" was not created so signature file ${SignFileXC} will be not Checked Out"
		fi
	else
		print "\nTrying to CheckOut signature file ${SignFileXC} from package \"${XTRAC_PACK_NAME}\" to ${OUT_DIR}"
		print "HCO_COMMAND=$HCO_COMMAND"
	fi
		
	if [[ "${HCP_STATUS}" = "1" ]]; then
		Output INFO "\nCheckIn new signature file to \"${XTRAC_PACK_NAME}\"."
		Output INFO "HCI_COMMAND=$HCI_COMMAND"
		if [[ "$JUST_PRINT" != "on" ]];then
			print "..."
			eval $HCI_COMMAND
			cat $HCI_LOG
			cat $HCI_LOG >> ${LOG_FILE}
			if [[ `grep "Checkin has been executed successfully" ${HCI_LOG}` != "" && `grep "No changes detected in" ${HCI_LOG}` = "" ]]; then
				HCI_STATUS="1"
				#print "HCI_STATUS = $HCI_STATUS"
			fi 
		fi
	else
		Output INFO "Package \"${XTRAC_PACK_NAME}\" was not created so signature file ${SignFileXC} will be not Checked In"
	fi
	
	Output INFO "\nPromoting package \"${XTRAC_PACK_NAME}\""
	if [[ "$JUST_PRINT" != "on" ]];then
		Output INFO "\n1st promote step - Promoting package \"${XTRAC_PACK_NAME}\" from state \"Infra\" to state \"Build\""
		Output INFO "HPP_COMMAND=${HPP_COMMAND}"
		if [[ "${HCI_STATUS}" = "1" ]]; then
			print "..."
			eval $HPP_COMMAND
			cat $HPP_LOG
			cat $HPP_LOG >> ${LOG_FILE}
			if [[ `grep "hpp has been executed successfully" ${HPP_LOG}` != "" ]]; then
				HPP_STATUS="1"
				Output INFO "HPP_STATUS = $HPP_STATUS , Package \"${XTRAC_PACK_NAME}\" was promoted succesfully from state \"Infra\" to state \"Build\"."
			else
				Output ERROR "HPP_STATUS = $HPP_STATUS , Package \"${XTRAC_PACK_NAME}\" was not promoted from state \"Infra\" to state \"Build\"."
			fi
		else
			Output INFO "No file exist in package \"${XTRAC_PACK_NAME}\" so promote will be note done"
		fi
		
		if [[ "${HPP_STATUS}" = "1" ]]; then
			Output INFO "\2nd promote step - Promoting package \"${XTRAC_PACK_NAME}\" from state \"Build\" to state \"Completed\""
			Output INFO "HPP_TO_COMPLET_COMMAND=${HPP_TO_COMPLET_COMMAND}"
			print "..."
			eval $HPP_TO_COMPLET_COMMAND
			cat $HPP_TO_COMPLET_LOG
			cat $HPP_TO_COMPLET_LOG >> ${LOG_FILE}
			if [[ `grep "hpp has been executed successfully" ${HPP_TO_COMPLET_LOG}` != "" ]]; then
				HPP_TO_COMPLET_STATUS="1"
				Output INFO "HPP_TO_COMPLET_STATUS = $HPP_TO_COMPLET_STATUS , Package \"${XTRAC_PACK_NAME}\" was promoted succesfully from state \"Build\" to state \"Completed\"."
			else
				Output ERROR "HPP_STATUS = $HPP_STATUS , Package \"${XTRAC_PACK_NAME}\" was not promoted from state \"Build\" to state \"Completed\"."
			fi
		else
			Output INFO "There is no package \"${XTRAC_PACK_NAME}\" in state Build so promote to Completed will not be done"
		fi
		
		if [[ "${HPP_TO_COMPLET_STATUS}" = "1" ]]; then
			Output INFO "\n3rd promote step - Promoting package \"${XTRAC_PACK_NAME}\" from state \"Completed\" to state \"Public\""
			Output INFO "HPP_TO_PUBLIC_COMMAND=${HPP_TO_PUBLIC_COMMAND}"
			print "..."
			eval $HPP_TO_PUBLIC_COMMAND
			cat $HPP_TO_PUBLIC_LOG
			cat $HPP_TO_PUBLIC_LOG >> ${LOG_FILE}
			if [[ `grep "hpp has been executed successfully" ${HPP_TO_PUBLIC_LOG}` != "" ]]; then
				HPP_TO_PUBLIC_STATUS="1"
				Output INFO "HPP_TO_PUBLIC_STATUS = $HPP_TO_PUBLIC_STATUS , Package \"${XTRAC_PACK_NAME}\" was promoted succesfully from state \"Completed\" to state \"Public\"."
			else
				Output ERROR "HPP_STATUS = $HPP_STATUS , Package \"${XTRAC_PACK_NAME}\" was not promoted from state \"Completed\" to state \"Public\"."
			fi
		else
				Output INFO "There is no package \"${XTRAC_PACK_NAME}\" in state Completed so promote to Public will not be done"
		fi
		
		
	fi
	
else
	Output ERROR "New signature file $NewSignature is empty or not exist"
	Output ERROR "XtraC package will not be created and CheckIn will not be done"
	exit 1;
	#exitFunc 1 
fi
}


packSources() {
	echo "Start Packing source files into $SourceFilesTar"
	echo "Start Packing source files into $SourceFilesTar" >> ${LOG_FILE}
	date
	date >> ${LOG_FILE}
	cd ${PROJECTHOME}
	
	if [[ ! -d ${SourceFilesDir} ]]; then
		echo "mkdir -p ${SourceFilesDir}"
		mkdir -p ${SourceFilesDir}
	fi
	if [[ -f ${SourceFilesTar} ]]; then
		echo "Removing old file(s) ${SourceFilesTar}"
		rm -f ${SourceFilesTar}
	fi
	if [[ -f ${SourceFilesTar}.gz ]]; then
		echo "Removing old file(s) ${SourceFilesTar}.gz "
		rm -f ${SourceFilesTar}.gz
	fi	
	echo "packing sources to file ${SourceFilesTar}.gz"

	#echo "\ls -d bb/*/${BbVer} | egrep -v 'build\/${BbVer}|ant\/${BbVer}|gpack\/${BbVer}|gdd\/${BbVer}|_generated\/${BbVer}|gmanifests\/${BbVer}|apm\/${BbVer}|_config\/${BbVer}'"
	#for bbn in `\ls -d bb/*/${BbVer} | egrep -v "build\/${BbVer}|ant\/${BbVer}|gpack\/${BbVer}|gdd\/${BbVer}|_generated\/${BbVer}|gmanifests\/${BbVer}|apm\/${BbVer}|_config\/${BbVer}"`; do
	#	echo Packing sources from BB $bbn
	#	tar -rf $SourceFilesTar `find ${bbn} -type f | egrep -v "bb_profile|\.harvest\.sig|make\.|build\.xml|build_|build\."` 2> /dev/null
	#done 
	BBListFile=${CCPROJECTHOME}/tmp/bblist.$$
	touch $BBListFile;
	for projn in `GetListOfCCEnt -pd $PRODUCT_NAME -v v${PROD_VER} -p -ngdd` ; do
		for bbn in `cat $CCPROJECTHOME/proj/${projn}/proj_profile | egrep -v '^BBnames =|^SubProjects = ' | awk '{print $1}' | egrep -v "build|ant|gpack|gdd|_generated|gmanifests|apm|_config}"` ; do
			if [[ `grep XX${bbn}XX ${BBListFile}` = "" ]] ; then
				echo Packing sources from BB $bbn ...
				tar -rf $SourceFilesTar `find bb/${bbn}/${BbVer} -type f | egrep -v "bb_profile|\.harvest\.sig|\.vcproj|make\.|main\.list|build\.xml|build_|build\."` 2> /dev/null
				echo XX${bbn}XX >> ${BBListFile}
			fi
		done
	done
	
	
	for projn in `GetListOfCCEnt -pd $PRODUCT_NAME -v v${PROD_VER} -p -ngdd` ; do
		echo Packing sources from Project ${projn}V${VARIANT} ...
		tar -rf $SourceFilesTar proj/${projn}V${VARIANT}/*/*.c proj/${projn}V${VARIANT}/*/*.cpp 2> /dev/null
	done
	
	echo "The Source files tar is ready:"
	ll ${SourceFilesTar}
	echo "The Source files tar is ready:"  >> ${LOG_FILE}
	ll ${SourceFilesTar} >> ${LOG_FILE}	
	date
	echo "Compressing ${SourceFilesTar} to ${SourceFilesTar}.gz"
	echo "Please wait..."
	date  >> ${LOG_FILE}
	echo "Compressing ${SourceFilesTar} to ${SourceFilesTar}.gz . Please wait..." >> ${LOG_FILE}
	date >> ${LOG_FILE}
	date
		gzip ${SourceFilesTar}
	echo "The Source files archive is ready:"
	ll ${SourceFilesTar}.gz
	date
	echo "The Source files archive is ready:" >> ${LOG_FILE}
	ll ${SourceFilesTar}.gz  >> ${LOG_FILE}
	date >> ${LOG_FILE}
}	

createAffectedFilesList() {
	
	echo "The affected files list will be created as ${AffectedList}"
	rm -f ${AffectedList}
	touch ${AffectedList}
	
	TotalNumberOfFiles=0
	
	for AFFECTED_FILE in `ls ${OUT_DIR}/Tmp/affected/*.affected | awk -F\/ '{print $NF}'` ; do
		module_name=`echo $AFFECTED_FILE | sed 's/\.affected//'`
		NumberOfFilesInManifest=0
		for LINE in `cat ${OUT_DIR}/Tmp/affected/$AFFECTED_FILE | sed 's/ /\*/g'` ; do
			LINE=`echo $LINE | sed 's/\*/ /g'`
			TotalNumberOfFiles=`expr $TotalNumberOfFiles + 1`
			NumberOfFilesInManifest=`expr $NumberOfFilesInManifest + 1`
			echo "$TotalNumberOfFiles\t.${module_name}.\t$NumberOfFilesInManifest\t${LINE}" | sed 's/\|/	/' >> ${AffectedList}
		done
	done
}

#############################################################		
#                       M  A  I  N                          #		
#############################################################		
				
if [ $# -eq 0 ] ;then		
Usage		
fi		
	
BAD_PARAM=""		
unset PELM_PROJ_SUFFIX

flagsArray="pack_type prod_ver major_prod_ver variant prod_name patch_ver dep_patch_ver out_dir run_mode debug just_print checkin pack_src"		

while [[ $1 != '' ]]
do		
   case $1 in		
		
# Params for CreatePackage.ksh		
# CompareAgainstFlags() ensures that if a flag with no param is given, script will abort.		
	     -help)		
        	Usage		
		;;		
	     -pack_type)
		PACK_TYPE_MULTI=${2}
		shift		
		shift		
		;; 
		-prod_ver)
		export PROD_VER=${2}
		shift		
		shift		
		;; 
		-major_prod_ver)
		export MAJOR_PROD_VER=${2}
		shift		
		shift		
		;; 
		-variant)
		export VARIANT=${2}
		shift		
		shift		
		;; 
		-prod_name)
		export PRODUCT_NAME=${2}
		shift		
		shift		
		;; 
		-patch_ver)
		export PATCH_VER=${2}
		shift		
		shift		
		;; 
		-dep_patch_ver)
		export DEP_PATCH_VER=${2}
		shift		
		shift		
		;; 
		-dest_ver)
		export DEST_VER=${2}
		shift		
		shift		
		;; 
		-out_dir)
		OUT_DIR_FLAG=${2}
		shift		
		shift	
		;; 
		-run_mode)
		export RUN_MODE=${2}
		shift
		shift
		;;
		-checkin)
		export CHECKIN=${2}
		shift
		shift
		;;
		-is_lm)
		IS_LM=${2}
		shift
		shift
		;;
		-pack_src)
		PACK_SRC=${2}
		shift
		shift
		;;
		-debug)
		export DEBUG=${2}
		shift
		shift
		;;
		-just_print)
		export JUST_PRINT=${2}
		shift
		shift
		;;
	        *)		
		Output ERROR "Unknown parameter: ${1}"
		Usage		
		;;		
	esac		
done

for PACK_TYPE in `echo $PACK_TYPE_MULTI | sed 's/\,/ /g'` ; do
	if [[ "$PACK_TYPE" != "rt" &&  "$PACK_TYPE" != "sdk" && "$PACK_TYPE" != "sdk_api" && "$PACK_TYPE" != "sdk_trb32" ]]; then
		print "Unacceptable pack_type: $PACK_TYPE"
		print "The only acceptable values of -pack_type: rt, sdk, sdk_api, sdk_trb32"
		exit 1
	fi
	
	if [[ "$PACK_TYPE" = "sdk" ]]; then
		if [[ "$PACK_SRC" != "on" && "$PACK_SRC" != "off" ]]; then
			print "Flag -pack_src must be provided as \"on\" or \"off\" in case of \"-pack_type sdk\""
			exit 1			
		fi
	fi
	if [[ "$PACK_TYPE" = "sdk_trb32" && "$VARIANT" != "32" ]]; then
		Output ERROR "Only variant 32 is acceptable in case of \"-pack_type sdk_trb32\""
 		exitFunc 1
 	fi
done

for PACK_TYPE in `echo $PACK_TYPE_MULTI | sed 's/\,/ /g'` ; do
	
	IS_SIGNATURE_CREATED="no"
	checkPackagerParam

	print "\n\n------------- Running packager for $PACK_TYPE  --------------------\n\n"
	runxAmdocsPackager

	if [[ "$CHECKIN" = "on" ]]; then
		if [[ "$IS_SIGNATURE_CREATED" = "yes" ]]; then 
			echo "Performing checkin to XtraC for $PACK_TYPE"
			checkInSignature
		else
			echo "WARNING! CheckIn of signature $PACK_TYPE to XtraC will not be done as signature was not created"
		fi
	fi
	
	if [[ "$IS_SIGNATURE_CREATED" = "yes" ]]; then 
		createAffectedFilesList
		if [[ "$PACK_TYPE" = "sdk" && "$PACK_SRC" = "on" ]]; then 
			packSources
		fi
	else
		echo "WARNING: The affected files list will not be created as creating of the signature file failed"
	fi
done

## Copy common log file to Log directory of each package at the end of the packaging
for PACK_TYPE in `echo $PACK_TYPE_MULTI | sed 's/\,/ /g'` ; do
	if [[ "$PACK_TYPE" = "sdk" ]]; then
		cp $LOG_FILE ${OUT_DIR_FLAG}/SdkPatchDir/Log
	fi
	if [[ "$PACK_TYPE" = "rt" ]]; then
		cp $LOG_FILE ${OUT_DIR_FLAG}/RtPatchDir/Log
	fi
	if [[ "$PACK_TYPE" = "sdk_api" ]]; then
		cp $LOG_FILE ${OUT_DIR_FLAG}/ApiPatchDir/Log
	fi
	if [[ "$PACK_TYPE" = "sdk_trb32" ]]; then
		cp $LOG_FILE ${OUT_DIR_FLAG}/Trb32PatchDir/Log
	fi	
done

	
exitFunc 0		
