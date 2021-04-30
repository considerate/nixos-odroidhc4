#! @bash@/bin/sh -e

shopt -s nullglob

export PATH=/empty
for i in @path@; do PATH=$PATH:$i/bin; done

usage() {
  echo "usage: $0 -c <path-to-default-configuration> -n <dtb file> [-d <boot-dir>]" >&2
  exit 1
}

config=''        # Default configuration
target=/boot     # Target directory
dtbname=''       # Devicetree name

while getopts "t:c:d:g:n:" opt; do
  case "$opt" in
    c) config="$OPTARG" ;;
    d) target="$OPTARG" ;;
    n) dtbname="$OPTARG" ;;
    \?) usage ;;
  esac
done

[ -e "$config" -a -d "$target" -a -n "$dtbname" ] || usage

resolve () { readlink -v -e "$1" || exit 2; }
kernel=$(resolve $config/kernel)
dtb=$(resolve $config/dtbs/$dtbname)
initrd=$(resolve $config/initrd.uboot)
syscfg=$(resolve $config)
init=$(resolve $config/init)

bootscr="$target/boot.scr"
tmpini="$bootscr.tmp1.$$"
tmpscr="$bootscr.tmp2.$$"

cat >$tmpini <<EOF
# Generated file, all changes will be lost on nixos-rebuild!

# expect to be set by u-boot:
# devtype, devnum, distro_bootpart, kernel_addr_r, fdt_addr_r, ramdisk_addr_r

load \${devtype} \${devnum}:\${distro_bootpart} \${kernel_addr_r} $kernel
load \${devtype} \${devnum}:\${distro_bootpart} \${fdt_addr_r} $dtb
fdt addr \${fdt_addr_r}
load \${devtype} \${devnum}:\${distro_bootpart} \${ramdisk_addr_r} $initrd

setenv bootargs "root=/dev/mmcblk0p\${distro_bootpart} rootwait rw systemConfig=$syscfg init=$init"

booti \${kernel_addr_r} \${ramdisk_addr_r} \${fdt_addr_r}
EOF

mkimage -A arm64 -O linux -T script -C none -d $tmpini $tmpscr
mv -f $tmpscr $bootscr
rm -f $tmpini
