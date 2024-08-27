{
  lib,
  stdenv,
  ant,
  buildPackages,
}:

lib.makeOverridable (
  lib.fetchers.withNormalizedHash { } (
    {
      pname,
      nativeBuildInputs ? [ ],
      antJdk ? buildPackages.jdk,
      outputHash,
      outputHashAlgo,
      ...
    }@args:

    let
      args' = lib.removeAttrs args [
        "pname"
        "nativeBuildInputs"
        "antJdk"
      ];
    in

    stdenv.mkDerivation (
      lib.recursiveUpdate {
        pname = pname + "-ant-deps";

        nativeBuildInputs = [ ant ] ++ nativeBuildInputs;

        buildPhase = ''
          runHook preBuild
          ant init
          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          mv bin/libs $out
          runHook postInstall
        '';

        fixupPhase = ''
          runHook preFixup

          find $out -type f \( \
            -name \*.lastUpdated \
            -o -name resolver-status.properties \
            -o -name _remote.repositories \) \
            -delete

          runHook postFixup
        '';

        dontConfigure = true;

        env = {
          JAVA_HOME = toString (antJdk.passthru.home or antJdk);
        };

        inherit outputHash outputHashAlgo;
        outputHashMode = "recursive";
      } args'
    )
  )
)
