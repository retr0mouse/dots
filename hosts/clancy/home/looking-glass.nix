{
  programs.looking-glass-client = {
    enable = true;

    settings = {
      lgmp.shmDevice = "/dev/kvmfr0";

      win = {
        # JIT presentation pacing causes periodic frame drops under Hyprland.
        jitRender = false;
        showFPS = true;
      };

      input = {
        # Games need relative input so the pointer cannot hit a host edge.
        rawMouse = true;
        captureOnFocus = true;
        escapeKey = "KEY_F12";
      };
    };
  };
}
