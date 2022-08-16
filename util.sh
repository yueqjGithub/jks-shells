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
# 第一个参数 仓库类型,git或svn
# 第二个参数 仓库分支
# 第三个参数 仓库地址
# 第四个参数 svn版本号
function avalon_web_cd_pull_repo() {
    local repoType=$1
    local branch=$2
    local repoUrl=$3
    local svnVersion=$4
    # 仓库代码在build中的子路径
    local buildSubPath=$(bash md5.sh "${repoUrl}")

    if [[ ${repoType} == "git" ]]; then
        echo '从公司内网git拉取代码'
        #http协议转为git协议
        local gitProtocolUrl=$(echo "${repoUrl}" | sed "s/http\:\/\//git@/g" | sed "s/https\:\/\//git@/g" | sed "s/avalongames.com\//avalongames.com:/g")
        local branhName=$(echo "${branch}" | sed "s/.*\///g")
        git clone -b"${branhName}" --depth=1 "${gitProtocolUrl}"
        local projectName=$(echo "${gitProtocolUrl}" | sed "s/.*\///g" | sed "s/\.git//g")
        mkdir -p ${WORKSPACE}/build/${buildSubPath}
        mv ${WORKSPACE}/${projectName}/* ${WORKSPACE}/build/${buildSubPath}/
        cd ${WORKSPACE}/build || exit 1
        return 0
    elif [[ ${repoType} == "svn" ]]; then
        echo '从公司内网svn拉取代码'
        mkdir -p ${WORKSPACE}/build/${buildSubPath}
        cd ${WORKSPACE}/build/${buildSubPath} || exit 1
        #获取svn最新版本号
        if [[ ${svnVersion} == 'latest' ]]; then
            for i in $(svn info "${repoUrl}/${branch}" --trust-server-cert --non-interactive | grep Revision); do
                svnVersion=$(echo "${i}" | sed 's:Revision\: ::g')
            done
        fi

        svn co "${repoUrl}/${branch}" -r "${svnVersion}" --trust-server-cert --non-interactive
        return 0
    else
        echo "无法识别的从仓库地址:${repoUrl}"
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

        local appConfigStr=${app}
        local appPath=$(bash -x ${WORKSPACE}/custom_string_parse.sh ${appConfigStr})
        # 根据应用配置的对应仓库，获取最终的build路径
        local appRepoId=$(bash -x ${WORKSPACE}/custom_string_parse.sh ${appConfigStr} 仓库id)
        local appRepoUrl=""
        if [[ "${appRepoId}" != "" ]]; then
            local matchResult=$(echo "${CD_REPO}" | sed -rn "s/^([^()]+)\([^()]*仓库id:${appRepoId}[,)].*$/\1/p")
            if [[ ${#matchResult[*]} == 1 ]]; then
                appRepoUrl="${matchResult[0]}"
            fi
        fi
        if [[ "${appRepoUrl}" == "" ]]; then
            #仓库只有一个时，使用默认值
            appRepoUrl=$(bash -x ${WORKSPACE}/custom_string_parse.sh ${CD_REPO})
        fi

        local appSubPath=$(bash md5.sh "${appRepoUrl}")
        local appAbsolutePath="${WORKSPACE}/build/${appSubPath}/${appPath}"

        local appName=$(echo "${appPath}" | sed -r 's/.+\///g')
        # 是否压缩应用，运维标准不统一，遗留问题
        local willZipApp=true

        cd "${appAbsolutePath}" || exit 1

        [[ -d "${appAbsolutePath}" ]] || mkdir "${appAbsolutePath}"

        local appType='未知'
        local buildFile="${appAbsolutePath}/*"
        if [[ -f 'composer.json' ]] && [[ $(cat composer.json | grep "laravel/framework") ]]; then
            appType='laravel'
        elif [[ -f 'webpack.config.custom.js' ]]; then
            appType='front'
            buildFile="${appAbsolutePath}/dist/*"
            if [[ -f "${appAbsolutePath}/next.config.js" ]] || [[ -f "${appAbsolutePath}/vite.confit.ts" ]]; then
                willZipApp=false
            fi
        elif [[ -f 'package.json' ]]; then
            appType='node'
            if [[ -f "${appAbsolutePath}/next.config.js" ]] || [[ -f "${appAbsolutePath}/vite.confit.ts" ]]; then
                willZipApp=false
            fi
        elif [[ -f 'pom.xml' ]]; then
            appType='java'
            # java应用不压缩目录
            willZipApp=false
            jarPath=$(bash -x ${WORKSPACE}/custom_string_parse.sh ${appConfigStr} jar包路径)
            if [[ jarPath == "" ]]; then
                echo "未配置jar包路径"
                exit 1
            fi

            buildFile="${WORKSPACE}/build/${appSubPath}/${jarPath}"
            # 如果java应用的仓库根目录就是应用，则使用jar名称作为应用名
            if [[ ${appName} == "" ]]; then
                local deployAppName=$(bash -x ${WORKSPACE}/custom_string_parse.sh ${appConfigStr} 部署名称)
                if [[ ${deployAppName} == "" ]]; then
                    echo "未配置部署名称"
                    exit 1
                fi
                appName="${deployAppName}"
            fi
        fi

        if [[ appName == "" ]]; then
            echo "非java单应用仓库的应用名称不能为空:${appRepoUrl}"
            exit 1
        fi

        local destAppDir=${destDir}/${appName}
        [[ -d "${destAppDir}" ]] || mkdir "${destAppDir}" || exit 1


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
            # 复制sql与properties文件
            mkdir ${destAppDir}/sql
            mv ${appAbsolutePath}/config/* ${destAppDir}/sql
            mv ${destAppDir}/sql/application.* ${destAppDir}
        fi

        if [[ -f "${appAbsolutePath}/custom-build/build.sh" ]]; then
            echo "${appName}检测到自定义脚本custom-build/build.sh，开始执行"
            bash "${appAbsolutePath}/custom-build/build.sh" || exit 1
            cd "${appAbsolutePath}" || exit 1
        else
            echo "${appName}未检测到自定义脚本custom-build/build.sh，无需执行"
        fi

        cp -R ${buildFile} "${destAppDir}" || exit 1

        if [[ ${willZipApp} == "true" ]]; then
            #压缩
            cd "${destDir}" || exit 1
            zip -r -q "${appName}.zip" "${appName}/"
            rm -rf "${destAppDir}"
        fi
    done

    #生成readme和Version.txt
    cd "${WORKSPACE}/build" || exit 1
    local version=$(git rev-list --all | wc -l)
    cd "${WORKSPACE}/dist/${CD_ZIP_ROOT}" || exit 1
    echo "${CD_README}" | sed 's: :\n:g' >readme.txt
    echo "${version}" >Version.txt

    #压缩并生成md5
    zipname=${CD_ZIP_PREFIX}_${CD_APP_VERSION}_${version}_${BUILD_NUMBER}
    if [[ ${CD_VERSION_W} != "" ]]; then
      zipname="${zipname}_${CD_VERSION_W}"
    fi
    zipname="${zipname}.zip"
    echo "${zipname}"
    echo "${CD_VERSION_W}"

    echo "${zipname}" > ${WORKSPACE}/build/zipname.txt

    cd "${WORKSPACE}/dist" || exit 1
    if [[ ${CD_ZIP_ROOT} == "" ]];then
        zip -r -q "${zipname}" *
    else
        zip -r -q "${zipname}" "${CD_ZIP_ROOT}"
    fi

    md5sum "${zipname}" | cut -d ' ' -f1 | tee "${zipname}.txt"


}

# 更新到服务器
function avalon_web_cd_update_to_server(){
    OLD_IFS="$IFS"
    IFS=","
    updateTargetList=(${CD_SELECTED_SERVERS})
    IFS="$OLD_IFS"
    zipname=$(cat ${WORKSPACE}/build/zipname.txt)
    for ut in ${updateTargetList[@]}; do
        local targetName=$(bash -x ${WORKSPACE}/custom_string_parse.sh ${ut})
        echo "#自动更新到"${targetName}
        local paramStr=$(echo "${ut}" | sed "s/.*(//g" | sed "s/).*//g")
        local user=$(bash -x ${WORKSPACE}/custom_string_parse.sh ${ut} user)
        if [[ ${user} == "" ]]; then
            user="webuser"
        fi

        local ip=$(bash -x ${WORKSPACE}/custom_string_parse.sh ${ut} ip)
        local port=$(bash -x ${WORKSPACE}/custom_string_parse.sh ${ut} 端口)
        local willSudo=$(bash -x ${WORKSPACE}/custom_string_parse.sh ${ut} 是否sudo)
        local deployDir=$(bash -x ${WORKSPACE}/custom_string_parse.sh ${ut} 部署目录)

        scp -P ${port} ${WORKSPACE}/dist/${zipname} ${user}@${ip}:/tmp/
cat >${WORKSPACE}/dist/update_${JOB_BASE_NAME}.sh <<EOF
#!/usr/bin/env bash
echo "#解压并移动到指定目录"
# 创建用于更新的临时目录
rm -rf ${deployDir}/update_tmp
mkdir ${deployDir}/update_tmp
mv -f /tmp/${zipname} ${deployDir}/update_tmp/ || exit 1
if [[ -f ${deployDir}/update_tmp/${zipname} ]]; then

else
    echo "zip更新包不存在:${deployDir}/update_tmp/${zipname}"
    exit 1
fi
cd ${deployDir}/update_tmp || exit 1
# 查看目录结构，获取要更新的应用列表
zipStruct=$(unzip -l ${zipname} | sed -rn "s/^\s+[0-9]+\s+[0-9:]+.+\s+(\S+)$/\1/p" || exit 1)
updateApps=$(echo \${zipStruct} | sed -rn "s/^([^/]+\/)$/\1/p" | sed -rn "s/^([^/]+)\/*$/\1/p" || exit 1)
echo "更新的应用列表:${updateApps}"

appZips=$(ls *.zip 2> /dev/null | wc -l)
if [[ "\${appZips}" != "0" ]]; then
    unzip -o ${zipname} || exit 1
fi

if [[ "${CD_ZIP_ROOT}" != "" ]]; then
    mv -f ${deployDir}/update_tmp/${CD_ZIP_ROOT}/*.zip ${deployDir}/update_tmp/update_tmp || exit 1
    rm -rf ${deployDir}/update_tmp/${CD_ZIP_ROOT}/ || exit 1
fi

rm -f ${zipname} || exit 1
cd ${deployDir}/update_tmp
# 尝试解压所有应用的zip
unzip -o *.zip
cd ${deployDir}

for i in \${updateApps}
  do
    appName=\`echo \${i} | cut -f 1 -d .\`

    echo "#开始更新\${appName}应用"
    appType=
    if [[ -f \${appName}.json ]] || [[ -f \${appName}.yaml ]]; then
      configFileType="json"
      configFileType=\$([[ -f \${appName}.yaml ]] && echo "yaml" )
      appType=pm2
      echo "检测到文件\${appName}.\${configFileType},判断为node应用,使用pm2更新"
      pm2 delete \${appName}.\${configFileType}
      echo "删除原目录"
      rm -rf \${appName}
      mv update_tmp/\${appName} ./
    elif [[ -f \${appName}/.env ]]; then
      appType=php
      echo "laravel应用需要备份.env文件"
      mv \${appName}/.env \${appName}.env
      rm -rf \${appName}
      mv update_tmp/\${appName} ./
      mv \${appName}.env \${appName}/.env 
    elif [[ -f \${appName}/\${appName}.jar ]]; then
      appType=java
      echo "java应用需要备份.properties文件"
      pid=$(ps ax | grep -i \${appName}.jar |grep java | grep -v grep | awk '{print $1}') || exit 1
      if [ -z "\$pid" ] ; then
        echo "\${appName}.jar未运行,不做停服处理"
      else
        kill \${pid}
      fi
      mv \${appName}/\${appName}.properties \${appName}.properties
      rm -rf \${appName}
      mv update_tmp/\${appName} ./
      mv \${appName}.properties \${appName}/\${appName}.properties    
    else
      rm -rf \${appName}
      mv update_tmp/\${appName} ./
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

    # 启动服务器，仅pm2和java需要执行启动
    if [[ \${appType} == 'pm2' ]]; then
      pm2 start \${appName}.\${configFileType}
    elif [[ \${appType} == 'java' ]]; then
      nohup java -Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8  -jar  \${appName}/\${appName}.jar --config-path=\${appName}/\${appName}.properties &
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

  zipname=$(cat ${WORKSPACE}/build/zipname.txt)

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

