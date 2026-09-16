{
  lib,
  pkgs,
  user,
  ...
}: {
  programs.virt-manager.enable = true;

  users.users.${user}.extraGroups = lib.mkAfter [
    "libvirtd"
    "kvm"
  ];

  virtualisation = {
    libvirtd = {
      enable = true;
      onBoot = "ignore";
      onShutdown = "shutdown";

      qemu = {
        package = pkgs.qemu_kvm;

        # Windows 11 TPM 2.0
        swtpm.enable = true;
      };
    };

    spiceUSBRedirection.enable = true;
  };

  services.supergfxd = {
    enable = true;

    settings = {
      vfio_enable = true;
      vfio_save = false;
    };
  };
}
