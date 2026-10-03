{
  inputs,
  lib,
  ...
}: let
  raspberryPi = inputs.nixos-raspberrypi;
  # This is the kernel/firmware pair published and cached by the pinned
  # nixos-raspberrypi release. Keep the pair together when changing versions.
  rpiBundle =
    raspberryPi.legacyPackages.aarch64-linux.linuxAndFirmware.v6_18_34;
  addKernelMetadata = kernel:
    kernel
    // {
      buildDTBs = true;
      target = "Image";
      # Preserve the compatibility metadata when the NixOS kernel module calls
      # override to apply its (empty here) kernel patch/feature configuration.
      override = arguments: addKernelMetadata (kernel.override arguments);
    };
  kernelPackages = rpiBundle.linuxPackages_rpi5.extend (_final: previous: {
    kernel = addKernelMetadata previous.kernel;
  });
in {
  imports = [
    raspberryPi.lib.inject-overlays
    raspberryPi.nixosModules.trusted-nix-caches
    raspberryPi.nixosModules.raspberry-pi-5.base
    raspberryPi.nixosModules.raspberry-pi-5.display-vc4
    raspberryPi.nixosModules.raspberry-pi-5.bluetooth
    raspberryPi.nixosModules.sd-image
  ];

  # Use the matched Raspberry Pi kernel, DTBs and firmware rather than mixing
  # the generic NixOS kernel with downstream-only Pi device-tree overlays.
  boot.kernelPackages = kernelPackages;
  # The installer base profile enables ZFS opportunistically. This image uses
  # ext4, and mixing ZFS tooling from unstable with a 26.05 kernel module set
  # is both unnecessary and explicitly unsupported.
  boot.supportedFilesystems.zfs = lib.mkForce false;
  boot.loader.raspberry-pi = {
    bootloader = "kernel";
    firmwarePackage = rpiBundle.raspberrypifw;

    # The image reserves 1 GiB for firmware. Two complete boot generations are
    # enough during testing and leave comfortable room for kernels/initrds.
    configurationLimit = 2;
  };

  hardware = {
    # The 26.11 device-tree module cannot infer this flag from a kernel built
    # by the pinned 26.05 package set, although that kernel ships its DTBs.
    deviceTree.enable = true;
    firmware = [
      rpiBundle.raspberrypiWirelessFirmware
    ];
  };

  image.baseName = lib.mkForce "nixos-tv-rpi5";

  # First-deploy version -- do not change after installation.
  system.stateVersion = "26.05";
}
