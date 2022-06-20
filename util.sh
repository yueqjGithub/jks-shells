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
    if [[ ${CD_REPO} == *git.avalongames.com* ]]; then
        echo '从公司内网git拉取代码'
        #http协议转为git协议
        local gitProtocolUrl=$(echo "${CD_REPO}" | sed "s/http\:\/\//git@/g" | sed "s/https\:\/\//git@/g" | sed "s/avalongames.com\//avalongames.com:/g")
        local branhName=$(echo "${CD_BRANCH}" | sed "s/.*\///g")
        git clone -b"${branhName}" --depth=1 "${gitProtocolUrl}"
        local projectName=$(echo "${gitProtocolUrl}" | sed "s/.*\///g" | sed "s/\.git//g")
        mv ${WORKSPACE}/${projectName} ${WORKSPACE}/build
        cd ${WORKSPACE}/build || exit 1
        return 0
    elif [[ ${CD_REPO} == *svn.avalongames.com* ]]; then
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

# 构建应用,构建后的文件位于 ${WORKSPACE}/dist/${CD_ZIPROOT} 目录下
function avalon_web_cd_build_app() {

    destDir=${WORKSPACE}/dist/${CD_ZIPROOT}
    mkdir -p ${destDir}

    OLD_IFS="$IFS"
    IFS=","
    apps=(${CD_APPLIST})
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
        cd "${WORKSPACE}/build" || exit 1
        zip -r -q "${appName}.zip" "${appName}/"
        [[ -d ${destDir} ]] || mkdir "${destDir}"
        mv "${appName}.zip" "${destDir}" || exit 1
        rm -rf "${destAppDir}"

    done

    #生成readme和Version.txt
    cd "${WORKSPACE}/build" || exit 1
    local version=$(echo "git rev-parse --short HEAD")
    cd "${WORKSPACE}/dist/${CD_ZIPROOT}" || exit 1
    echo "${CD_REAMME}" | sed 's: :\n:g' >readme.txt
    echo "${version}" >Version.txt

    #压缩并生成md5
    cd "${WORKSPACE}/dist" || exit 1
    zipname=${zipPrefix}_${CD_APPVERSION}_${version}_${BUILD_NUMBER}.zip
    txtname=${zipname}.txt
    zip -r -q "${zipname}" ${CD_ZIPROOT}/
    md5sum "${zipname}" | cut -d ' ' -f1 | tee "${txtname}"
}
