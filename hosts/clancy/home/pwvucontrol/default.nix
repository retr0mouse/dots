{pkgs, ...}: let
  styledPwvucontrol = pkgs.pwvucontrol.overrideAttrs (old: {
    postPatch =
      (old.postPatch or "")
      + ''
        cat ${./style.css} >> data/resources/ui/style.css

        substituteInPlace src/ui/peakmeter.rs \
          --replace-fail '0x33d17a' '0x98a87c' \
          --replace-fail '0xf6d32d' '0xc6a96b' \
          --replace-fail '0xe01b24' '0xd08770' \
          --replace-fail 'from_rect(bounding_box, 5.0)' 'from_rect(bounding_box, 0.0)'
      '';
  });
in {
  # This stylesheet is compiled into pwvucontrol itself. No global GTK or Qt
  # settings are changed.
  home.packages = [styledPwvucontrol];
}
