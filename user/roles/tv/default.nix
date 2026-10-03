{pkgs, ...}: {
  imports = [
    ../../modules/kitty.nix
  ];

  # First-deploy version -- do not change after Home Manager has activated.
  home.stateVersion = "26.05";

  # Keep the full shared shell/editor profile from user/common.nix and add the
  # terminal-only tools used on Clancy. Avoid pulling the laptop GUI stack onto
  # the TV host.
  home.packages = with pkgs; [
    alejandra
    bat
    black
    codex
    eza
    fd
    hollywood
    htop
    kitty-themes
    nodejs
    pi-coding-agent
    prettier
    ripgrep
    sl
    speedtest-cli
    stylua
    tmux
    unrar
  ];
}
