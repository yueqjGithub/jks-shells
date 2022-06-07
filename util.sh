#!/usr/bin/env bash

# 拉取仓库代码
function avalon_web_cd::pull_repo(){
    if [[ $1 == '' ]]; then
        echo '未设置仓库地址'
        exit 1
    fi
}