#!/usr/bin/env bash
#jenkins专用打包脚本，函数会直接使用jenkins环境变量和用户自定义变量

#清空上一次的构建残留
function avalon_web_cd_clear_build() {
    local projectName=$(echo "${CD_REPO}" | sed "s/.*\///g" | sed "s/\.git//g")
    rm -rf ${WORKSPACE}/build
    rm -rf ${WORKSPACE}/dist
    rm -rf ${WORKSPACE}/${projectName}
}

# 拉取仓库代码,应用列表位于 ${WORKSPACE}/build/ 目录下
function avalon_web_cd_pull_repo() {
    if [[ ${CD_REPO_TYPE} == "git" ]]; then
        echo '从公司内网git拉取代码'
        #http协议转为git协议
        local gitProtocolUrl=$(echo "${CD_REPO}" | sed "s/http\:\/\//git@/g" | sed "s/https\:\/\//git@/g" | sed "s/avalongames.com\//avalongames.com:/g")
        local branhName=$(echo "${CD_BRANCH}" | sed "s/.*\///g")
        git clone -b"${branhName}" --depth=1 "${gitProtocolUrl}"
        local projectName=$(echo "${gitProtocolUrl}" | sed "s/.*\///g" | sed "s/\.git//g")
        mv ${WORKSPACE}/${projectName} ${WORKSPACE}/build
        cd ${WORKSPACE}/build || exit 1
        return 0
    elif [[ ${CD_REPO_TYPE} == "svn" ]]; then
        echo '从公司内网svn拉取代码'
        mkdir ${WORKSPACE}/build
        cd ${WORKSPACE}/build || exit 1
        #获取svn最新版本号
        if [[ ${CD_SVNVERSION} == 'latest' ]]; then
            for i in $(svn info "${CD_REPO}/${CD_BRANCH}" --trust-server-cert --non-interactive | grep Revision); do
                svnVersion=$(echo "${i}" | sed 's:Revision\: ::g')
            done
        fi

        svn co "${CD_REPO}/${CD_BRANCH}" -r "${svnVersion}" --trust-server-cert --non-interactive
        return 0
    else
        echo "无法识别的从仓库地址:${CD_REPO}"
        return 1
    fi
}

