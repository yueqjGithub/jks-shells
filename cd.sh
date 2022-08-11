#!/usr/bin/env bash

echo "当前node版本$(node -v)"
echo "当前npm版本$(npm -v)"

#参数检测
if [[ ${ftpPath} == '' ]]; then
  echo '未设置参数ftpPath (ftp上传路径)'
  exit 1
fi
if [[ ${appSvnDir} == '' ]] || [[ ${appGitDir} == '' ]]; then
  echo '未设置参数appSvnDir/appGitDir (项目svn目录或git目录)'
  exit 1
fi

repoType="svn"
if [[ ${appSvnDir} == '' ]]; then
  repoType="git"
fi

if [[ ${repoType} == "svn" ]] && [[ ${svnVersion} == '' ]]; then
  echo '未设置参数svnVersion (svn版本号)'
  exit 1
fi
if [[ ${appVersion} == '' ]]; then
  echo '未设置参数appVersion (项目版本号)'
  exit 1
fi
if [[ ${branch} == '' ]]; then
  echo '未设置参数branch (项目分支)'
  exit 1
fi
if [[ ${willUploadFtp} == '' ]]; then
  echo '未设置参数willUploadFtp (是否上传ftp)'
  exit 1
fi
if [[ ${webpackMode} == '' ]]; then
  echo '未设置参数webpackMode,默认为测试环境 (webpack打包模式)'
  webpackMode="测试环境"
fi

appVersion=$(echo "${appVersion}" | awk -F"[ ]" '{print $1}')
echo "appVersion=${appVersion}"

#配置
zipPrefix=${JOB_BASE_NAME}
zipRootDirName=web
ftpUser=webuser
ftpPassword=vy6Ks348a7s88

#工作目录初始化
echo "当前jenkins工作目录${WORKSPACE}"
cd "${WORKSPACE}" || exit 1
rm -rf build
mkdir build
rm -rf dist
mkdir dist
cd build || exit 1
mkdir dist
cd ../dist || exit 1
mkdir ${zipRootDirName}
mkdir "${WORKSPACE}/build/repo"
cd "${WORKSPACE}/build" || exit 1

if [[ repoType == "svn" ]]; then
  #获取svn最新版本号
  if [[ ${svnVersion} == 'latest' ]]; then
    for i in $(svn info "${appSvnDir}/${branch}" --trust-server-cert --non-interactive | grep Revision); do
      svnVersion=$(echo "${i}" | sed 's:Revision\: ::g')
    done
  fi
fi

#从仓库拉取源代码
cd "${WORKSPACE}/build/repo" || exit 1
if [[ repoType == "svn" ]]; then
  #拉取svn
  svn co "${appSvnDir}/${branch}" -r "${svnVersion}" --trust-server-cert --non-interactive >/dev/null 2>&1 || { echo '拉取svn失败,svn日志太多未进行打印,请检查svn权限' && exit 1 ;}
else
  #拉取git
  git clone --depth=1 "${appGitDir}"
fi

