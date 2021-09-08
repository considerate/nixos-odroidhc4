final: prev: {
  linux_hardkernel = final.linux_latest.override {
    autoModules = false;
    # Configuration provided by elatllat
    # https://forum.odroid.com/viewtopic.php?f=176&t=33993&p=261833#p261833
    # I had to drop "DM_CRYPT y" because of repeated question error in
    # generate-config.pl I hope the default "CONFIG_DM_CRYPT=m" will work
    # fine for the HC4.
    structuredExtraConfig = with final.lib.kernel; {
      MDIO_BUS_MUX_MESON_G12A = yes;

      DM_CRYPT = module;

      BPF_SYSCALL = yes;
      CGROUP_BPF = yes;
      BPF_EVENTS = yes;
      BLK_DEV_DM = yes;
      FUSE_FS = yes;
      SQUASHFS_XZ = yes;
      PNFS_BLOCK = yes;
      CRYPTO_CBC = yes;
      CRYPTO_ECB = yes;
      CRYPTO_XTS = yes;
      CRYPTO_USER_API = yes;
      CRYPTO_USER_API_HASH = yes;
      CRYPTO_USER_API_SKCIPHER = yes;
      USB_UAS = yes;
      PWM_MESON = yes;

      BLK_DEV_MD = module;
      MD_AUTODETECT = module;
      MD_LINEAR = module;
      MD_RAID0 = module;
      MD_RAID1 = module;
      MD_RAID10 = module;
      MD_RAID456 = module;
      XOR_BLOCKS = module;
      ASYNC_CORE = module;
      ASYNC_MEMCPY = module;
      ASYNC_XOR = module;
      ASYNC_PQ = module;
      ASYNC_RAID6_RECOV = module;
      RAID6_PQ = module;
      LIBCRC32C = module;

      WIRELESS = no;
      WLAN = no;

      # Set HC4 platform (meson)
      ARCH_MESON = yes;

      # Disable all other platforms
      ARCH_ACTIONS = no;
      ARCH_AGILEX = no;
      ARCH_ALPINE = no;
      ARCH_APPLE = no;
      ARCH_BCM2835 = no;
      ARCH_BCM4908 = no;
      ARCH_BCM_IPROC = no;
      ARCH_BERLIN = no;
      ARCH_BRCMSTB = no;
      ARCH_EXYNOS = no;
      ARCH_HISI = no;
      ARCH_INTEL_SOCFPGA = no;
      ARCH_K3 = no;
      ARCH_KEEMBAY = no;
      ARCH_LAYERSCAPE = no;
      ARCH_LG1K = no;
      ARCH_MEDIATEK = no;
      ARCH_MVEBU = no;
      ARCH_MXC = no;
      ARCH_QCOM = no;
      ARCH_RENESAS = no;
      ARCH_ROCKCHIP = no;
      ARCH_S32 = no;
      ARCH_SEATTLE = no;
      ARCH_SPRD = no;
      ARCH_STRATIX10 = no;
      ARCH_SUNXI = no;
      ARCH_SYNQUACER = no;
      ARCH_TEGRA = no;
      ARCH_THUNDER = no;
      ARCH_THUNDER2 = no;
      ARCH_UNIPHIER = no;
      ARCH_VEXPRESS = no;
      ARCH_VISCONTI = no;
      ARCH_XGENE = no;
      ARCH_ZX = no;
      ARCH_ZYNQMP = no;
      # Disable NOUVEAU drivers
      DRM_NOUVEAU = no;
      NOUVEAU_LEGACY_CTX_SUPPORT = no;
      DRM_NOUVEAU_BACKLIGHT = no;
    };
  };
}
