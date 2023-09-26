{ lib
, buildGoModule
, fetchFromGitHub
, nixosTests
, caddy
, testers
, installShellFiles
}:
let
  version = "2.7.4";
  dist = fetchFromGitHub {
    owner = "caddyserver";
    repo = "dist";
    rev = "v${version}";
    hash = "sha256-8wdSRAONIPYe6kC948xgAGHm9cePbXsOBp9gzeDI0AI=";
  };
  plugins = [
    {
      name = "github.com/caddy-dns/cloudflare";
      version = "bfe272c8525b6dd8248fcdddb460fd6accfc4e84";
    }
  ];
in
buildGoModule {
  pname = "caddy";
  version = "master";

  src = fetchFromGitHub {
    owner = "Veraticus";
    repo = "caddy";
    rev = "master";
    hash = "sha256-Tke/eNoeRWXOB1AxagaxPFeyV9HLm9RXjQNQRtcZI0A=";
  };

  passthru.plugins = plugins;

  vendorHash = "sha256-NKn+A9oTS7DUk1qaZPSxFh80MBM2nOrgtDjngGXVxk0=";

  subPackages = [ "cmd/caddy" ];

  ldflags = [
    "-s"
    "-w"
    "-X github.com/caddyserver/caddy/v2.CustomVersion=${version}"
  ];

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    cp go.mod go.sum $out/

    install -Dm644 ${dist}/init/caddy.service ${dist}/init/caddy-api.service -t $out/lib/systemd/system

    substituteInPlace $out/lib/systemd/system/caddy.service --replace "/usr/bin/caddy" "$out/bin/caddy"
    substituteInPlace $out/lib/systemd/system/caddy-api.service --replace "/usr/bin/caddy" "$out/bin/caddy"

    $out/bin/caddy manpage --directory manpages
    installManPage manpages/*

    installShellCompletion --cmd caddy \
      --bash <($out/bin/caddy completion bash) \
      --fish <($out/bin/caddy completion fish) \
      --zsh <($out/bin/caddy completion zsh)
  '';

  overrideModAttrs = _: {
    preBuild = lib.flip lib.concatMapStrings plugins
      ({ name
       , version
       ,
       }: "go get ${lib.escapeShellArg name}@${lib.escapeShellArg version}\n");
  };

  postPatch = lib.flip lib.concatMapStrings plugins
    ({ name, ... }: "sed -i '/plug in Caddy modules here/a \\\\t_ \"${name}\"' cmd/caddy/main.go\n");
  postConfigure = "cp vendor/go.mod vendor/go.sum .";

  passthru.tests = {
    inherit (nixosTests) caddy;
    version = testers.testVersion {
      command = "${caddy}/bin/caddy version";
      package = caddy;
    };
  };

  meta = with lib; {
    homepage = "https://caddyserver.com";
    description = "Fast and extensible multi-platform HTTP/1-2-3 web server with automatic HTTPS";
    license = licenses.asl20;
    maintainers = with maintainers; [ Br1ght0ne emilylange techknowlogick ];
  };
}
