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

echo '将/AvalonSSDKFramework/src/main/assets/avalon_supersdk_properties.json中super_sdk_version的值改为appVersion'
pwd
version_line_num=$(echo $(sed -n '/super_sdk_version/=' AvalonSSDKFramework/src/main/assets/avalon_supersdk_properties.json))
echo "删除原有行"
sed -i "${version_line_num}d" AvalonSSDKFramework/src/main/assets/avalon_supersdk_properties.json | exit 1
version_line_num=$((10#${version_line_num}-1))
echo "${version_line_num}"
cat >version_temp.txt <<EOF
"super_sdk_version": "${appVersion}"
EOF
sed -i "${version_line_num} r version_temp.txt" AvalonSSDKFramework/src/main/assets/avalon_supersdk_properties.json | exit 1
rm version_temp.txt
echo "super插入jiraversion完成"

echo "sueper_client_unity插入jiraversion"
cd "${WORKSPACE}/unity_core"
echo "删除原有行"
version_line_num=$(echo $(sed -n '/version/=' SuperSDK/Assets/Plugins/iOS/AvalonPluginResources.bundle/super_sdk.json))
sed -i "${version_line_num}d" SuperSDK/Assets/Plugins/iOS/AvalonPluginResources.bundle/super_sdk.json | exit 1
version_line_num=$((10#${version_line_num}-1))
echo "${version_line_num}"
cat >version_temp.txt <<EOF
"version": "${appVersion}",
EOF
sed -i "${version_line_num} r version_temp.txt" SuperSDK/Assets/Plugins/iOS/AvalonPluginResources.bundle/super_sdk.json | exit 1
rm version_temp.txt
echo "super_client_unity插入Jiraversion完成"

echo "客户端supersdk构建 需要修改一个变量static BOOL DEBUG_MODE = NO;"
cd "${WORKSPACE}/unity_core/SuperSDK/Assets/Plugins/iOS"
echo "删除原有行"
version_line_num=$(echo $(sed -n '/static BOOL DEBUG_MODE /=' AvalonCommunicateForUnity.mm))
echo "${version_line_num}"
sed -i "${version_line_num}d" AvalonCommunicateForUnity.mm | exit 1
version_line_num=$((10#${version_line_num}-1))
echo "${version_line_num}"
cat >version_temp.txt <<EOF
static BOOL DEBUG_MODE = NO;
EOF
sed -i "${version_line_num} r version_temp.txt" AvalonCommunicateForUnity.mm | exit 1
rm version_temp.txt
echo "修改AvalonCommunicateForUnity.mm完成"

exit 0

cd ${WORKSPACE}

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

cd ${WORKSPACE}

echo "参数插入结束，执行gradle命令生成"
echo "复制local.properties到工作目录"
cp dist/local.properties ./
gradle :AvalonGameCenter:clean && gradle :AvalonGameCenter:assembleRelease
echo "gradle执行完成,创建成果目录"
mkdir build_result

# IOS部分
# if [[ ${INCLUDE_IOS} ]]; then
#   echo '执行IOS相关操作'
#   cd ${WORKSPACE}
#   cp -rf ${WORKSPACE}/unity_core/SuperSDK/Assets/Plugins/iOS ${WORKSPACE}/unity_core/avalon-ssdk-upload
# fi
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