# 构建应用,构建后的文件位于 ${WORKSPACE}/dist/${CD_ZIP_ROOT} 目录下
function avalon_web_cd_build_app() {

    destDir=${WORKSPACE}/dist/${CD_ZIP_ROOT}
    mkdir -p ${destDir}

    OLD_IFS="$IFS"
    IFS=","
    apps=(${CD_SELECTED_APPS})
    IFS="$OLD_IFS"
    for app in ${apps[@]}; do

        appName=${app##*/}

        destAppDir=${destDir}/${appName}
        mkdir "${destAppDir}" || exit 1

        echo "开始构建应用${appName}"

        cd "${WORKSPACE}/build/${appName}" || exit 1

        [[ -d "${WORKSPACE}/build/${appName}" ]] || mkdir "${WORKSPACE}/build/${appName}"

        appType='未知'
        buildFile="${WORKSPACE}/build/${appName}/*"
        if [[ -f 'composer.json' ]] && [[ $(cat composer.json | grep "laravel/framework") ]]; then
            appType='laravel'
        elif [[ -f 'webpack.config.custom.js' ]]; then
            appType='front'
            buildFile="${WORKSPACE}/build/${appName}/dist/*"
        elif [[ -f 'package.json' ]]; then
            appType='node'
        elif [[ -f 'pom.xml' ]]; then
            appType='java'
            buildFile="${WORKSPACE}/build/${appName}/target/${appName}.jar"
        fi

        echo "${appName}应用类型=${appType}"

        if [ ${appType} == 'front' ]; then
            #前端应用
            echo "安装依赖库"
            npm install --unsafe-perm || exit 1
            echo "执行构建"
            npm run release || exit 1
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
            if [[ $(cat package.json | grep "\"release\"") ]]; then
                echo 'package.json中存在release命令，开始执行'
                npm run release || exit 1
            else
                echo 'package.json中不存在release命令，无需执行'
            fi
        fi

        if [[ ${appType} == 'java' ]]; then
            #java应用
            echo "安装依赖库"
            mvn clean install -DskipTests || exit 1
        fi

        if [[ -f "${WORKSPACE}/build/${appName}/custom-build/build.sh" ]]; then
            echo "${appName}检测到自定义脚本custom-build/build.sh，开始执行"
            bash "${WORKSPACE}/build/${appName}/custom-build/build.sh" || exit 1
            cd "${WORKSPACE}/build/${appName}" || exit 1
        else
            echo "${appName}未检测到自定义脚本custom-build/build.sh，无需执行"
        fi

        mv ${buildFile} "${destAppDir}" || exit 1

        #压缩并移动
        cd "${destDir}" || exit 1
        zip -r -q "${appName}.zip" "${appName}/"
        rm -rf "${destAppDir}"
    done

    #生成readme和Version.txt
    cd "${WORKSPACE}/build" || exit 1
    local version=$(git rev-parse --short HEAD)
    cd "${WORKSPACE}/dist/${CD_ZIP_ROOT}" || exit 1
    echo "${CD_README}" | sed 's: :\n:g' >readme.txt
    echo "${version}" >Version.txt

    #压缩并生成md5
    zipname=${JOB_BASE_NAME}_${CD_APP_VERSION}_${version}_${BUILD_NUMBER}.zip
    echo "${zipname}" > ${WORKSPACE}/dist/zipname.txt

    cd "${WORKSPACE}/dist" || exit 1
    zipname=${JOB_BASE_NAME}_${CD_APP_VERSION}_${version}_${BUILD_NUMBER}.zip
    zip -r -q "${zipname}" ${CD_ZIP_ROOT}/
    md5sum "${zipname}" | cut -d ' ' -f1 | tee "${zipname}.txt"


}

# 更新到服务器
function avalon_web_cd_update_to_server(){
    OLD_IFS="$IFS"
    IFS=","
    updateTargetList=(${CD_SELECTED_SERVERS})
    IFS="$OLD_IFS"
    zipname=$(cat ${WORKSPACE}/dist/zipname.txt)
    for ut in ${updateTargetList[@]}; do
        local targetName=$(echo "${ut}" | sed "s/(.*)//g")
        echo "#自动更新到"${targetName}
        local paramStr=$(echo "${ut}" | sed "s/.*(//g" | sed "s/).*//g")
        local user=$(echo "${paramStr}" | sed "s/.*user://g" | sed "s/，.*//g")        
        local ip=$(echo "${paramStr}" | sed "s/.*ip://g" | sed "s/，.*//g")
        local port=$(echo "${paramStr}" | sed "s/.*端口://g" | sed "s/，.*//g")
        local willSudo=$(echo "${paramStr}" | sed "s/.*是否sudo://g" | sed "s/，.*//g")
        local deployDir=$(echo "${paramStr}" | sed "s/.*部署目录://g" | sed "s/，.*//g")

        scp -P ${port} ${WORKSPACE}/dist/${zipname} ${user}@${ip}:/tmp/
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
    if [[ -f \${appName}.json ]] || [[ -f \${appName}.yaml ]]; then
      local configFileType="json"
      configFileType=\$([[ -f \${appName}.yaml ]] && echo "yaml" )
      echo "检测到文件\${appName}.\${configFileType},判断为node应用,使用pm2更新"
      pm2 delete \${appName}.\${configFileType} >/dev/null 2>&1
      echo "删除原目录"
      rm -rf \${appName}
      unzip -o \${appName}.zip >/dev/null 2>&1
      pm2 start \${appName}.\${configFileType} >/dev/null 2>&1
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
        scp -P ${port} ${WORKSPACE}/dist/update_${JOB_BASE_NAME}.sh ${user}@${ip}:/tmp/ || exit 1

        sudoStr=''
        if [[ ${willSudo} == 'true' ]]; then
            echo "#以管理员执行命令"
            sudoStr='sudo -i'
        fi

        ssh -p ${port} -T ${user}@${ip} "${sudoStr} bash /tmp/update_${JOB_BASE_NAME}.sh" || exit 1
    done
}

# 上传ftp
function avalon_web_cd_upload_ftp(){
  cd "${WORKSPACE}/dist" || exit 1

  zipname=$(cat ${WORKSPACE}/dist/zipname.txt)

  ftp -n <<-EOF
  open ${CD_FTP_HOST}
  user ${CD_FTP_USER} ${CD_FTP_PASS}
  cd ${CD_FTP_PATH}
  bin
  put ${zipname}
  put ${zipname}.txt
  bye
EOF
    #检查ftp上传是否成功
    if [[ $? > 0 ]]; then
      exit 1
    fi

    echo "写入归档文件"
    local releaseinfoName=${CD_APP_VERSION}.releaseinfo
    local archivePath=${WORKSPACE}/dist/${releaseinfoName}
    cat >>${archivePath} <<EOF
  更新包名:
    ${zipname}  
EOF

    if [[ -n ${readme} ]]; then
      cat >>${archivePath} <<EOF
  配置更新:
    ${readme}  
EOF
    fi
    echo "web归档文件【build号】= ${BUILD_NUMBER} ，【文件名】= ${releaseinfoName} "
    echo "包名：${zipname}"
}