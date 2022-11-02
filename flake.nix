{
  description = "Relay prometheus alerts to ntfy.sh";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { nixpkgs, flake-utils, self, ... }:

    {
      nixosModule = ({ pkgs, ... }: {
        imports = [ ./module.nix ];
        # defined overlays injected by the nixflake
        nixpkgs.overlays = [
          (_self: _super: {
            alertmanager-ntfy = self.packages.${pkgs.system}.alertmanager-ntfy;
          })
        ];
      });
    } //

    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in rec {
        packages = flake-utils.lib.flattenTree rec {

          alertmanager-ntfy = pkgs.buildGoModule rec {

            pname = "alertmanager-ntfy";
            version = "1.0.0";

            src = ./.;
            vendorSha256 = "sha256-Ezt1HDxGQ7DePF90HgHKkH7v365ICFdnfcWJipLhCwQ=";

            meta = with pkgs.lib; {
              description = "Relay prometheus alerts to ntfy";
              homepage = "https://github.com/pinpox/alertmanager-ntfy";
              license = licenses.gpl3;
              maintainers = with maintainers; [ pinpox ];
            };
          };

          mock-hook = pkgs.writeScriptBin "mock-hook" ''
            #!${pkgs.stdenv.shell}
            ${pkgs.curl}/bin/curl -X POST -d @mock.json http://$HTTP_ADDRESS:$HTTP_PORT
          '';
        };

        apps = {
          mock-hook = flake-utils.lib.mkApp { drv = packages.mock-hook; };
          alertmanager-ntfy = flake-utils.lib.mkApp { drv = packages.alertmanager-ntfy; };
        };

        defaultPackage = packages.alertmanager-ntfy;
        defaultApp = apps.alertmanager-ntfy;
      });
}
