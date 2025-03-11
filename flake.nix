{
  nixConfig = {
    # TODO: Move to lwjgl-cache.prismlauncher.org
    # Thank you Soopy
    extra-substituters = [ "https://s3.soopy.moe/lwjgl-nix" ];
    extra-trusted-public-keys = [
      "lwjgl-cache.prismlauncher.org:ucMitaRYTISlJtFr5ETPsDm8UCBAQ4+PTj2rBVlK8IQ="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    getchpkgs = {
      url = "github:getchoo/getchpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:

    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./checks.nix
        ./dev-shells.nix
        ./lwjgl.nix
        ./module.nix
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      perSystem =
        { pkgs, ... }:

        {
          formatter = pkgs.nixfmt-rfc-style;
        };
    };
}
