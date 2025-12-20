#!/usr/bin/env bash

dir=~/.config/rofi/launchers/themes
theme="type-1-style-5"
mode="${1:-drun}"
# get from https://github.com/adi1090x/rofi

case "$mode" in
  drun|window) ;;
  *) mode="drun" ;;
esac

rofi -show "$mode" -modi "drun,window" -theme "${dir}/${theme}.rasi"
