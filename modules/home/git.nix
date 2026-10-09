{
  programs.git = {
    enable = true;
    settings = {
      user.name = "retr0mouse";
      user.email = "daniil.sharin667@gmail.com";
      init.defaultBranch = "main";
    };
  };
  programs.delta = {
    enable = true;
    options = {
      side-by-side = true;
      line-numbers = true;
    };
  };
}
