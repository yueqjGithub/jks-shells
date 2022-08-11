#!/usr/bin/env bash
# 获取pom.xml配置的包名
# 第一个参数=pom.xml路径

pomPath=$1
if [[ $pomPath == "" ]]; then
    exit 1
fi

str=$(cat "${pomPath}")

matchResult=$(echo "${str}" | sed -rn 's/^.*<finalName>\s*([^<>]+)\s*<\/finalName>.*$/\1/p')
echo "$matchResult"
if [[ ${#matchResult[*]} == 1 ]]; then
    echo matchResult[0]
else
    exit 1
fi
