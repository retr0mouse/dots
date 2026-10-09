{pkgs, ...}: {
  home.stateVersion = "25.11"; # First-deploy version — do not change.

  programs.btop.package = pkgs.btop.override {
    cudaSupport = true;
  };

  home.packages = with pkgs; [
    jdk25
    mcrcon
  ];
}
