# nix-build
# or to build a cross compiled package: nix-build -A <triple>.lwjgl
# i.e., nix-build -A aarch64-unknown-linux-gnu.lwjgl
{
  pkgs ? import <nixpkgs> {
    inherit system;
    config = { };
    overlays = [ ];
  },
  nixpkgs ? <nixpkgs>,
  system ? builtins.currentSystem,
}:

let
  inherit (pkgs) lib;
  inherit (pkgs.stdenv.hostPlatform) system;
  nativeTarget = pkgs.stdenv.hostPlatform.config;

  # Targets we want to build for
  targets = [
    "x86_64-unknown-linux-gnu"
    "i686-unknown-linux-gnu"
    "aarch64-unknown-linux-gnu"
    "armv7l-unknown-linux-gnueabihf"
    "riscv64-unknown-linux-gnu"
  ];

  # Loop over each target
  forAllTargets = lib.genAttrs targets;

  # Nixpkgs re-instantiated to cross compile from our current system to each target
  crossPkgsFor = forAllTargets (
    target:

    import nixpkgs {
      inherit system;
      inherit (pkgs) config overlays;
      crossSystem = {
        config = target;
      };
    }
  );

  # Our package set for each target
  ourPackagesFor = forAllTargets (
    target:

    let
      callPackage = lib.callPackageWith (ourPackagesFor.${target} // crossPkgsFor.${target});
    in

    {
      fetchAntDeps = callPackage ./pkgs/fetch-ant-deps.nix { };
      lwjgl = callPackage ./pkgs/lwjgl.nix { };
    }
  );

  nativeLwjgl =
    ourPackagesFor.${nativeTarget}.lwjgl
      or (lib.trace "${nativeTarget} is not a supported target" pkgs.emptyFile);
in

ourPackagesFor // { lwjgl = nativeLwjgl; }
