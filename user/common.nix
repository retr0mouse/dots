{
  pkgs,
  username,
  ...
}: {
  imports = [
    ./modules/git.nix
    ./modules/neovim
    ./modules/terminal-tools
    ./modules/zsh.nix
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

  programs.home-manager.enable = true;
}
