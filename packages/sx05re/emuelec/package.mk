# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="emuelec"
PKG_VERSION=""
PKG_REV="2"
PKG_ARCH="any"
PKG_LICENSE="GPLv3"
PKG_SITE=""
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain $OPENGLES emuelec-emulationstation retroarch"
PKG_SECTION="emuelec"
PKG_SHORTDESC="EmuELEC Meta Package"
PKG_LONGDESC="EmuELEC Meta Package"
PKG_IS_ADDON="no"
PKG_AUTORECONF="no"
PKG_TOOLCHAIN="make"
PKG_NEED_UNPACK="$(get_pkg_directory busybox)"

PKG_EXPERIMENTAL="munt nestopiaCV quasi88 xmil np2kai hypseus-singe yabasanshiroSA fbneoSA"
PKG_EMUS="$LIBRETRO_CORES advancemame PPSSPPSDL amiberry hatarisa openbor dosbox-staging mupen64plus-nx mupen64plus-nx-alt scummvmsa stellasa solarus dosbox-pure pcsx_rearmed ecwolf potator freej2me duckstation flycastsa fmsx-libretro jzintv mupen64plussa"
PKG_TOOLS="emuelec-tools"
PKG_DEPENDS_TARGET+=" $PKG_TOOLS $PKG_EMUS $PKG_EXPERIMENTAL emuelec-ports"

# Removed cores for space and/or performance
# PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET mame2015 fba4arm mba.mini.plus $LIBRETRO_EXTRA_CORES xow"

# These packages are only meant for S922x, S905x2 and A311D devices as they run poorly on S905" 
if [ "${DEVICE}" == "Amlogic-ng" ] || [ "$DEVICE" == "RK356x" ] || [ "$DEVICE" == "OdroidM1" ]; then
PKG_DEPENDS_TARGET+=" $LIBRETRO_S922X_CORES mame2016"
fi

if [ "$DEVICE" == "OdroidGoAdvance" ] || [ "$DEVICE" == "GameForce" ]; then
    PKG_DEPENDS_TARGET+=" kmscon odroidgoa-utils"
    
    #we disable some cores that are not working or work poorly on OGA
    for discore in duckstation mesen-s virtualjaguar quicknes MC; do
         PKG_DEPENDS_TARGET=$(echo $PKG_DEPENDS_TARGET | sed "s|$discore | |")
    done
    PKG_DEPENDS_TARGET+=" yabasanshiro"
else
    PKG_DEPENDS_TARGET+=" fbterm"
fi

# These cores do not work, or are not needed on aarch64, this package needs cleanup :) 
if [ "$ARCH" == "aarch64" ]; then
for discore in munt_neon quicknes parallel-n64 pcsx_rearmed; do
		PKG_DEPENDS_TARGET=$(echo $PKG_DEPENDS_TARGET | sed "s|$discore| |")
	done
	
PKG_DEPENDS_TARGET+=" swanstation emuelec-32bit-libs"

if [ "${DEVICE}" == "Amlogic-ng" ] || [ "$DEVICE" == "RK356x" ] || [ "$DEVICE" == "OdroidM1" ]; then
	PKG_DEPENDS_TARGET+=" dolphinSA"
fi

fi

make_target() {
if [ "${DEVICE}" == "Amlogic-ng" ]; then
    cp -r $PKG_DIR/fbfix* $PKG_BUILD/
    cd $PKG_BUILD/fbfix
    $CC -O2 fbfix.c -o fbfix
fi
}


makeinstall_target() {
   
	mkdir -p $INSTALL/usr/bin
	cp -rf $PKG_DIR/bin $INSTALL/usr

    if [ "${DEVICE}" == "Amlogic-ng" ]; then
    	cp $PKG_BUILD/fbfix/fbfix $INSTALL/usr/bin
    fi
	
	mkdir -p $INSTALL/usr/config/
    cp -rf $PKG_DIR/config/* $INSTALL/usr/config/
    ln -sf /storage/.config/emuelec $INSTALL/emuelec
    
    # Added for compatibility with portmaster
    ln -sf /storage/roms $INSTALL/roms
    ln -sf /storage/roms/ports/portmaster $INSTALL/portmaster
    
    find $INSTALL/usr/config/emuelec/ -type f -exec chmod o+x {} \;
    
	mkdir -p $INSTALL/usr/config/emuelec/logs
	ln -sf /var/log $INSTALL/usr/config/emuelec/logs/var-log
    
  # leave for compatibility
  if [ "${DEVICE}" == "Amlogic" ]; then
      echo "s905" > $INSTALL/ee_s905
  fi
  
  
  echo "$DEVICE" > $INSTALL/ee_arch
  
  mkdir -p $INSTALL/usr/share/retroarch-overlays
    cp -r $PKG_DIR/overlay/* $INSTALL/usr/share/retroarch-overlays
  
  mkdir -p $INSTALL/usr/share/common-shaders
    cp -r $PKG_DIR/shaders/* $INSTALL/usr/share/common-shaders
    
  mkdir -p $INSTALL/usr/share/libretro-database
     touch $INSTALL/usr/share/libretro-database/dummy
   
   # Make sure all scripts and binaries are executable  
   find $INSTALL/usr/bin -type f -exec chmod +x {} \;
}

post_install() {
  for i in borders effects gamepads ipad keyboards misc; do
    rm -rf "$INSTALL/usr/share/retroarch-overlays/$i"
  done

mkdir -p $INSTALL/etc/retroarch-joypad-autoconfig
cp -r $PKG_DIR/gamepads/* $INSTALL/etc/retroarch-joypad-autoconfig

# link default.target to emuelec.target
   ln -sf emuelec.target $INSTALL/usr/lib/systemd/system/default.target
   enable_service emuelec-autostart.service
   enable_service emuelec-disable_small_cores.service
  
# Thanks to vpeter we can now have bash :) 
  rm -f $INSTALL/usr/bin/{sh,bash,busybox,sort,wget}
  cp $(get_install_dir busybox)/usr/bin/busybox $INSTALL/usr/bin
  cp $(get_install_dir bash)/usr/bin/bash $INSTALL/usr/bin
  cp $(get_install_dir wget)/usr/bin/wget $INSTALL/usr/bin
  cp $(get_install_dir coreutils)/usr/bin/sort $INSTALL/usr/bin
  ln -sf bash $INSTALL/usr/bin/sh
 
  echo "chmod 4755 $INSTALL/usr/bin/bash" >> $FAKEROOT_SCRIPT
  echo "chmod 4755 $INSTALL/usr/bin/busybox" >> $FAKEROOT_SCRIPT
  find $INSTALL/usr/ -type f -iname "*.sh" -exec chmod +x {} \;
  
# Remove scripts from OdroidGoAdvance build
if [[ ${DEVICE} == "OdroidGoAdvance" || "${DEVICE}" == "GameForce" ]]; then 
  for i in "wifi" "sselphs_scraper" "skyscraper" "system_info"; do 
  xmlstarlet ed -L -P -d "/gameList/game[name='${i}']" $INSTALL/usr/bin/scripts/setup/gamelist.xml
  rm "$INSTALL/usr/bin/scripts/setup/${i}.sh"
  done
fi 

#For automatic updates we use the buildate
	date +"%m%d%Y" > $INSTALL/usr/buildate
} 
