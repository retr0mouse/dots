{pkgs, ...}: {
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  services.journald.extraConfig = ''
    SystemMaxUse=500M
  '';

  # Keep Kitty-compatible terminfo available for remote administration.
  environment.systemPackages = [pkgs.kitty.terminfo];
}
