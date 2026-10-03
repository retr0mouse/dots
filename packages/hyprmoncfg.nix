{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation rec {
  pname = "hyprmoncfg";
  version = "1.18.4";

  src = fetchurl {
    url = "https://github.com/crmne/hyprmoncfg/releases/download/v${version}/hyprmoncfg_${version}_linux_amd64.tar.gz";
    hash = "sha256-Vk1tDbtiGuCBV1cYEfD3nH33wSyOo/paBs+w8tMcdAM=";
  };

  sourceRoot = ".";

  installPhase = ''
    install -Dm755 hyprmoncfg $out/bin/hyprmoncfg
    install -Dm755 hyprmoncfgd $out/bin/hyprmoncfgd
  '';

  meta = {
    description = "Arrange Hyprland monitors without coordinate math";
    homepage = "https://github.com/crmne/hyprmoncfg";
    license = lib.licenses.mit;
    platforms = ["x86_64-linux"];
    mainProgram = "hyprmoncfg";
  };
}
