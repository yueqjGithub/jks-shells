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
fileName=${JOB_BASE_NAME}_${appVersion}_R${GIT_COMMIT:0:6}_B${BUILD_NUMBER}
zipName=${fileName}.zip
txtName=${fileName}.txt

cd dist

curl -X post -v -u quanjiang.yue:Avalonyqj123@  https://newjenkins.avalongames.com/job/AvalonWeb/job/SuperSDK/job/Client/lastSuccessfulBuild/artifact/dist/SuperSDKClient_2.2.0_Re3d98f_B105_release.zip

#mkdir client_ios

#mv `ls | grep -v client_ios` client_ios/

#zip -r -q "${zipName}" client_ios/

#if [[ ${versioncode_w} == null ]]; then
#    echo "未定义versioncode_w，使用默认值release"
#fi

#md5sum "${zipName}.zip" | cut -d ' ' -f1 | tee "${txtName}"