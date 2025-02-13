# SPDX-FileCopyrightText: 2021 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA
{ nixpkgs, pkgs, ... }:
let
  inherit (pkgs) system;
in
import "${nixpkgs}/nixos/tests/make-test-python.nix" ({ ... }:
{
  name = "tezos-modules-test";
  machine = { ... }: {
    virtualisation.memorySize = 1024;
    virtualisation.diskSize = 1024;

    nixpkgs.pkgs = pkgs;
    imports = [ ../nix/modules/tezos-node.nix
                ../nix/modules/tezos-signer.nix
                ../nix/modules/tezos-accuser.nix
                ../nix/modules/tezos-baker.nix
              ];

    services.octez-node.instances.mumbainet = {
      enable = true;
      additionalOptions = [
        "--bootstrap-threshold=1"
        "--connections" "50"
      ];
    };

    services.octez-signer.instances.mumbainet = {
      enable = true;
      networkProtocol = "http";
    };

    services.octez-accuser.instances.mumbainet = {
      enable = true;
      baseProtocols = ["PtMumbai"];
    };

    services.octez-baker.instances.mumbainet = {
      enable = true;
      baseProtocols = ["PtMumbai"];
      bakerAccountAlias = "baker";
      bakerSecretKey = "unencrypted:edsk3KaTNj1d8Xd3kMBrZkJrfkqsz4XwwiBXatuuVgTdPye2KpE98o";
    };

  };

  testScript = ''
    start_all()

    services = [
        "octez-node",
        "octez-signer",
        "octez-baker",
        "octez-accuser",
    ]

    for s in services:
        machine.wait_for_unit(f"tezos-mumbainet-{s}.service")

    with subtest("check octez-node rpc response"):
        machine.wait_for_open_port(8732)
        machine.wait_until_succeeds(
            "curl --silent http://localhost:8732/chains/main/blocks/head/header | grep level"
        )

    with subtest("service status sanity check"):
        for s in services:
            machine.succeed(f"systemctl status tezos-mumbainet-{s}.service")
  '';
}) { inherit pkgs system; }
