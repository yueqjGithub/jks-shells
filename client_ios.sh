BUILD_ID=dontKillMe
if [[ ${ftpPath} == '' ]]; then
  echo '未设置参数ftpPath (ftp上传路径)'
  exit 1
fi

ftpUser=webuser
ftpPassword=vy6Ks348a7s88

echo "成品类型=${resultType}"


if [[ ${resultType} == 'apk' ]]; then
  if [[ ${SUPER_SDK_APP_ID} == '' ]]; then
    echo "打包APK必须填写SUPER_SDK_APP_ID"
    exit 1
  fi
  if [[ ${SUPER_SDK_APP_KEY} == '' ]]; then
    echo "打包APK必须填写SUPER_SDK_APP_KEY"
    exit 1
  fi
  if [[ ${SUPER_SDK_ENV} == '' ]]; then
    echo "打包APK必须填写SUPER_SDK_ENV"
    exit 1
  fi
fi

echo "修改library参数"
#cd AvalonGameCenter/build.gradle
libraryVal=true
if [[ ${resultType} == 'apk' ]]; then
    libraryVal=false
fi
echo ${libraryVal}
sed -i '/library =/ d' AvalonGameCenter/build.gradle | exit 1
sed -i "1i boolean library=${libraryVal}" AvalonGameCenter/build.gradle | exit 1
echo "修改library参数完毕"

