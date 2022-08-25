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
    rm -rf dist
else
    mkdir dist
fi

cp -r ${WORKSPACE}/ios_avalon/AvalonUIKit/AProducts/AvalonUIKit.xcframework/ios-arm64_armv7/AvalonUIKit.framework ${WORKSPACE}/dist