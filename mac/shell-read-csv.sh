#!/bin/bash

# 读取 CSV 文件并将其转换为数组
read_csv() {
  local csv_file="$1"
  local -n array_ref="$2"
  local delimiter=","
  local row_num=0

  # 逐行读取 CSV 文件
  while read line; do
    # 判断是否以 '#' 开头，如果是则跳过该行
    if [[ $line == \#* ]]; then
      continue
    fi

    # 分割行数据并将其存储到数组中
    IFS="$delimiter" read -ra fields <<< "$line"
    array_ref[row_num]="${fields[@]}"
    ((row_num++))
  done < "$csv_file"
}

# 测试读取 CSV 文件并输出数组
declare -a my_array
read_csv "shell-login.csv" my_array
for row in "${my_array[@]}"; do
  echo "$row"
done
