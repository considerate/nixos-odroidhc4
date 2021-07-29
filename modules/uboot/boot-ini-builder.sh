#! @bash@/bin/sh -e

shopt -s nullglob

export PATH=/empty
for i in @path@; do PATH=$PATH:$i/bin; done

usage() {
  echo "usage: $0 -t <timeout> -c <path-to-default-configuration> [-d <boot-dir>] [-g <num-generations>] [-n <dtbName>]" >&2
  exit 1
}

timeout=         # Timeout in centiseconds
default=         # Default configuration
target=/boot     # Target directory
numGenerations=0 # Number of other generations to include in the menu

while getopts "t:c:d:g:n:" opt; do
  case "$opt" in
  t) # U-Boot interprets '0' as infinite and negative as instant boot
    if [ "$OPTARG" -lt 0 ]; then
      timeout=0
    elif [ "$OPTARG" = 0 ]; then
      timeout=-10
    else
      timeout=$((OPTARG * 10))
    fi
    ;;
  c) default="$OPTARG" ;;
  d) target="$OPTARG" ;;
  g) numGenerations="$OPTARG" ;;
  n) dtbName="$OPTARG" ;;
  \?) usage ;;
  esac
done

[ "$timeout" = "" -o "$default" = "" ] && usage

mkdir -p $target/nixos

# Convert a path to a file in the Nix store such as
# /nix/store/<hash>-<name>/file to <hash>-<name>-<file>.
cleanName() {
  local path="$1"
  echo "$path" | sed 's|^/nix/store/||' | sed 's|/|-|g'
}

# Copy a file from the Nix store to $target/nixos.
declare -A filesCopied

copyToKernelsDir() {
  local src=$(readlink -f "$1")
  local dst="$target/nixos/$(cleanName $src)"
  # Don't copy the file if $dst already exists.  This means that we
  # have to create $dst atomically to prevent partially copied
  # kernels or initrd if this script is ever interrupted.
  if ! test -e $dst; then
    local dstTmp=$dst.tmp.$$
    cp -r $src $dstTmp
    mv $dstTmp $dst
  fi
  filesCopied[$dst]=1
  result=$dst
}

copyInitrd() {
  local src=$(readlink -f "$1")
  local dst="$target/nixos/$(cleanName $src)"
  if ! test -e $dst; then
    local initrd=$dst.initrd.tmp.$$
    local dstTmp=$dst.tmp.$$
    # Unzip and convert ramdisk to uInitrd format (u-boot initrd)
    gzip -d <"$path/initrd" >$initrd
    mkimage -A arm64 -O linux -T ramdisk -C none -d "$initrd" "$dstTmp" >/dev/null
    rm $initrd
    mv $dstTmp $dst
  fi
  filesCopied[$dst]=1
  result=$dst
}

# Copy its kernel, initrd and dtbs to $target/nixos, and echo out boot.ini entry
addEntry() {
  local path=$(readlink -f "$1")
  local tag="$2" # Generation number or 'default'

  if ! test -e $path/kernel -a -e $path/initrd; then
    return
  fi

  copyToKernelsDir "$path/kernel"
  kernel=$result
  copyInitrd "$path/initrd"
  initrd=$result
  dtbDir=$(readlink -m "$path/dtbs")
  if [ -e "$dtbDir" ]; then
    copyToKernelsDir "$dtbDir"
    dtbs=$result
  fi

  echo "load mmc \${devno}:1 \${k_addr} nixos/$(basename $kernel)"
  echo "load mmc \${devno}:1 \${dtb_loadaddr} nixos/$(basename $dtbs)/amlogic/meson64_odroid\${variant}.dtb"
  echo "fdt addr \${dtb_loadaddr}"
  echo "load mmc \${devno}:1 \${initrd_loadaddr} nixos/$(basename $initrd)"
  echo "setenv bootargs \"\${bootargs} \""
  echo "# Boot Args"
  echo "setenv bootargs \"root=root=/dev/mmcblk\${devno}p2  rootwait rw \${condev} \${amlogic} no_console_suspend fsck.repair=yes net.ifnames=0 elevator=noop hdmimode=\${hdmimode} cvbsmode=576cvbs max_freq_a55=\${max_freq_a55} maxcpus=\${maxcpus} voutmode=\${voutmode} \${cmode} disablehpd=\${disablehpd} cvbscable=\${cvbscable} overscan=\${overscan} \${hid_quirks} monitor_onoff=\${monitor_onoff} logo=osd0,loaded \${cec_enable} sdrmode=\${sdrmode} enable_wol=\${enable_wol} systemConfig=$path init=$path/init\""
}

tmpFile="$target/boot.ini.tmp.$$"

# This configuration was adapted from the Ubuntu 20.04 image provided
# on the Hardkernel Wiki.
cat >$tmpFile <<EOF
ODROIDC4-UBOOT-CONFIG
# Generated file, all changes will be lost on nixos-rebuild!

setenv bootlabel "Hardkernel NixOS 21.05"

setenv board "odroidc4"
setenv display_autodetect "true"
setenv hdmimode "1080p60hz"
setenv monitor_onoff "false" # true or false
setenv overscan "100"
setenv sdrmode "auto"
setenv voutmode "hdmi"
setenv disablehpd "false"
setenv cec "true"
setenv disable_vu7 "true"
setenv max_freq_a55 "1908"    # 1.908 GHz, default value
setenv maxcpus "4"
setenv enable_wol "0"

# Set load addresses
setenv dtb_loadaddr "0x10000000"
setenv dtbo_addr_r "0x11000000"
setenv k_addr "0x1100000"
setenv loadaddr "0x1B00000"
setenv initrd_loadaddr "0x00000000"

if test "\${variant}" = "hc4"; then
   setenv max_freq_a55 "1800"
fi

load mmc \${devno}:1 \${loadaddr} config.ini \
  && ini generic \${loadaddr}
if test "x\${overlay_profile}" != "x"; then
  ini overlay_\${overlay_profile} \${loadaddr}
fi

setenv condev "console=ttyS0,115200n8"   # on both

### Normal HDMI Monitors
if test "\${display_autodetect}" = "true"; then hdmitx edid; fi
if test "\${hdmimode}" = "custombuilt"; then setenv cmode "modeline=\${modeline}"; fi
if test "\${cec}" = "true"; then setenv cec_enable "hdmitx=cec3f"; fi
if test "\${disable_vu7}" = "false"; then setenv hid_quirks "usbhid.quirks=0x0eef:0x0005:0x0004"; fi

EOF

# The boot.ini file format only supports a single entry
# as far as I can tell.
addEntry $default default >>$tmpFile

cat >>$tmpFile <<EOF
if test "x{overlays}" != "x"; then
  fdt resize \${overlay_resize}
  for overlay in \${overlays}; do
  load mmc \${devno}:1 \${dtbo_addr_r} amlogic/overlays/\${board}/\${overlay}.dtbo \
      && fdt apply \${dtbo_addr_r}
  done
fi

# unzip the kernel
unzip \${k_addr} \${loadaddr}
# boot
booti \${loadaddr} \${initrd_loadaddr} \${dtb_loadaddr}
EOF

mv -f $tmpFile $target/boot.ini
cp -f @configIni@ $target/config.ini
# Remove obsolete files from $target/nixos.
for fn in $target/nixos/*; do
  if ! test "${filesCopied[$fn]}" = 1; then
    echo "Removing no longer needed boot file: $fn"
    chmod +w -- "$fn"
    rm -rf -- "$fn"
  fi
done
