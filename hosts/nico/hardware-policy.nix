{pkgs, ...}: let
  msiklm = pkgs.stdenv.mkDerivation {
    pname = "msiklm";
    version = "unstable-2023-03-14";

    src = pkgs.fetchFromGitHub {
      owner = "Gibtnix";
      repo = "MSIKLM";
      rev = "e9a75942d85612869e32f14d4ec0e6ad5b4514ed";
      hash = "sha256-NHTFYKrPA6V5yOatI+DanMS76kBTuAcZPxXlBffgB/k=";
    };

    buildInputs = [pkgs.hidapi];

    installPhase = ''
      runHook preInstall
      install -Dm755 msiklm "$out/bin/msiklm"
      runHook postInstall
    '';

    meta = {
      description = "MSI SteelSeries keyboard light manager";
      homepage = "https://github.com/Gibtnix/MSIKLM";
      license = pkgs.lib.licenses.gpl3Only;
      platforms = pkgs.lib.platforms.linux;
    };
  };

  keyboardBacklightOff = pkgs.writeShellScript "keyboard-backlight-off" ''
    ${msiklm}/bin/msiklm off
    ${msiklm}/bin/msiklm off off
  '';
in {
  # This MSI laptop is an always-on server and must stay awake with its lid shut.
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };

  # Keep all three zones of the built-in SteelSeries keyboard dark after boot
  # and when switching configurations. The generic LED-class interface binds
  # to this USB ID but does not control this model. Do not invoke this from a
  # udev add rule: hidapi temporarily reattaches the HID interface, which would
  # recursively trigger the rule.
  systemd.services.keyboard-backlight-off = {
    description = "Disable the built-in keyboard lighting";
    wantedBy = ["multi-user.target"];
    after = ["systemd-udev-settle.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = keyboardBacklightOff;
    };
  };

  systemd.sleep.settings.Sleep = {
    AllowSuspend = "no";
    AllowHibernation = "no";
    AllowHybridSleep = "no";
  };
}
