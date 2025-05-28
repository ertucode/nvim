#!/usr/bin/env bash

output=$("./CheckModKeys" capslock)

if [ "$output" = "1" ]; then
  echo "■"
else
  echo "□"
fi
