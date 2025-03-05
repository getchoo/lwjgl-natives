{
  lib,
  inputs,
  self,
  ...
}:

let
  collectNestedDerivationsIn = lib.foldlAttrs (
    acc: attrType: values:

    acc // lib.mapAttrs' (attrName: lib.nameValuePair "${attrType}-${attrName}") values
  ) { };
in

{
  imports = [ inputs.getchpkgs.flakeModules.checks ];

  perSystem =
    {
      pkgs,
      system,
      self',
      ...
    }:

    lib.mkMerge [
      {
        checks = collectNestedDerivationsIn { inherit (self') devShells packages; };
      }

      (lib.mkIf (system == "x86_64-linux") {
        quickChecks = {
          deadnix = {
            dependencies = [ pkgs.deadnix ];
            script = "deadnix --fail ${self}";
          };

          nixfmt = {
            dependencies = [ pkgs.nixfmt-rfc-style ];
            script = "nixfmt --check ${self}";
          };

          statix = {
            dependencies = [ pkgs.statix ];
            script = "statix check ${self}";
          };
        };
      })
    ];
}
