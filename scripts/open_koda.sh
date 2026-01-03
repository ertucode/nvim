#!/bin/bash

home_dir=$(eval echo "~")
app_path="${home_dir}/dev/koda/dist/mac-arm64/Koda.app"

first_arg_path=$1

if [[ -n "$first_arg_path" ]]; then
    open -a "${app_path}" --args --initial-path="${first_arg_path}"
    exit 0
fi

open -a "${app_path}"
