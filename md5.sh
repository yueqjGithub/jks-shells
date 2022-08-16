#!/usr/bin/env bash
# 对字符串进行md5签名
# 第一个参数=要签名的字符串

value=$1
echo -n "${value}" | md5sum | cut -d ' ' -f1
