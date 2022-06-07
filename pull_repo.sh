#!/usr/bin/env bash

# 拉取仓库代码
function pull_repo(){
    if [[ $1 == '' ]]; then
        echo '未设置仓库地址'
        exit 1
    fi
}