# nix-build release.nix -A <system>
# i.e., nix-build release.nix -A x86_64-linux
{
  lib ? import <nixpkgs/lib>,
}:

let
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.gitTracked ./.;
  };

  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "x86_64-darwin"
    "aarch64-darwin"
  ];
in

lib.genAttrs systems (
  system:

  let
    pkgs = import <nixpkgs> {
      inherit system;
      config = { };
      overlays = [ ];
    };

    mkCheck =
      name: deps: script:
      pkgs.runCommand name { nativeBuildInputs = deps; } ''
        ${script}
        touch $out
      '';

    packages = lib.mapAttrs (lib.const lib.recurseIntoAttrs) (import ./default.nix { inherit pkgs; });

    checks = {
      deadnix = mkCheck "check-deadnix" [ pkgs.deadnix ] "deadnix --fail ${src}";
      nixfmt = mkCheck "check-nixfmt" [ pkgs.nixfmt-rfc-style ] "nixfmt --check ${src}";
      statix = mkCheck "check-statix" [ pkgs.statix ] "statix check ${src}";
    };
  in

  checks // packages // { shell = import ./shell.nix { inherit pkgs; }; }
)
