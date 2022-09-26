BUILD_ID=dontKillMe

if [[ ${CD_BUILD_NAME} == '' ]]; then
  echo '未设置参数发布名称'
  exit 1
fi

if [[ ${CD_BUILD_VERSION} == '' ]]; then
  echo '未设置发布版本'
  exit 1
fi

ftpPath=''
ftpUser=webuser
ftpPassword=vy6Ks348a7s88

if [[ ${CD_BUILD_TYPE} =~ 'channel' ]]; then
  ftpPath='corp/PackTools/dev/channels'
else
  ftpPath='corp/PackTools/dev/plugins'
fi


cd ${WORKSPACE}

if [[ -d build_result ]]; then
  echo "删除旧的build_result文件夹"
  rm -rf build_result
fi

mkdir build_result

echo "发布信息"
echo "发布类型为${CD_BUILD_TYPE}"
echo "发布版本为${CD_BUILD_VERSION}"
echo "发布渠道为${CD_BUILD_NAME}"


echo "根据发布类型进入对应目录"
cd ${CD_BUILD_TYPE}

echo "检测是否有需要发布的插件或渠道"
if [[ -e ${CD_BUILD_NAME}/${CD_BUILD_vERSION} ]]; then
  echo "检测到需要发布的插件或渠道"
  echo "开始收集文件"
  cp -r ${CD_BUILD_NAME}/${CD_BUILD_VERSION} ${WORKSPACE}/build_result
  cd ${WORKSPACE}/build_result
  echo "开始压缩文件"
  zip -r -q ${CD_BUILD_NAME}-${CD_BUILD_VERSION}.zip ${CD_BUILD_VERSION}
  md5sum "${CD_BUILD_NAME}-${CD_BUILD_VERSION}.zip" | cut -d ' ' -f1 | tee "${CD_BUILD_NAME}-${CD_BUILD_VERSION}_${BUILD_NUMBER}.txt"

  echo '上传ftp'
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
else
  echo "未检测到需要发布的插件或渠道"
  exit 1
fi
