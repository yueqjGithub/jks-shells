echo 'ready to build ios client'

pwd
# 执行autoBuild.sh~
cd ${WORKSPACE}/ios_avalon/AvalonUIKit || exit 1
sh autoBuild.sh || exit 1
cd ${WORKSPACE}/ios_avalon/AvalonFoundation || exit 1
sh autoBuild.sh || exit 1

# 复制成果文件
cd ${WORKSPACE}
if [ -d 'dist' ]; then
    rm -rf dist || exit 1
else
    mkdir dist
fi

mv ${WORKSPACE}/ios_avalon/AvalonUIKit/AProducts/AvalonUIKit.xcframework/ios-arm64_armv7/AvalonUIKit.framework ${WORKSPACE}/dist/

echo "压缩成果包"
if [[ ${versioncode_w} == null ]]; then
   echo "未定义versioncode_w，使用默认值release"
fi
fileName=${JOB_BASE_NAME}_${appVersion}_R${GIT_COMMIT:0:6}_B${BUILD_NUMBER}_${versioncode_w}
zipName=${fileName}.zip
txtName=${fileName}.txt

cd dist


mkdir client_ios

mv `ls | grep -v client_ios` client_ios/

zip -r -q "${zipName}" client_ios/

rm -rf client_ios || exit 1

if [ ${android_result} != '' ];then
  curl -u quanjiang.yue:Avalonyqj123@ https://newjenkins.avalongames.com/job/AvalonWeb/job/SuperSDK/job/Client/lastSuccessfulBuild/artifact/dist/${android_result} -o ${WORKSPACE}/ios_avalon/dist/${android_result}
fi

/usr/local/Cellar/md5sha1sum/0.9.5_1/bin/md5sum "${zipName}" | cut -d ' ' -f1 | tee "${txtName}"