#!/usr/bin/env bash

# 检查参数
function avalon_web_cd_check_param() {
    if [[ ${CD_REPO_HTTP} == '' ]]; then
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
}

# 拉取仓库代码
function avalon_web_cd_pull_repo() {
    local repo="$1"
    repo =$(echo "${repo}" | sed "s/http\:\/\//git@/g" | sed "s/avalongames.com\//avalongames.com:/g".git)
    local branch="$2"

    if [[ ${repo} == *git.avalongames.com* ]]; then
        echo '从公司内网git拉取代码'
        git clone -b"${branch}" --depth=1 "${repo}"
        return 0
    elif [[ ${repo} == *svn.avalongames.com* ]]; then
        echo '从公司内网svn拉取代码'
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
