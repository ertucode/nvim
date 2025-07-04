#!/bin/bash

# chmod +x ./scripts/restart_wifi.sh
#
# sudo visudo
# cavitertugrulsirt ALL=(ALL) NOPASSWD: /Users/cavitertugrulsirt/.config/nvim/scripts/restart_wifi.sh

ifconfig en0 down
ifconfig en0 up
