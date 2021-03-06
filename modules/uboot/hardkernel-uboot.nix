{ config, lib, pkgs, ... }:

with lib;
let
  blCfg = config.boot.loader;
  dtCfg = config.hardware.deviceTree;
  cfg = blCfg.hardkernel-uboot;

  timeoutStr = if blCfg.timeout == null then "-1" else toString blCfg.timeout;

  # The builder used to write during system activation
  builder = import ./boot-ini-builder.nix { inherit pkgs; };
  # The builder exposed in populateCmd, which runs on the build architecture
  populateBuilder = import ./boot-ini-builder.nix { pkgs = pkgs.buildPackages; };
in
{
  options = {
    boot.loader.hardkernel-uboot = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Whether to generate an extlinux-compatible configuration file
          under <literal>/boot/extlinux.conf</literal>.  For instance,
          U-Boot's generic distro boot support uses this file format.
          See <link xlink:href="http://git.denx.de/?p=u-boot.git;a=blob;f=doc/README.distro;hb=refs/heads/master">U-boot's documentation</link>
          for more information.
        '';
      };

      populateCmd = mkOption {
        type = types.str;
        readOnly = true;
        description = ''
          Contains the builder command used to populate an image,
          honoring all options except the <literal>-c &lt;path-to-default-configuration&gt;</literal>
          argument.
          Useful to have for sdImage.populateRootCommands
        '';
      };

    };
  };

  config =
    let
      builderArgs = "-t ${timeoutStr}" + lib.optionalString (dtCfg.name != null) " -n ${dtCfg.name}";
    in
    mkIf cfg.enable {
      system.build.installBootLoader = "${builder} ${builderArgs} -c";
      system.boot.loader.id = "hardkernel-uboot";
      boot.loader.hardkernel-uboot.populateCmd = "${populateBuilder} ${builderArgs}";
    };
}
