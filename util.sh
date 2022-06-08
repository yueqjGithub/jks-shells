#!/usr/bin/env bash

# 拉取仓库代码
function avalon_web_cd_pull_repo() {
    local repo="$1"
    local branch="$2"

    if [[ ${repo} == '' ]]; then
        echo '未设置仓库地址'
        return 1
    fi

    if [[ ${branch} == '' ]]; then
        echo '未设置仓库分支'
        return 1
    fi

    if [[ ${repo} == git@* ]]; then
        echo '从git拉取代码'
        git clone -b="${branch}" --depth=1 "${repo}"
        return 0
    elif [[ ${repo} == https://svn* ]]; then
        echo '从svn拉取代码'
        local svnVersion="$3"
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
