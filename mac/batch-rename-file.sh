#!/bin/bash
## Author: shunop
## Source: https://github.com/shunop/script
## Created: 2021-12-28
## Modified： 2021-12-28
## Version： v0.0.1
## Description: 批量修改文件名

cat tname.txt | while read line; do prefix=${line:0:3};find . -name "${prefix}*" | xargs -I {} mv {} $line;done

