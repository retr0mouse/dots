{
  pkgs,
  user,
  ...
}: {
  imports = [
    ./modules/git.nix
    ./modules/neovim
    ./modules/zsh.nix
  ];

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    packages = with pkgs; [
      btop
      fzf
      gh
      jq
      tree
      yazi
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

  programs.home-manager.enable = true;
}
