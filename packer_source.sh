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

channel_str=""

ftpPath='corp/PackTools/dev/channels'
echo "开始处理安卓渠道资源"
arr=(`echo ${CD_AND_CHANNELS} | tr ',' ' '` )

for var in ${arr[@]}
do
  cd ${WORKSPACE}/and_channel
  # echo $var
  version=${var##*-}
  name=${var%-*}
  echo $version
  echo $name
  if [[ -e $name/$version ]]; then
    echo "检测到需要发布的插件或渠道"
    echo "开始收集文件"
    cd ${WORKSPACE}/build_result
    if [[ -e $name ]]; then
      echo "已存在资源名称目录，无需创建"
    else
      mkdir $name
    fi
    cd ${WORKSPACE}/and_channel
    cp -r $name/$version ${WORKSPACE}/build_result/$name/
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
    new_str=""
    if [[ $channel_str == "" ]]; then
      new_str="$name-$version.zip"
    else
      new_str=",$name-$version.zip"
    fi
    channel_str=${channel_str}${new_str}
  else
    echo "未检测到需要发布的插件或渠道"
    exit 1
  fi
done


echo "开始处理IOS渠道资源"
arr=(`echo ${CD_IOS_CHANNELS} | tr ',' ' '` )
for var in ${arr[@]}
do
  cd ${WORKSPACE}/ios_channel
  version=${var##*-}
  name=${var%-*}
  echo $version
  echo $name
  if [[ -e $name/$version ]]; then
   echo "检测到需要发布的插件或渠道"
    echo "开始收集文件"
    cd ${WORKSPACE}/build_result
    if [[ -e $name ]]; then
      echo "已存在资源名称目录，无需创建"
    else
      mkdir $name
    fi
    cd ${WORKSPACE}/ios_channel
    cp -r $name/$version ${WORKSPACE}/build_result/$name/
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
    new_str=""
    if [[ $channel_str == "" ]]; then
      new_str="$name-$version.zip"
    else
      new_str=",$name-$version.zip"
    fi
    channel_str=${channel_str}${new_str}
  else
    echo "未检测到需要发布的插件或渠道"
    exit 1
  fi
done


plugin_str=""

echo "开始处理安卓插件资源"
ftpPath='corp/PackTools/dev/plugins'
arr=(`echo ${CD_AND_PLUGINS} | tr ',' ' '` )
for var in ${arr[@]}
do
  cd ${WORKSPACE}/and_plugin
  version=${var##*-}
  name=${var%-*}
  echo $version
  echo $name
  if [[ -e $name/$version ]]; then
    echo "检测到需要发布的插件或渠道"
    echo "开始收集文件"
    cd ${WORKSPACE}/build_result
    if [[ -e $name ]]; then
      echo "已存在资源名称目录，无需创建"
    else
      mkdir $name
    fi
    cd ${WORKSPACE}/and_plugin
    cp -r $name/$version ${WORKSPACE}/build_result/$name/
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
    new_str=""
    if [[ $plugin_str == "" ]]; then
      new_str="$name-$version.zip"
    else
      new_str=",$name-$version.zip"
    fi
    plugin_str=${plugin_str}${new_str}
  else
    echo "未检测到需要发布的插件或渠道"
    exit 1
  fi
done


echo "开始处理IOS插件资源"
arr=(`echo ${CD_IOS_PLUGINS} | tr ',' ' '` )
for var in ${arr[@]}
do
  cd ${WORKSPACE}/ios_plugin
  version=${var##*-}
  name=${var%-*}
  echo $version
  echo $name
  if [[ -e $name/$version ]]; then
    echo "检测到需要发布的插件或渠道"
    echo "开始收集文件"
    cd ${WORKSPACE}/build_result
    if [[ -e $name ]]; then
      echo "已存在资源名称目录，无需创建"
    else
      mkdir $name
    fi
    cd ${WORKSPACE}/ios_plugin
    cp -r $name/$version ${WORKSPACE}/build_result/$name/
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
    new_str=""
    if [[ $plugin_str == "" ]]; then
      new_str="$name-$version.zip"
    else
      new_str=",$name-$version.zip"
    fi
    plugin_str=${plugin_str}${new_str}
  else
    echo "未检测到需要发布的插件或渠道"
    exit 1
  fi
done

echo $plugin_str
echo $channel_str