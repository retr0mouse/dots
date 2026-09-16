{pkgs, ...}: {
  imports = [
    ./common.nix
  ];

  home.stateVersion = "25.11"; # First-deploy version — do not change.

  home.packages = with pkgs; [
    jdk25
    mcrcon
  ];
}
