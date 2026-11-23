{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.helium;
  package = cfg.package.override {
    inherit (cfg) flags extraArgs desktopIntegration;
  };
in
{
  options.programs.helium = {
    enable = lib.mkEnableOption "Helium Browser";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ../../pkgs/helium { };
      defaultText = "pkgs.helium from this flake";
      description = "The Helium package to install.";
    };

    flags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "--enable-features=TouchpadOverscrollHistoryNavigation" ];
      description = "Arguments baked into the Helium wrapper and applied on every launch.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "--start-maximized" ];
      description = "Additional arguments passed to Helium after the persistent flags.";
    };

    desktopIntegration = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install Helium desktop files and icons.";
    };

    policies = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      example = lib.literalExpression ''
        {
          BrowserSignin = 0;
          PasswordManagerEnabled = false;
        }
      '';
      description = "User-level Chrome Enterprise policies written as JSON.";
    };

    policyPath = lib.mkOption {
      type = lib.types.str;
      default = "helium/policies/managed/policies.json";
      example = "chromium/policies/managed/helium.json";
      description = "Path under xdg.configHome receiving the policy JSON.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ package ];
    xdg.configFile = lib.mkIf (cfg.policies != { }) {
      "${cfg.policyPath}".text = builtins.toJSON cfg.policies;
    };
  };
}
