{
  perSystem =
    { pkgs, ... }:

    {
      devShells = {
        default = pkgs.mkShellNoCC {
          packages = [
            pkgs.deadnix
            pkgs.nixfmt-rfc-style
            pkgs.statix
          ];
        };
      };
    };
}
