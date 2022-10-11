BUILD_ID=dontKillMe

ftpPath=''
ftpUser=webuser
ftpPassword=vy6Ks348a7s88

echo "成品目录处理"
cd ${WORKSPACE}

if [[ -d build_result ]]; then
  echo "删除旧的build_result文件夹"
  rm -rf build_result
fi

mkdir build_result

ftpPath='corp/PackTools/dev/channels'
echo "开始处理安卓渠道资源"
arr=(`echo ${CD_AND_CHANNELS} | tr ',' ' '` )
cd ${WORKSPACE}/and_channel
for var in ${arr[@]}
do
  # echo $var
  version=${var##*-}
  name=${var%-*}
  echo $version
  echo $name
  if [[ -e $name/$version ]]; then
    echo "检测到需要发布的插件或渠道"
    echo "开始收集文件"
    cp -r $name/$version ${WORKSPACE}/build_result/$name
    cd ${WORKSPACE}/build_result/$name
    echo "开始压缩文件"
    zip -r -q $name-$version.zip $version
    # md5sum "${CD_BUILD_NAME}-${CD_BUILD_VERSION}.zip" | cut -d ' ' -f1 | tee "${CD_BUILD_NAME}-${CD_BUILD_VERSION}_${BUILD_NUMBER}.txt"

    echo '上传ftp'
    ftp -n <<-EOF
    open ftp.avalongames.com
    user ${ftpUser} ${ftpPassword}
    cd ${ftpPath}
    bin
    put $name-$version.zip
    bye
EOF
    #检查ftp上传是否成功
    if [[ $? > 0 ]]; then
        echo "ftp上传失败，构建结束"
        exit 1
    fi
  else
    echo "未检测到需要发布的插件或渠道"
    exit 1
  fi
done


echo "开始处理IOS渠道资源"
arr=(`echo ${CD_IOS_CHANNELS} | tr ',' ' '` )
cd ${WORKSPACE}/ios_channel
for var in ${arr[@]}
do
  version=${var##*-}
  name=${var%-*}
  echo $version
  echo $name
    if [[ -e $name/$version ]]; then
    echo "检测到需要发布的插件或渠道"
    echo "开始收集文件"
    cp -r $name/$version ${WORKSPACE}/build_result/$name
    cd ${WORKSPACE}/build_result/$name
    echo "开始压缩文件"
    zip -r -q $name-$version.zip $version
    # md5sum "${CD_BUILD_NAME}-${CD_BUILD_VERSION}.zip" | cut -d ' ' -f1 | tee "${CD_BUILD_NAME}-${CD_BUILD_VERSION}_${BUILD_NUMBER}.txt"

    echo '上传ftp'
    ftp -n <<-EOF
    open ftp.avalongames.com
    user ${ftpUser} ${ftpPassword}
    cd ${ftpPath}
    bin
    put $name-$version.zip
    bye
EOF
    #检查ftp上传是否成功
    if [[ $? > 0 ]]; then
        echo "ftp上传失败，构建结束"
        exit 1
    fi
  else
    echo "未检测到需要发布的插件或渠道"
    exit 1
  fi
done


echo "开始处理安卓插件资源"
ftpPath='corp/PackTools/dev/plugins'
arr=(`echo ${CD_AND_PLUGINS} | tr ',' ' '` )
cd ${WORKSPACE}/and_plugin
for var in ${arr[@]}
do
  version=${var##*-}
  name=${var%-*}
  echo $version
  echo $name
    if [[ -e $name/$version ]]; then
    echo "检测到需要发布的插件或渠道"
    echo "开始收集文件"
    cp -r $name/$version ${WORKSPACE}/build_result/$name
    cd ${WORKSPACE}/build_result/$name
    echo "开始压缩文件"
    zip -r -q $name-$version.zip $version
    # md5sum "${CD_BUILD_NAME}-${CD_BUILD_VERSION}.zip" | cut -d ' ' -f1 | tee "${CD_BUILD_NAME}-${CD_BUILD_VERSION}_${BUILD_NUMBER}.txt"

    echo '上传ftp'
    ftp -n <<-EOF
    open ftp.avalongames.com
    user ${ftpUser} ${ftpPassword}
    cd ${ftpPath}
    bin
    put $name-$version.zip
    bye
EOF
    #检查ftp上传是否成功
    if [[ $? > 0 ]]; then
        echo "ftp上传失败，构建结束"
        exit 1
    fi
  else
    echo "未检测到需要发布的插件或渠道"
    exit 1
  fi
done


echo "开始处理IOS插件资源"
arr=(`echo ${CD_IOS_PLUGINS} | tr ',' ' '` )
cd ${WORKSPACE}/ios_plugin
for var in ${arr[@]}
do
  version=${var##*-}
  name=${var%-*}
  echo $version
  echo $name
    if [[ -e $name/$version ]]; then
    echo "检测到需要发布的插件或渠道"
    echo "开始收集文件"
    cp -r $name/$version ${WORKSPACE}/build_result/$name
    cd ${WORKSPACE}/build_result/$name
    echo "开始压缩文件"
    zip -r -q $name-$version.zip $version
    # md5sum "${CD_BUILD_NAME}-${CD_BUILD_VERSION}.zip" | cut -d ' ' -f1 | tee "${CD_BUILD_NAME}-${CD_BUILD_VERSION}_${BUILD_NUMBER}.txt"

    echo '上传ftp'
    ftp -n <<-EOF
    open ftp.avalongames.com
    user ${ftpUser} ${ftpPassword}
    cd ${ftpPath}
    bin
    put $name-$version.zip
    bye
EOF
    #检查ftp上传是否成功
    if [[ $? > 0 ]]; then
        echo "ftp上传失败，构建结束"
        exit 1
    fi
  else
    echo "未检测到需要发布的插件或渠道"
    exit 1
  fi
done
