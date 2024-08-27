# nix-shell
{
  pkgs ? import <nixpkgs> {
    inherit system;
    config = { };
    overlays = [ ];
  },
  system ? builtins.currentSystem,
}:

pkgs.mkShellNoCC {
  packages = [
    pkgs.deadnix
    pkgs.nixfmt-rfc-style
    pkgs.statix
  ];
}
