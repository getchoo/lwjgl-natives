{
  pkgs ? import <nixpkgs> {
    inherit system;
    config = {
      # Maven is not supported for riscv OOTB in nixpkgs
      allowUnsupportedSystem = true;
    };
    overlays = [ ];
  },
  system ? builtins.currentSystem,
}:

let
  inherit (pkgs) lib;

  # Build our packages with from the given package set
  mkPackagesWith = pkgs: { lwjgl = pkgs.callPackage ./lwjgl.nix { }; };

  # Targets we want to cross compile for
  crossTargets = with pkgs.pkgsCross; [
    # aarch64-linux
    aarch64-multiplatform
    # powerpc64le-linux
    powernv
    # riscv64-linux
    riscv64
  ];

  # If the package is cross compiled, append the system triple to its name
  fixupNameOf =
    package:
    (builtins.parseDrvName package.name).name
    + lib.optionalString (
      pkgs.stdenv.hostPlatform != pkgs.stdenv.buildPlatform
    ) package.stdenv.hostPlatform.config;

  # Packages compiled with our native package set
  nativePackages = mkPackagesWith pkgs;

  # Packages cross compiled for the targets listed above
  crossPackages = lib.mergeAttrsList (
    map (
      pkgs:
      let
        packages = mkPackagesWith pkgs;
      in
      lib.mapAttrs' (_: package: lib.nameValuePair (fixupNameOf package) package) packages
    ) crossTargets
  );
in
nativePackages // crossPackages // { default = nativePackages.lwjgl; }
