{ config, pkgs, lib, ... }:
with lib;

# with lib;
let cfg = config.services.alertmanager-ntfy;
in {

  options.services.alertmanager-ntfy = {
    enable = mkEnableOption "alertmanager-ntfy service";

    httpAddress = mkOption {
      type = types.str;
      default = "localhost";
      example = "127.0.0.1";
      description = "Host to listen on";
    };

    httpPort = mkOption {
      type = types.str;
      default = "11000";
      example = "1300";
      description = "Port to listen on";
    };

    ntfyTopic = mkOption {
      type = types.str;
      default = null;
      description = "ntfy.sh topic to send to";
      example = "https://ntfy.sh/test";
    };

    ntfyPriority = mkOption {
      type = types.str;
      default = "";
      description = "ntfy.sh message priority";
      example = "urgent";
    };

    envFile = mkOption {
      type = types.str;
      default = null;
      example = "/var/secrets/alertmanager-ntfy/envfile";
      description = ''
        Additional environment file to pass to the service.
        e.g. with NFTY_USER and NTFY_PASS
      '';
    };
  };

  config = mkIf cfg.enable {

    # User and group
    users.users.alertmanager-ntfy = {
      isSystemUser = true;
      description = "alertmanager-ntfy system user";
      extraGroups = [ "alertmanager-ntfy" ];
      group = "alertmanager-ntfy";
    };

    users.groups.alertmanager-ntfy = { name = "alertmanager-ntfy"; };

    # Service
    systemd.services.alertmanager-ntfy = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "alertmanager-ntfy";
      serviceConfig = {

        EnvironmentFile = [ cfg.envFile ];
        Environment = [
          "HTTP_ADDRESS='${cfg.httpAddress}'"
          "HTTP_PORT='${cfg.httpPort}'"
          "NTFY_TOPIC='${cfg.ntfyTopic}'"
          "NTFY_PRIORITY='${cfg.ntfyPriority}'"
        ];

        User = "alertmanager-ntfy";
        ExecStart = "${pkgs.alertmanager-ntfy}/bin/alertmanager-ntfy";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
