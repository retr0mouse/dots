{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      config = "cd ~/dots && tree";
      rebuild = "sudo nixos-rebuild switch --flake ~/dots#$(hostname)";
      logthefuckout = "loginctl terminate-user $USER";
    };
    oh-my-zsh = {
      enable = true;
      plugins = ["git"];
      theme = "dst";
    };
  };
}
