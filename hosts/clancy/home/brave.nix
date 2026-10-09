{pkgs, ...}: {
  programs.chromium = {
    package = pkgs.brave;
    enable = true;
    commandLineArgs = [
      "--password-store=basic"
    ];
    extensions = [
      {id = "mnjggcdmjocbbbhaepdhchncahnbgone";} # SponsorBlock
      {id = "enboaomnljigfhfjfoalacienlhjlfil";} # UnTrap
      {id = "hkgfoiooedgoejojocmhlaklaeopbecg";} # Picture-in-Picture
      {id = "nngceckbapebfimnlniiiahkandclblb";} # Bitwarden Password Manager
    ];
  };
}
