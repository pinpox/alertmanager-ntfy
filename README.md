# alertmanager-ntfy

Listen for webhooks from
[Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/) and
send them to [ntfy](https://ntfy.sh/) push notifications


Configuration is done with environment variables.


| Variable      | Description                  | Example                |
|---------------|------------------------------|------------------------|
| HTTP_ADDRESS  | Adress to listen on          | `localhost`            |
| HTTP_PORT     | Port to listen on            | `8080`                 |
| NTFY_TOPIC    | ntfy topic to send to        | `https://ntfy.sh/test` |
| NTFY_USER     | ntfy user for basic auth     | `myuser`               |
| NTFY_PASS     | ntfy password for basic auth | `supersecret`          |
| NTFY_PRIORITY | Priority of ntfy messages    | `high`                 |

# Nix

For Nix/Nixos users a `flake.nix` is provided to simplify the build. It also
privides app to test the hooks with mocked data from `mock.json`

### Build

```sh
nix build
```

### Run directly

```sh
nix run
```

### Test alerts

```sh
nix run '.#mock-hook'
```

### Module

The flake also includes a NixOS module for ease of use. A minimal configuration
will look like this:

```nix

# Add to flake inputs
inputs.alertmanager-ntfy.url = "github:pinpox/alertmanager-ntfy";

# Import the module in your configuration.nix
imports = [
	self.inputs.alertmanager-nfty.nixosModules.alertmanager-ntfy
];

# Enable and set options
services.alertmanager-ntfy = {
	enable = true;
	httpAddress = "localhost";
	httpPort = "9999";
	ntfyTopic = "https://ntfy.sh/test";
	ntfyPriority = "high";
	envFile = "/var/src/secrets/alertmanager-ntfy/envfile";
};
```
