{
  config,
  inputs,
  pkgs,
  username,
  ...
}: let
  looking-glass-client-dev = pkgs.looking-glass-client.overrideAttrs (old: {
    version = "B7-826-236efcb1";

    src = inputs.looking-glass-src;

    # The stable B7 package carries a patch specific to its source.
    patches = [];

    # The flake input is unpacked as ./source.
    sourceRoot = "source/client";

    # No .git directory exists in the Nix build sandbox, so explicitly
    # provide the version Looking Glass should report.
    postUnpack = ''
      chmod -R u+w source
      echo "B7-826-236efcb1" > source/VERSION
      export sourceRoot="source/client"
    '';

    buildInputs =
      old.buildInputs
      ++ (with pkgs; [
        fuse3
        libunwind
        elfutils
        zstd
        libxcb
      ]);

    # Development source includes fuse3/fuse_lowlevel.h, while fuse's
    # pkg-config include path alone isn't sufficient for that include.
    NIX_CFLAGS_COMPILE =
      (old.NIX_CFLAGS_COMPILE or "")
      + " -I${pkgs.fuse3.dev}/include";

    # Current CMake installs its own SVG/desktop resources, so don't use
    # the old B7 postInstall that manually copies the PNG.
    postInstall = "";
  });

  start-vm = pkgs.writeShellApplication {
    name = "start-vm";
    runtimeInputs = [
      looking-glass-client-dev
      pkgs.libvirt
      pkgs.lsof
    ];
    text = builtins.readFile ./start-vm.sh;
  };
in {
  environment.systemPackages = [start-vm];

  # Make the exact same client package available to the Clancy Home Manager
  # layer, which owns the per-user Looking Glass configuration.
  home-manager.extraSpecialArgs.lookingGlassPackage = looking-glass-client-dev;

  boot.extraModulePackages = [config.boot.kernelPackages.kvmfr];
  boot.kernelModules = ["kvmfr"];
  boot.extraModprobeConfig = ''
    options kvmfr static_size_mb=128
  '';

  services.udev.extraRules = ''
    SUBSYSTEM=="kvmfr", OWNER="${username}", GROUP="kvm", MODE="0660"
  '';

  virtualisation.libvirtd.qemu.verbatimConfig = ''
    namespaces = []

    cgroup_device_acl = [
      "/dev/null", "/dev/full", "/dev/zero",
      "/dev/random", "/dev/urandom",
      "/dev/ptmx", "/dev/userfaultfd",
      "/dev/kvm", "/dev/kqemu",
      "/dev/rtc", "/dev/hpet",
      "/dev/vfio/vfio",
      "/dev/kvmfr0"
    ]
  '';
}
