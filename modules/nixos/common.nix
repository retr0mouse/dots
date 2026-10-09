{
  pkgs,
  username,
  ...
}: {
  # Nix
  nix.settings.experimental-features = ["nix-command" "flakes"];
  nixpkgs.config.allowUnfree = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    # Keep enough history for a configuration to prove itself before its
    # rollback closure becomes eligible for collection.
    options = "--delete-older-than 14d";
  };

  boot.kernelParams = ["boot.shell_on_fail"];

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
  users.users.${username} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
    ];
  };

  programs.zsh.enable = true;

  # nix-ld
  programs.nix-ld.enable = true;
}
