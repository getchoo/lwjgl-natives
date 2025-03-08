{
  config,
  lib,
  inputs,
  ...
}:

let
  cfg = config.lwjgl;

  lwjglVersionSubmodule =
    { name, ... }:
    {
      freeformType = lib.types.attrsOf lib.types.anything;

      options = {
        version = lib.mkOption {
          type = lib.types.str;
          default = name;
          defaultText = lib.literalExpression "config.name";
          description = "Version of LWJGL3 these arguments are for.";
        };

        hash = lib.mkOption {
          type = lib.types.str;
          description = "Hash of the LWJGL3 source tarball.";
        };

        antHash = lib.mkOption {
          type = lib.types.str;
          description = "Hash of the LWJGL3 ant dependencies.";
        };
      };
    };

  lwjglSubmodule = {
    options = {
      targets = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "A list of target triples to cross compile LWJGL3 for.";
      };

      versions = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule lwjglVersionSubmodule);
        default = { };
        description = "An attribute set of LWJGL3 versions and hashes.";
      };
    };
  };
in

{
  options.lwjgl = lib.mkOption {
    type = lib.types.submodule lwjglSubmodule;
    default = { };
    description = "Configuration for the LWJGL3 project.";
  };

  config = {
    perSystem =
      {
        pkgs,
        system,
        self',
        ...
      }:

      let
        nativeTarget = pkgs.stdenv.hostPlatform.config;

        fetchAntDeps = pkgs.callPackage ./pkgs/fetch-ant-deps.nix { };

        # Loop over each target
        forAllTargets = lib.genAttrs cfg.targets;

        # Nixpkgs re-instantiated to cross compile from our current system to each target
        crossPkgsFor = forAllTargets (
          target:

          if target == nativeTarget then
            pkgs
          else
            import inputs.nixpkgs {
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
            lwjgls = lib.mapAttrs' (
              version: args:

              lib.nameValuePair "${target}-lwjgl-${version}" (
                crossPkgsFor.${target}.callPackage (import ./pkgs/lwjgl args) { inherit fetchAntDeps; }
              )
            ) cfg.versions;

            versions = lib.naturalSort (lib.attrNames lwjgls);
          in

          {
            # Use latest version by default
            lwjgl = lwjgls.${lib.elemAt versions (lib.length versions - 1)};
          }
          // lwjgls
        );
      in

      {
        packages = lib.mergeAttrsList (
          (lib.attrValues ourPackagesFor)
          ++ [
            {
              lwjgl =
                ourPackagesFor.${nativeTarget}.lwjgl
                  or (lib.trace "${nativeTarget} is not a supported target" pkgs.emptyFile);

              default = self'.packages.lwjgl;
            }
          ]
        );
      };
  };
}
