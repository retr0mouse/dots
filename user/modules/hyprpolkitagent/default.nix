{pkgs, ...}: let
  styledHyprpolkitagent = pkgs.hyprpolkitagent.overrideAttrs (old: {
    postPatch =
      (old.postPatch or "")
      + ''
        cp ${./main.qml} qml/main.qml
      '';
  });
in {
  # hyprpolkitagent does not expose a theme file, so keep the customization
  # local to its compiled QML instead of changing the theme of every Qt app.
  services.hyprpolkitagent = {
    enable = true;
    package = styledHyprpolkitagent;
  };
}
