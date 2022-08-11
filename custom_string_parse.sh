#!/usr/bin/env bash
# 解析指定格式字符串source(propId1:propValue1，propId2:propValue2)
# 第一个参数=字符串
# 第二个参数如果不传，返回source；如果传了表示propId，返回对应的propId

str=$1
propId=$2
if [[ $str == "" ]]; then
    exit 1
fi

if [[ $propId == "" ]]; then
    echo "${str}" | sed -r 's/\(.+\)//g'
    exit 0
fi

matchResult=$(echo "${str}" | sed -rn "s/^.*${propsId}:([^，()]+).*$/\1/p")
if [[ ${#matchResult[*]} == 1 ]]; then
    echo "${matchResult[0]}"
else
    echo ""
fi
exit 0
