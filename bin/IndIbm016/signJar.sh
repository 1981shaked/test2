#!/bin/ksh

export CCBUILD=`grep ^build.number ${CCBB_ccrm9Configuration}/${CCVER}/build.number | awk -F"=" '{print $2}'` 
export STORE_ALIAS=AmdocsAlias
export STORE_PWD=AmdocsStorePassword
export KEY_PWD=AmdocsKeyPass
export STORE_NAME=AmdocsStoreName
export VALID_DAYS=3650
export SIGN_INFO="-keystore ${STORE_NAME} -storepass ${STORE_PWD} -keypass ${KEY_PWD}"
export PACK_MEM="-J-Xmx512m"
export PATH=${PATH}:${JAVA_HOME}/bin:${JAVA_HOME}/jre/bin 
export OUTPUT_DIR=${HOME}/tmp/output_jars
export JARVER=$(echo $CCPRODVERNUM)

createDir(){
        if [[ ! -d "$1" ]]; then
                        mkdir $1
        fi
}

genKey(){
        keytool -genkey -alias ${STORE_ALIAS} -keypass ${KEY_PWD} -validity ${VALID_DAYS} -keystore ${STORE_NAME} -storepass ${STORE_PWD} -dname "cn=Amdocs Internal, ou=Amdocs Internal, o=CRM, c=US"
}

normalizeJars(){
        echo "Normalize jars for signing..."
        #First repack
        #for f in *.jar; do pack200 --repack ${PACK_OPTION} ${PACK_MEM} ${OUTPUT_DIR}/t_$f $f; done
        #--------------------------------------------------------------------
        # DO NOT REMOVE!!!!
        # For big jar, must do the 2nd repack to make sure jar is normalized probably
        #--------------------------------------------------------------------
        #:doRePack2nd
        #echo Repacking Jars
        #for %%f in (*.jar) do pack200 --repack %PACK_OPTION% %PACK_MEM% %OUTPUT_DIR%\s_%%f %OUTPUT_DIR%\t_%%f
        #echo Clean up jars
        #for %%f in (*.jar) do del /q %OUTPUT_DIR%\t_%%f
}
 
signAndPack(){
        #sign
        echo "Normalize ${1} for signing..."
        #First repack
        cp -f ${OUTPUT_DIR}/$1 ${OUTPUT_DIR}/t_$1
        pack200 --repack ${PACK_OPTION} ${PACK_MEM} ${OUTPUT_DIR}/$1 ${OUTPUT_DIR}/t_$1
        rm -f ${OUTPUT_DIR}/t_$1
        echo "Signing...."
        cp -f ${OUTPUT_DIR}/$1 ${OUTPUT_DIR}/s_$1
        jarsigner ${SIGN_INFO} -signedjar ${OUTPUT_DIR}/$1 ${OUTPUT_DIR}/s_$1 ${STORE_ALIAS} ${PACK_MEM}
        #pack
        echo "Packing...."
        pack200 ${PACK_MEM} ${OUTPUT_DIR}/$1.pack.gz ${OUTPUT_DIR}/$1
        rm -f ${OUTPUT_DIR}/s_$1
}
 
unsignJar(){
        echo "Unsigning ${1} \c"
        createDir temp
        cp -f $1 ./temp
        cd temp
        echo "[Unpacking jar] \c"
        jar xf $1
        rm -f $1
        echo "[Removing signature] \c"
        rm -f  `ls META-INF/*.SF META-INF/*.RSA META-INF/*.DSA`
        echo "[Packing jar]"
        jar cf $1 .
        mv -f $1 ${OUTPUT_DIR}
        cd ${OUTPUT_DIR} 
        rm -fR temp
        #rm ./temp/$1
}
 
doAll(){
        unsignJar $1
        signAndPack $1
}
 
verifyAll(){
        echo "Verify signed jars"
        for f in *.jar; do unpack200 ${PACK_MEM} ${OUTPUT_DIR}/$f.pack.gz ${OUTPUT_DIR}/v_$f; done
        for f in *.jar; do
                        echo "Verifying --> ${f}"
                        jarsigner -verify ${OUTPUT_DIR}/v_$f;
        done
        for f in *.jar; do rm -f ${OUTPUT_DIR}/v_$f; done
}

### work directory....
echo "createing ${OUTPUT_DIR}"
createDir ${OUTPUT_DIR}
rm -f ${OUTPUT_DIR}/*

cp -rf ${CCBB_ccrm9Configuration}/${CCVER}/templates/SMARTWEB/${STORE_NAME} ${OUTPUT_DIR}

echo "coping ${CCBB_ccrm9Configuration}/${CCVER}/scanner jars to ${OUTPUT_DIR}" 
cp -rf ${CCBB_ccrm9Configuration}/${CCVER}/cc/scanner/*.jar ${OUTPUT_DIR}
cp -rf ${SDK_CRM_HOME}/CRM/application/installedApps/ClfyAgent/ClfyAgent.war/WEB-INF/lib/xercesImpl.jar ${OUTPUT_DIR}


echo "coping ${SDK_CRM_HOME}/SMARTWEB/war/CRM/* to ${OUTPUT_DIR} "
cp -Rf ${SDK_CRM_HOME}/SMARTWEB/war/CRM/*  ${OUTPUT_DIR}/

echo "coping ${CCMPA}/lib/IsbCrmClient.jar ${OUTPUT_DIR} "
cp -Rf ${CCMPA}/lib/IsbCrmClient.jar ${OUTPUT_DIR}/ 


## Loop on all jar files...

cd ${OUTPUT_DIR}

for f in *.jar; do doAll $f; done

mv -f IsbCrmClient.jar IsbCrmClient__V${JARVER}_${CCBUILD}.jar

## VERIFY...
#verifyAll

cp -f ${OUTPUT_DIR}/* $CCWPA/bin/
echo "END"

