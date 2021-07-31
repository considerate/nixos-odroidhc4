final: prev: {
  linux_hardkernel = final.linux.override {
    # Configuration provided by elatllat
    # https://forum.odroid.com/viewtopic.php?f=176&t=33993&p=261833#p261833
    # I had to drop "DM_CRYPT y" because of repeated question error in
    # generate-config.pl I hope the default "CONFIG_DM_CRYPT=m" will work
    # fine for the HC4.
    extraConfig = ''
      MDIO_BUS_MUX_MESON_G12A y
      ARCH_MESON y

      BPF_SYSCALL y
      CGROUP_BPF y
      BPF_EVENTS y
      SQUASHFS_XZ y
      BLK_DEV_DM y
      FUSE_FS y
      SQUASHFS_XZ y
      PNFS_BLOCK y
      CRYPTO_CBC y
      CRYPTO_ECB y
      CRYPTO_XTS y
      CRYPTO_USER_API y
      CRYPTO_USER_API_HASH y
      CRYPTO_USER_API_SKCIPHER y
      USB_UAS y
      PWM_MESON y

      BLK_DEV_MD m
      MD_AUTODETECT m
      MD_LINEAR m
      MD_RAID0 m
      MD_RAID1 m
      MD_RAID10 m
      MD_RAID456 m
      XOR_BLOCKS m
      ASYNC_CORE m
      ASYNC_MEMCPY m
      ASYNC_XOR m
      ASYNC_PQ m
      ASYNC_RAID6_RECOV m
      RAID6_PQ m
      LIBCRC32C m

      WIRELESS n
      WLAN n
    '';
  };
}
