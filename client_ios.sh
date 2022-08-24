echo 'ready to build ios client'

cd ${WORKSPACE}

// 执行autoBuild.sh
sh ./ios_avalon/AvalonUIKit/autoBuild.sh
sh ./ios_avalon/AvalonFoundation/autoBuild.sh