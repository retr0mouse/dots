{pkgs, ...}: let
  mkScript = name: pkgs.writeShellScriptBin name (builtins.readFile ../scripts/${name}.sh);
in {
  home.packages = [
    (mkScript "bluetooth_status")
  ];
}
