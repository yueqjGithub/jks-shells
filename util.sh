#!/usr/bin/env bash

# 拉取仓库代码
function avalon_web_cd::pull_repo(){
    repo=$1
    branch=$2
    svnVersion=$3

    if [[ ${repo} == '' ]]; then
        echo '未设置仓库地址'
        exit 1
    fi

    if [[ ${branch} == '' ]]; then
        echo '未设置仓库分支'
        exit 1
    fi

    if [[ ${repo} == 'git@*' ]]; then
        echo '从git拉取代码'
        git clone --depth=1 "${repo}"
        return
    fi

    if [[ ${repo} == 'https://svn*' ]]; then
        echo '从svn拉取代码'
        #获取svn最新版本号
        if [[ $3 == 'latest' ]]; then
            for i in $(svn info "${repo}/${branch}" --trust-server-cert --non-interactive | grep Revision); do
            svnVersion=$(echo "${i}" | sed 's:Revision\: ::g')
            done
        fi

        svn co "${repo}/${branch}" -r "${svnVersion}" --trust-server-cert --non-interactive
        return
    fi

    exit 1
}