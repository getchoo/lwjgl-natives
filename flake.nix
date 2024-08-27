{
  description = "Native builds of LWJGL for more exotic platforms";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs) lib;
      systems = lib.systems.flakeExposed;

      forAllSystems = lib.genAttrs systems;
      nixpkgsFor = forAllSystems (system: nixpkgs.legacyPackages.${system});
    in
    {
      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
          formatter = self.formatter.${system};
        in
        {
          nixfmt = pkgs.runCommand "check-${formatter.pname}" { } ''
            cd ${self}

            echo "Running ${formatter.pname}..."
            ${lib.getExe formatter} --check .

            touch $out
          '';
        }
        # For use with nix-fast-build
        // self.packages.${system}
      );

      formatter = forAllSystems (system: nixpkgsFor.${system}.nixfmt-rfc-style);

      packages = forAllSystems (
        system:
        let
          pkgs = import (self + "/default.nix") {
            inherit system;
            pkgs = nixpkgsFor.${system};
          };

          isAvailable = lib.meta.availableOn { inherit system; };
          pkgs' = lib.filterAttrs (_: isAvailable) pkgs;
        in
        pkgs'
      );
    };
}
