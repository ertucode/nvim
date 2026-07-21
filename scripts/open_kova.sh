#!/bin/bash

home_dir=$(eval echo "~")
app_path="${home_dir}/dev/kova/dist/mac-arm64/Kova.app"

open -a "${app_path}"
