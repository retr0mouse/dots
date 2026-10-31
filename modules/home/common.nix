{
  pkgs,
  username,
  ...
}: {
  imports = [
    ./git.nix
    ./neovim
    ./terminal-tools
    ./zsh.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    packages = with pkgs; [
      gh
      jq
      tree
    ];
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings."*" = {
      AddKeysToAgent = "yes";
      Compression = true;
      ServerAliveInterval = 60;
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.tmux = {
    enable = true;
    keyMode = "vi";
    extraConfig = ''
      # Visual selection
      bind -T copy-mode-vi v send -X begin-selection
      bind -T copy-mode-vi V send -X select-line
      bind -T copy-mode-vi C-v send -X rectangle-toggle

      # Yank
      bind -T copy-mode-vi y send -X copy-selection-and-cancel

      # Escape cancels selection
      bind -T copy-mode-vi Escape send -X clear-selection

      # Vim-style scrolling
      bind -T copy-mode-vi C-u send -X halfpage-up
      bind -T copy-mode-vi C-d send -X halfpage-down

      # System clipboard
      set -g set-clipboard on
    '';
  };

  programs.home-manager.enable = true;
}
