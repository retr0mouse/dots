{lib, ...}: {
  options.dotfiles = {
    deployment = {
      role = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = "The transferable logical role assigned to this deployment.";
      };

      machine = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = "The physical machine currently providing this deployment.";
      };

      activateIdentity = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether services that claim the role's network identity may activate.
          Disable this for a staged replacement that runs alongside the active role.
        '';
      };
    };

    hardware = {
      battery = lib.mkEnableOption "battery-dependent user features";
      backlight = lib.mkEnableOption "display-backlight-dependent user features";
      powerProfiles = lib.mkEnableOption "power-profile-dependent user features";
      integratedGpu = lib.mkEnableOption "integrated-GPU-dependent user features";
      discreteGpu = lib.mkEnableOption "discrete-GPU-dependent user features";

      lanInterface = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          The physical LAN interface provided by this machine, when a role
          needs to attach network policy to it.
        '';
      };

      videoAcceleration = lib.mkOption {
        type = lib.types.nullOr (lib.types.enum ["nvenc" "vaapi"]);
        default = null;
        description = "The hardware video-acceleration backend provided by this machine.";
      };
    };
  };
}