#应用列表
OLD_IFS="$IFS"
IFS=","
apps=(${appList})
IFS="$OLD_IFS"
for app in ${apps[@]}; do

  appName=${app##*/}

  echo "开始构建应用${appName}"

  destDir=${WORKSPACE}/dist/${zipRootDirName}

  cd "${WORKSPACE}/build/repo/${appName}" || exit 1

  [[ -d "${WORKSPACE}/build/${appName}" ]] || mkdir "${WORKSPACE}/build/${appName}"

  appType='未知'
  buildFile="${WORKSPACE}/build/repo/${appName}/*"
  if [[ -f 'composer.json' ]] && [[ $(cat composer.json | grep "laravel/framework") ]]; then
    appType='laravel'
  elif [[ -f 'webpack.config.custom.js' ]]; then
    appType='front'
    buildFile="${WORKSPACE}/build/repo/${appName}/dist/*"
  elif [[ -f 'package.json' ]]; then
    appType='node'
  elif [[ -f 'pom.xml' ]]; then
    appType='java'
    buildFile="${WORKSPACE}/build/repo/${appName}/target/${appName}.jar"
  fi

  echo "${appName}应用类型=${appType}"

  if [ ${appType} == 'front' ]; then
    #前端应用
    echo "安装依赖库"
    npm install --unsafe-perm || exit 1
    echo "执行构建"
    if [[ ${webpackMode} == '测试环境' ]]; then
      npm run dev || exit 1
    else
      npm run release || exit 1
    fi
  fi

  if [[ ${appType} == 'laravel' ]]; then
    #laravel应用
    echo "安装依赖库"
    composer install || exit 1
    echo "执行构建"
    rm -rf storage
    rm -rf bootstrap/cache
    mkdir -p storage/app/public
    mkdir -p storage/framework/cache/data
    mkdir -p storage/framework/sessions
    mkdir -p storage/framework/testing
    mkdir -p storage/framework/views
    mkdir -p storage/logs
    mkdir -p bootstrap/cache
    composer dump-autoload
    #laravel最后再删除.env,避免composer调用失败
    rm -f .env
  fi

  if [[ ${appType} == 'node' ]]; then
    #node应用
    echo "安装依赖库"
    npm install --unsafe-perm || exit 1
    #判断是否需要执行命令
    echo "执行构建"
    if [[ ${webpackMode} == '测试环境' ]]; then
      if [[ $(cat package.json | grep "\"dev\"") ]]; then
        echo 'package.json中存在dev命令，开始执行'
        npm run dev || exit 1
      else
        echo 'package.json中不存在dev命令，无需执行'
      fi
    else
      if [[ $(cat package.json | grep "\"release\"") ]]; then
        echo 'package.json中存在release命令，开始执行'
        npm run release || exit 1
      else
        echo 'package.json中不存在release命令，无需执行'
      fi
    fi
  fi

  if [[ ${appType} == 'java' ]]; then
    #java应用
    echo "安装依赖库"
    mvn clean install -DskipTests || exit 1
    

  fi

  if [[ -f "${WORKSPACE}/build/repo/${appName}/custom-build/build.sh" ]]; then
    echo "${appName}检测到自定义脚本custom-build/build.sh，开始执行"
    bash "${WORKSPACE}/build/repo/${appName}/custom-build/build.sh" || exit 1
    cd "${WORKSPACE}/build/repo/${appName}" || exit 1
  else
    echo "${appName}未检测到自定义脚本custom-build/build.sh，无需执行"
  fi

  mv ${buildFile} "${WORKSPACE}/build/${appName}" || exit 1

  #压缩并移动
  cd "${WORKSPACE}/build" || exit 1
  zip -r -q "${appName}.zip" "${appName}/"
  [[ -d ${destDir} ]] || mkdir "${destDir}"
  mv "${appName}.zip" "${destDir}" || exit 1

done

#生成readme和Version.txt
cd "${WORKSPACE}/build" || exit 1
echo "${readme}" | sed 's: :\n:g' >readme.txt
echo "${svnVersion}" >Version.txt
mv "${WORKSPACE}/build/readme.txt" "${WORKSPACE}/dist/${zipRootDirName}" || exit 1
mv "${WORKSPACE}/build/Version.txt" "${WORKSPACE}/dist/${zipRootDirName}" || exit 1
cd "${WORKSPACE}/dist" || exit 1

#执行自定义脚本
if [[ "${customShellPath}" == '' ]]; then
  echo '未设置参数customShellPath，不执行自定义脚本'
else
  echo "开始执行自定义脚本${customShellPath}"
  bash "${customShellPath}" || exit 1
fi

#压缩并生成md5
cd "${WORKSPACE}/dist" || exit 1
zipname=${zipPrefix}_${appVersion}_${svnVersion}_${BUILD_NUMBER}.zip
txtname=${zipname}.txt
zip -r -q "${zipname}" ${zipRootDirName}/
md5sum "${zipname}" | cut -d ' ' -f1 | tee "${txtname}"

#更新到服务器
OLD_IFS="$IFS"
IFS=","
updateTargetList=(${updateTarget})
IFS="$OLD_IFS"
for ut in ${updateTargetList[@]}; do
  targetName=$(echo "${ut}" | sed "s/(.*)//g")
  echo "#自动更新到"${targetName}
  paramStr=$(echo "${ut}" | sed "s/.*(//g" | sed "s/).*//g")
  ip=$(echo "${paramStr}" | sed "s/.*ip://g" | sed "s/，.*//g")
  port=$(echo "${paramStr}" | sed "s/.*端口://g" | sed "s/，.*//g")
  willSudo=$(echo "${paramStr}" | sed "s/.*是否sudo://g" | sed "s/，.*//g")
  deployDir=$(echo "${paramStr}" | sed "s/.*部署目录://g" | sed "s/，.*//g")

  scp -P ${port} ${WORKSPACE}/dist/${zipname} webuser@${ip}:/tmp/
  cat >${WORKSPACE}/dist/update_${JOB_BASE_NAME}.sh <<EOF
#!/usr/bin/env bash
echo "#解压并移动到指定目录"
mv -f /tmp/${zipname} ${deployDir}/
cd ${deployDir}
unzip -o ${zipname}
mv -f ${deployDir}/web/*.zip ${deployDir}/
rm -rf ${deployDir}/web/
rm -f ${zipname}

echo "#遍历目录"
for i in \`ls -l ${deployDir}/ | awk '/.zip$/{print \$NF}'\`
  do
    appName=\`echo \${i} | cut -f 1 -d .\`

    echo "#开始更新\${appName}应用"
    if [[ -f \${appName}.json ]]; then
      echo "检测到文件\${appName}.json,判断为node应用,使用pm2更新"
      pm2 delete \${appName}.json >/dev/null 2>&1
      echo "删除原目录"
      rm -rf \${appName}
      unzip -o \${appName}.zip >/dev/null 2>&1
      pm2 start \${appName}.json >/dev/null 2>&1
    elif [[ -f \${appName}/.env ]]; then
      echo "laravel应用需要备份.env文件"
      mv \${appName}/.env \${appName}.env
      rm -rf \${appName}
      unzip -o \${appName}.zip >/dev/null 2>&1
      mv \${appName}.env \${appName}/.env 
    elif [[ -f \${appName}/\${appName}.jar ]]; then
      echo "java应用需要备份.properties文件"
      pid=$(ps ax | grep -i \${appName}.jar |grep java | grep -v grep | awk '{print $1}') || exit 1
      if [ -z "\$pid" ] ; then
        echo "\${appName}.jar未运行,不做停服处理"
      else
        kill \${pid}
      fi
      mv \${appName}/\${appName}.properties \${appName}.properties
      rm -rf \${appName}
      unzip -o \${appName}.zip >/dev/null 2>&1
      mv \${appName}.properties \${appName}/\${appName}.properties       
      nohup java -Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8  -jar  \${appName}/\${appName}.jar --config-path=\${appName}/\${appName}.properties  >/dev/null 2>&1 &
    else
      rm -rf \${appName}
      unzip -o \${appName}.zip >/dev/null 2>&1
    fi

    if [[ -f \${appName}/custom-build/before-app-start.sh ]]
    then    
      echo "开始执行应用启动前的自定义脚本"
      cd \${appName}
      bash custom-build/before-app-start.sh
      cd ../
    else
      echo "\${appName}未检测到应用启动前的自定义脚本custom-build/before-app-start.sh，无需执行"
    fi

    rm -f \${appName}.zip
  done

exit 0
EOF
  scp -P ${port} ${WORKSPACE}/dist/update_${JOB_BASE_NAME}.sh webuser@${ip}:/tmp/ || exit 1

  sudoStr=''
  if [[ ${willSudo} == 'true' ]]; then
    echo "#以管理员执行命令"
    sudoStr='sudo -i'
  fi

  ssh -p ${port} -T webuser@${ip} "${sudoStr} bash /tmp/update_${JOB_BASE_NAME}.sh" || exit 1
done

if [[ ${willUploadFtp} == 'true' ]]; then
  echo "上传ftp"
  ftp -n <<-EOF
open ftp.avalongames.com
user ${ftpUser} ${ftpPassword}
cd ${ftpPath}
bin
put ${zipname}
put ${txtname}
bye
EOF
  #检查ftp上传是否成功
  if [[ $? > 0 ]]; then
    exit 1
  fi

  echo "写入归档文件"
  releaseinfoName=${appVersion}.releaseinfo
  archivePath=${WORKSPACE}/dist/${releaseinfoName}
  if [[ ${#appList[@]} > 0 ]]; then
    cat >>${archivePath} <<EOF
更新包名:
  ${zipname}  
EOF
  fi
  if [[ -n ${readme} ]]; then
    cat >>${archivePath} <<EOF
配置更新:
  ${readme}  
EOF
  fi
  echo "web归档文件【build号】= ${BUILD_NUMBER} ，【文件名】= ${releaseinfoName} "
  echo "包名：${zipname}"
fi