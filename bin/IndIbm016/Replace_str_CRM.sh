#!/usr/local/bin/tcsh

#set base_dir = /clrhome/clr/ccclr/mb_ccclr/tmp/Claro
set base_dir = $CCWSCA/config/ClaroClient/ESB/Claro

foreach wsdl ( `find . -name "*.wsdl"` )
setenv file_name  `echo $wsdl | awk -F/ '{print $4}' | awk -F. '{print $1}'`
set dir_name_1 =  `echo $wsdl | awk -F/ '{print $2}'`
set dir_name = $dir_name_1/v1
echo Replace string to $file_name in $dir_name
cd  $base_dir/$dir_name
  

perl -pe 's|targetNamespace="http://www.claro.com.br/EBO/Claro/v1|targetNamespace="http://www.claro.com.br/EBO/Claro/v1/'$file_name'"|g' -pi *.xsd
perl -pe 's|targetNamespace="http://www.claro.com.br/EBS/Claro/v1"|targetNamespace="http://www.claro.com.br/EBS/Claro/v1/'$file_name'"|g' -pi *.wsdl
perl -pe 's|targetNamespace="http://www.claro.com.br/EBO/Claro/v1"|targetNamespace="http://www.claro.com.br/EBO/Claro/v1/'$file_name'"|g' -pi *.wsdl
perl -pe 's|targetNamespace="http://www.claro.com.br/EBS/Claro/v1"|targetNamespace="http://www.claro.com.br/EBS/Claro/v1/'$file_name'"|g' -pi *.xsd



end

