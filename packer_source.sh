BUILD_ID=dontKillMe
if [[ ${ftpPath} == '' ]]; then
  echo '未设置参数ftpPath (ftp上传路径)'
  exit 1
fi

ftpUser=webuser
ftpPassword=vy6Ks348a7s88

cd ${WORKSPACE}

echo "发布信息"
echo "发布类型为${CD_BUILD_TYPE}"
echo "发布版本为${CD_BUILD_VERSION}"
echo "发布渠道为${CD_BUILD_NAME}"


echo "根据发布类型进入对应目录"
cd ${CD_BUILD_TYPE}

echo "检测是否有需要发布的插件或渠道"
if [[ -e ${CD_BUILD_NAME}/${CD_BUILD_vERSION} ]]; then
  echo "检测到需要发布的插件或渠道"
else
  echo "未检测到需要发布的插件或渠道"
  exit 1
fi
fi