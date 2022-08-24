echo 'ready to build ios client'

pwd
# 执行autoBuild.sh
cd ${WORKSPACE}/ios_avalon/AvalonUIKit || exit 1
sh autoBuild.sh || exit 1
cd ${WORKSPACE}/ios_avalon/AvalonFoundation || exit 1
sh autoBuild.sh || exit 1