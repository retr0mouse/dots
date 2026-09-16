{...}: {
  imports = [./common.nix];

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
}
