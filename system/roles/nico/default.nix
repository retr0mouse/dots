{config, ...}: {
  imports = [
    ./server.nix
    ./applications.nix
    ./minecraft.nix
    ./monitoring.nix
    ./networking.nix
  ];

  assertions = [
    {
      assertion = builtins.hasAttr "/data" config.fileSystems;
      message = ''
        The Nico role requires its assigned machine to provide a /data
        filesystem for media and application storage.
      '';
    }
  ];
}
