#!/usr/bin/env bash
# 获取pom.xml配置的包名
# 第一个参数=pom.xml路径

pomPath=$1
if [[ $1 == "" ]]; then
    exit 1
fi
matchResult=$(echo "${str}" | sed -r 's/^.*<finalName>\s*([^<>]+)\s*<\/finalName>.*$/\1/p')
if [[ ${#matchResult[*]} == 2 ]]; then
    echo matchResult[1]
else
    exit 1
fi
exit 0
