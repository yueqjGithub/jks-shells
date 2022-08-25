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
cd and_super
exit 0
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
cp ${WORKSPACE}/dist/local.properties ./
gradle :AvalonGameCenter:clean && gradle :AvalonGameCenter:assembleRelease
echo "gradle执行完成,创建成果目录"
mkdir ${WORKSPACE}/build_result

if [[ ${resultType} == 'aar' ]]; then
    echo "文件类型为aar，执行后续操作"
    echo "修改arr文件名,并移动至unity_core"
    mv -f AvalonGameCenter/build/outputs/aar/AvalonGameCenter-release.aar AvalonGameCenter/build/outputs/aar/avalon-ssdk.aar
    mv -f AvalonGameCenter/build/outputs/aar/avalon-ssdk.aar ${WORKSPACE}/unity_core/SuperSDK/Assets/Plugins/Android
    echo "移动arr文件完成，复制所需文件"
    cp -rf ${WORKSPACE}/unity_core/SuperSDK/Assets/AvalonSuperSDK/* ${WORKSPACE}/unity_core/avalon-ssdk-upload/Runtime/AvalonSuperSDK/
    cp -rf ${WORKSPACE}/unity_core/SuperSDK/Assets/Editor/* ${WORKSPACE}/unity_core/avalon-ssdk-upload/Editor/
    cp -rf ${WORKSPACE}/unity_core/SuperSDK/Assets/Plugins/Android/* ${WORKSPACE}/unity_core/avalon-ssdk-upload/Plugins/Android/
    echo "移动对应文件完成，修改版本号"
    lineNum=$(echo $(sed -n '/version/=' unity_core/avalon-ssdk-upload/package.json))
    sed -i "${lineNum}d" ${WORKSPACE}/unity_core/avalon-ssdk-upload/package.json
    sed -i "${lineNum}i \"version\": \"${appVersion}\"," ${WORKSPACE}/unity_core/avalon-ssdk-upload/package.json
    echo "版本号修改完成,移动到成果目录"
    mv ${WORKSPACE}/unity_core/avalon-ssdk-upload ${WORKSPACE}/build_result
elif [[ ${resultType} == 'apk' ]]; then
    echo "文件类型为apk，直接复制apk到build_result目录"
    mv AvalonGameCenter/build/outputs/apk/release/AvalonGameCenter-release.apk ${WORKSPACE}/build_result
fi
echo "压缩成果文件，上传ftp"
zipName=${zipPre}${JOB_BASE_NAME}_${appVersion}_R${GIT_COMMIT:0:6}_B${BUILD_NUMBER}_${versioncode_w}.zip
txtName=${zipName}.txt

cd ${WORKSPACE}/build_result
mkdir client
mv `ls | grep -v client` client/
zip -r -q "${zipName}" client
if [[ ${versioncode_w} == null ]]; then
    echo "未定义versioncode_w，使用默认值release"
fi
/usr/local/Cellar/md5sha1sum/0.9.5_1/bin/md5sum "${zipName}" | cut -d ' ' -f1 | tee "${txtName}"
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