#!/usr/bin/env bash

# 检查参数
function avalon_web_cd_check_param() {
    if [[ ${CD_REPO} == '' ]]; then
        echo '未设置仓库http地址'
        return 1
    fi
    if [[ ${CD_BRANCH} == '' ]]; then
        echo '未设置仓库分支'
        return 1
    fi
    if [[ ${CD_REPO} == https://svn* ]] && [[ ${CD_SVN_VERSION} == '' ]]; then
        echo '未设置svn版本号'
        return 1
    fi
    if [[ ${CD_APPLIST} == '' ]]; then
        echo '未设置应用列表'
    fi

}

# 拉取仓库代码,应用列表位于${WORKSPACE}/build/目录
function avalon_web_cd_pull_repo() {
    local repo="$1"
    local branch="$2"

    if [[ ${repo} == *git.avalongames.com* ]]; then
        echo '从公司内网git拉取代码'
        repo=$(echo "${repo}" | sed "s/http\:\/\//git@/g" | sed "s/https\:\/\//git@/g" | sed "s/avalongames.com\//avalongames.com:/g")
        git clone -b"${branch}" --depth=1 "${repo}"
        local projectName=$(echo "${repo}" | sed "s/.*\///g" | sed "s/\.git//g")
        mv ${WORKSPACE}/${projectName} ${WORKSPACE}/build
        cd ${WORKSPACE}/build || exit 1
        return 0
    elif [[ ${repo} == *svn.avalongames.com* ]]; then
        echo '从公司内网svn拉取代码'
        local svnVersion="$3"
        mkdir ${WORKSPACE}/build
        cd ${WORKSPACE}/build || exit 1
        #获取svn最新版本号
        if [[ $3 == 'latest' ]]; then
            for i in $(svn info "${repo}/${branch}" --trust-server-cert --non-interactive | grep Revision); do
                svnVersion=$(echo "${i}" | sed 's:Revision\: ::g')
            done
        fi

        svn co "${repo}/${branch}" -r "${svnVersion}" --trust-server-cert --non-interactive
        return 0
    else
        echo "无法识别的从仓库地址:${repo}"
        return 1
    fi
}

# 构建应用
function avalon_web_cd_build_app() {
    local appList="$1"

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
}