echo "插入参数"
if [[ ${resultType} == 'apk' ]]; then
    lineNum=$(echo $(sed -n '/\/application/=' AvalonGameCenter/src/main/AndroidManifest.xml))
    lineNum=$((10#${lineNum}-1))
    echo "${lineNum}"
    cat >tmp_xml.xml <<EOF
        <meta-data
            android:name="SUPER_SDK_APP_ID"
            android:value="${SUPER_SDK_APP_ID}" />

        <meta-data
            android:name="SUPER_SDK_APP_KEY"
            android:value="${SUPER_SDK_APP_KEY}" />

        <meta-data
            android:name="SUPER_SDK_ENV"
            android:value="${SUPER_SDK_ENV}" />
EOF
    sed -i "${lineNum} r tmp_xml.xml" AvalonGameCenter/src/main/AndroidManifest.xml
    echo "修改UnityPlayerActivity"
    sed -i 's/extends UnityPlayerActivity/extends Activity/' AvalonGameCenter/src/main/java/com/avalon/gamecenter/AvalonGameBaseActivity.java
    sed -i 's/CMODE = "release"/CMODE = "debug"/' AvalonGameCenter/src/main/java/com/avalon/gamecenter/AvalonGameBaseActivity.java
fi

echo "参数插入结束，执行gradle命令生成"
echo "复制local.properties到工作目录"
cp dist/local.properties ./
gradle :AvalonGameCenter:clean && gradle :AvalonGameCenter:assembleRelease
echo "gradle执行完成,创建成果目录"
mkdir build_result

# IOS部分
echo "压缩IOS两个git仓库，存放到IOS目标机器"
ios_zipname=ios_client.zip
ios_port=22
ios_user=webuser
ios_ip=10.172.182.44
ios_deployDir=/Users/webuser/workspace

zip -r -q "${ios_zipname}" ./ios_*_client || exit 1
rm -rf ios_*_client*
echo "将zip发送到IOS目标机器"

scp -P ${ios_port} ${WORKSPACE}/${ios_zipname} ${ios_user}@${ios_ip}:/tmp/
rm -rf ${WORKSPACE}/${ios_zipname}
cat >${WORKSPACE}/update_${JOB_BASE_NAME}.sh <<EOF
#!/usr/bin/env bash
echo "#解压并移动到指定目录"
# 创建用于更新的临时目录
rm -rf ${ios_deployDir}/update_tmp
mkdir ${ios_deployDir}/update_tmp
mv -f /tmp/${ios_zipname} ${ios_deployDir}/update_tmp/ || exit 1
cd ${ios_deployDir}/update_tmp || exit 1

# 解压更新包
pwd
unzip ${ios_zipname} || exit 1
rm -f ${ios_zipname} || exit 1

echo "执行autoBuild.sh"

# workspace/update_tmp

echo "开始收集IOS成果"
cd ${ios_deployDir}
# workspace
if [ -d dist ];then
  rm -rf dist
fi
mkdir dist

cd ${ios_deployDir}/update_tmp/ios_super_client || exit 1
sh autoBuild.sh
mv -f AProducts/AvalonSuperSDK.xcframework/ios-arm64_armv7/AvalonSuperSDK.framework ${ios_deployDir}/dist/
cd ${ios_deployDir}/update_tmp/ios_avalon_client/AvalonUIKit || exit 1
sh autoBuild.sh
mv -f AProducts/AvalonUIKit.xcframework/ios-arm64_armv7/AvalonUIKit.framework ${ios_deployDir}/dist/
cd ${ios_deployDir}/update_tmp/ios_avalon_client/AvalonFoundation
sh autoBuild.sh
mv -f AProducts/AvalonFoundation.xcframework/ios-arm64_armv7/AvalonFoundation.framework ${ios_deployDir}/dist/
cd ${ios_deployDir}/update_tmp/ios_avalon_client/SDKDemo/Bundle
mv -f AvalonPluginResources.bundle ${ios_deployDir}/dist/
mv -f AvalonResource.bundle ${ios_deployDir}/dist/

cd ${ios_deployDir}/dist

zip -r -q -m ios_result.zip ./*

echo "复制zip回到jenkins打包机，注意核对返回结果机器Ip和用户名，scp需要ssh-copy-id"
scp -P ${ios_port} ${ios_deployDir}/dist/ios_result.zip webuser@192.168.200.25:/tmp/ || exit 1
echo "IOS机器处理结束"
EOF
scp -P ${ios_port} ${WORKSPACE}/update_${JOB_BASE_NAME}.sh ${ios_user}@${ios_ip}:/tmp/ || exit 1
ssh -p ${ios_port} -T ${ios_user}@${ios_ip} "bash /tmp/update_${JOB_BASE_NAME}.sh" || exit 1

echo "将ios_result.zip赋给jenkins"
cd /tmp
sudo chown jenkins ios_result.zip
cd ${WORKSPACE}
pwd
whoami
if [ -d ios_result ]; then
  rm -rf ios_result
fi
mkdir ios_result
cd ios_result
mv /tmp/ios_result.zip ${WORKSPACE}/ios_result
unzip ios_result.zip
rm -rf ios_result.zip
echo "复制IOS成果到unity工程"
cp -rf ${WORKSPACE}/ios_result/* ${WORKSPACE}/unity_core/SuperSDK/Assets/Plugins/iOS/
rm -rf ${WORKSPACE}/ios_result

# IOS部分结束
cd ${WORKSPACE}

if [[ ${resultType} == 'aar' ]]; then
    echo "文件类型为aar，执行后续操作"
    echo "修改arr文件名,并移动至unity_core"
    mv -f AvalonGameCenter/build/outputs/aar/AvalonGameCenter-release.aar AvalonGameCenter/build/outputs/aar/avalon-ssdk.aar
    mv -f AvalonGameCenter/build/outputs/aar/avalon-ssdk.aar unity_core/SuperSDK/Assets/Plugins/Android
    echo "移动arr文件完成，复制所需文件"
    cp -rf unity_core/SuperSDK/Assets/AvalonSuperSDK/* unity_core/avalon-ssdk-upload/Runtime/AvalonSuperSDK/
    cp -rf unity_core/SuperSDK/Assets/Editor/* unity_core/avalon-ssdk-upload/Editor/
    cp -rf unity_core/SuperSDK/Assets/Plugins/* unity_core/avalon-ssdk-upload/Plugins/
    echo "移动对应文件完成，修改版本号"
    lineNum=$(echo $(sed -n '/version/=' unity_core/avalon-ssdk-upload/package.json))
    sed -i "${lineNum}d" unity_core/avalon-ssdk-upload/package.json
    sed -i "${lineNum}i \"version\": \"${appVersion}\"," unity_core/avalon-ssdk-upload/package.json
    echo "版本号修改完成,移动到成果目录"
    mv unity_core/avalon-ssdk-upload build_result
elif [[ ${resultType} == 'apk' ]]; then
    echo "文件类型为apk，直接复制apk到build_result目录"
    mv AvalonGameCenter/build/outputs/apk/release/AvalonGameCenter-release.apk build_result
fi
echo "压缩成果文件，上传ftp"
zipName=${zipPre}${JOB_BASE_NAME}_${appVersion}_R${GIT_COMMIT:0:6}_B${BUILD_NUMBER}_${versioncode_w}.zip
txtName=${zipName}.txt

cd build_result
mkdir client
mv `ls | grep -v client` client/
zip -r -q "${zipName}" client
if [[ ${versioncode_w} == null ]]; then
    echo "未定义versioncode_w，使用默认值release"
fi
md5sum "${zipName}" | cut -d ' ' -f1 | tee "${txtName}"

if [ ${willUploadFtp} == 'true' ]; then
ftp -n <<-EOF
  open ftp.avalongames.com
  user ${ftpUser} ${ftpPassword}
  cd ${ftpPath}
  bin
  put ${zipName}
  put ${txtName}
  bye
EOF
#检查ftp上传是否成功
if [[ $? > 0 ]]; then
    echo "ftp上传失败，构建结束"
    exit 1
fi
fi

echo "写入归档文件"
releaseinfoName=${zipPre}${JOB_BASE_NAME}_${appVersion}_R${GIT_COMMIT:0:6}_B${BUILD_NUMBER}_${versioncode_w}.releaseinfo
cd ${WORKSPACE}
[[ -d "dist" ]] || mkdir "dist"
rm -rf dist/*.releaseinfo || exit 0
archivePath=${WORKSPACE}/dist/${releaseinfoName}
cat >>${archivePath} <<EOF
更新包名:
  ${zipName}
  
更新内容:
  ${readme}
EOF

rm -rf ${WORKSPACE}/dist/*.zip || exit 1
mv ${WORKSPACE}/build_result/${zipName} ${WORKSPACE}/dist/

echo "web归档文件【build号】= ${BUILD_NUMBER} ，【文件名】= ${releaseinfoName} "
echo "包名：${zipName}"

cd ${WORKSPACE}
rm -rf `ls | grep -v dist` || exit 0

#cd ${WORKSPACE}
#rm -rf `ls | grep -v dist` || exit 0
