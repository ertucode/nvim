#!/bin/bash

home_dir=$(eval echo "~")
app_path="${home_dir}/dev/kopa/dist/mac-arm64/Kopa.app"

open -a "${app_path}"
