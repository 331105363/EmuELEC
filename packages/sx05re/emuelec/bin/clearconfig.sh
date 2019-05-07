#!/bin/sh

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

case $1 in
"EMUS")
systemctl stop emustation
rm -rf /storage/.config/emulationstation/es_settings.cfg
rm -rf /storage/.config/emulationstation/es_systems.cfg
rm -rf /storage/.config/emulationstation/scripts/*
rm -rf /emuelec/*
rm -rf /storage/.local*
rm -rf /storage/.config/ppsspp*
rm -rf /storage/.config/reicast*
rm -rf /storage/.config/retroarch*
rm -rf /storage/.advance*
sync
systemctl reboot
  ;;
"ALL")
systemctl stop emustation
rm -rf /storage/.*
rm -rf /storage/*
sync
systemctl reboot
  ;;
esac
