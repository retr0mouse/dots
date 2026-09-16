{
  programs.looking-glass-client = {
    enable = true;

    settings = {
      app.shmFile = "/dev/kvmfr0";

      win = {
        jitRender = true;
        showFPS = true;
      };
    };
  };
}
