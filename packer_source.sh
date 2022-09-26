BUILD_ID=dontKillMe
if [[ ${ftpPath} == '' ]]; then
  echo '未设置参数ftpPath (ftp上传路径)'
  exit 1
fi

if [[ ${CD_BUILD_NAME} == '' ]]; then
  echo '未设置参数发布名称'
  exit 1
fi

if [[ ${CD_BUILD_VERSION} == '' ]]; then
  echo '未设置发布版本'
  exit 1
fi

ftpUser=webuser
ftpPassword=vy6Ks348a7s88

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
fileName = ${CD_BUILD_NAME}-${CD_BUILD_VERSION}
if [[ -e ${CD_BUILD_NAME}/${CD_BUILD_vERSION} ]]; then
  echo "检测到需要发布的插件或渠道"
  echo "开始收集文件"
  cp -r ${CD_BUILD_NAME}/${CD_BUILD_VERSION} ${WORKSPACE}/build_result
  cd ${WORKSPACE}/build_result
  echo "开始压缩文件"
  zip -r -q ${fileName}.zip ${CD_BUILD_VERSION}
  md5sum "${fileName}.zip" | cut -d ' ' -f1 | tee "${fileName}_${BUILD_NUMBER}.txt"
else
  echo "未检测到需要发布的插件或渠道"
  exit 1
fi

