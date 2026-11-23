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
      example = [
        "--ozone-platform-hint=auto"
        "--start-maximized"
      ];
      description = "Arguments baked into the Helium wrapper and applied on every launch.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "--proxy-server=http://127.0.0.1:7890" ];
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
      description = "Chrome Enterprise policies written as JSON.";
    };

    policyPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "chromium/policies/managed/helium.json"
        "helium/policies/managed/helium.json"
      ];
      example = [ "chromium/policies/managed/policies.json" ];
      description = "Absolute-under-/etc paths receiving the policy JSON.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ package ];
    environment.etc = lib.mkIf (cfg.policies != { }) (
      lib.genAttrs cfg.policyPaths (_: {
        text = builtins.toJSON cfg.policies;
      })
    );
  };
}
