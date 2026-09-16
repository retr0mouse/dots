{
  pkgs,
  user,
  ...
}: {
  # Nix
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.allowUnfree = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 3d";
  };

  # Boot
  boot = {
    loader.systemd-boot.enable = true;
    loader.timeout = 1;

    kernelParams = [
      "boot.shell_on_fail"
    ];
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # Time / Locale
  time.timeZone = "Europe/Tallinn";

  i18n.defaultLocale = "en_CA.UTF-8";
  i18n.extraLocaleSettings.LC_TIME = "en_GB.UTF-8";

  # Core services
  services = {
    dbus.enable = true;
    fstrim.enable = true;
    timesyncd.enable = true;
  };

  # User
  users.users.${user} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
    ];
  };

  programs.zsh.enable = true;

  # Docker

  # nix-ld
  programs.nix-ld.enable = true;

  environment.systemPackages = [];
}
