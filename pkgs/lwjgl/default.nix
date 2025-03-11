{
  version,
  hash,
  antHash,
  ...
}@args:

{
  lib,
  stdenv,
  ant,
  assimp,
  buildPackages,
  dbus,
  draco,
  fetchAntDeps,
  fetchFromGitHub,
  freetype,
  glfw,
  glib,
  gtk3,
  harfbuzz,
  hwloc,
  jemalloc,
  kotlin,
  ktx-tools,
  libGL,
  libffi,
  libopus,
  openal,
  openxr-loader,
  pkg-config,
  sdl3,
  shaderc,
  spirv-cross,
  stripJavaArchivesHook,

  withVendoredLibraries ? true,
}:

let
  args' = lib.removeAttrs args [
    "version"
    "hash"
    "antHash"
  ];

  isCross = stdenv.buildPlatform != stdenv.hostPlatform;

  natives = {
    assimp = [
      (lib.getLib assimp + "/lib/libassimp.so")
      (lib.getLib draco + "/lib/libdraco.so")
    ];

    # bgfx = [ ];

    freetype = [ (lib.getLib freetype + "/lib/libfreetype.so") ];

    glfw = [ (lib.getLib glfw + "/lib/libglfw.so") ];

    harfbuzz = [ (lib.getLib harfbuzz + "/lib/libharfbuzz.so") ];

    hwloc = [ (lib.getLib hwloc + "/lib/libhwloc.so") ];

    jemalloc = [ (lib.getLib jemalloc + "/lib/libjemalloc.so") ];

    ktx = [ (lib.getLib ktx-tools + "/lib/libktx.so") ];

    openal = [ (lib.getLib openal + "/lib/libopenal.so") ];

    openxr = [ (lib.getLib openxr-loader + "/lib/libopenxr_loader.so") ];

    opus = [ (lib.getLib libopus + "/lib/libopus.so") ];

    sdl = [ (lib.getLib sdl3 + "/lib/libSDL3.so") ];

    shaderc = [ (lib.getLib shaderc + "/lib/libshaderc.so") ];

    spvc = [ (lib.getLib spirv-cross + "/lib/libspirv-cross.so") ];
  };
in

stdenv.mkDerivation (
  finalAttrs:

  lib.recursiveUpdate {
    pname = "lwjgl";
    inherit version;

    src = fetchFromGitHub {
      owner = "LWJGL";
      repo = "lwjgl3";
      tag = finalAttrs.version;
      inherit hash;
    };

    patches =
      lib.optionals (lib.versionOlder finalAttrs.version "3.3.4") [
        ./patches/3.3.3/0001-build-use-pkg-config-for-linux-dependencies.patch
        ./patches/3.3.3/0002-build-add-support-for-Linux-RISC-V-64.patch
        ./patches/3.3.3/0003-build-rpmalloc-get_thread_id-support-on-riscv64.patch
        ./patches/3.3.3/0004-build-core-fix-warnings-errors-on-GCC-14.patch
      ]

      ++ lib.optionals (lib.versionAtLeast finalAttrs.version "3.3.4") [
        ./patches/3.3.4/0001-build-use-pkg-config-for-linux-dependencies.patch
      ]

      ++ [
        ./patches/3.3.4/0002-build-allow-local-kotlin.patch
        ./patches/3.3.4/0003-build-allow-linking-against-system-libffi.patch
        ./patches/3.3.4/0004-build-add-dbus-as-dependency-for-nfd_portal.patch
        ./patches/3.3.4/0005-build-allow-setting-pkg-config-prefix-suffix.patch
      ];

    antJdk = buildPackages.jdk_headless;
    antDeps = fetchAntDeps {
      inherit (finalAttrs)
        pname
        version
        src
        patches
        antJdk
        antFlags
        ;
      hash = antHash;
    };

    strictDeps = true;

    nativeBuildInputs = [
      ant
      kotlin
      pkg-config
      stripJavaArchivesHook
    ];

    buildInputs = [
      dbus
      glib
      gtk3
      libffi
    ];

    antFlags =
      [
        "-Dgcc.libpath.opengl=${lib.getLib libGL}/lib"

        # Don't bundle javadoc, else ant will try to grab a favicon from lwjgl.org
        # It also slows down builds
        # https://github.com/LWJGL/lwjgl3/blob/5bd237c53774aa52703b35cc2e692d7113db2bca/build.xml#L1372C36-L1372C55
        "-Djavadoc.skip=true"

        "-Dlibffi.path=${lib.getLib libffi}/lib"
        "-Duse.libffi.so=true"

        "-Dlocal.kotlin=${lib.getBin kotlin}"
      ]
      ++ lib.optionals (!isCross) [
        "-Dgcc.prefix="
        "-Dpkg-config.prefix="
      ]
      ++ lib.optionals isCross [
        "-Dgcc.prefix=${stdenv.cc.targetPrefix}"
        "-Dpkg-config.prefix=${stdenv.cc.targetPrefix}"
      ];

    env = {
      JAVA_HOME = finalAttrs.antJdk.home;
      JAVA8_HOME = buildPackages.jdk8_headless.home;

      # https://github.com/LWJGL/lwjgl3/tree/e8552d53624f789c8f8c3dc35976fa02cba73cff/doc#build-configuration
      LWJGL_BUILD_ARCH =
        if stdenv.hostPlatform.isx86_64 then
          "x64"
        else if stdenv.hostPlatform.isi686 then
          "x86"
        else if stdenv.hostPlatform.isAarch64 then
          "arm64"
        else if stdenv.hostPlatform.isArmv7 then
          "arm32"
        else if stdenv.hostPlatform.isRiscV64 then
          "riscv64"
        else if stdenv.hostPlatform.isPower64 then
          "ppc64le"
        else
          throw "${stdenv.hostPlatform.cpu.name} is not a supported architecture";
      LWJGL_BUILD_OFFLINE = "yes";
      LWJGL_BUILD_TYPE = "release/${finalAttrs.version}";
    };

    preConfigure = lib.optionalString (!withVendoredLibraries) (
      ''
        natives_dir="bin/libs/native/linux/$LWJGL_BUILD_ARCH/org/lwjgl"
        mkdir -p $natives_dir
      ''
      + lib.concatLines (
        lib.flatten (
          lib.mapAttrsToList (
            name: libraries:
            [ "mkdir $natives_dir/${name}" ]
            ++ map (library: "ln -s ${library} $natives_dir/${name}/") libraries
          ) natives
        )
      )
    );

    # Put the dependencies we already downloaded in the right place
    # NOTE: This directory *must* be writable
    configurePhase = ''
      runHook preConfigure

      mkdir -p bin
      cp -dpr "$antDeps" bin/libs && chmod -R +w bin/libs

      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild

      concatTo flagsArray buildFlags buildFlagsArray antFlags antFlagsArray
      ant compile-templates compile-native release "''${flagsArray[@]}"

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/{lib,share/lwjgl3}

      find bin/RELEASE/ \
        -type f \
        -name '*.jar' \
        -and -not -name '*-sources.jar' \
        -exec install -Dm644 -t $out/share/lwjgl3 {} \;

      find bin/ \
        -type f \
        -name '*.so' \
        -exec install -Dm755 -t $out/lib {} \;

      runHook postInstall
    '';

    meta = {
      description = "Lightweight Java Game Library";
      homepage = "https://www.lwjgl.org/";
      changelog = "https://github.com/LWJGL/lwjgl3/releases/tag/${toString finalAttrs.src.tag}";
      license = lib.licenses.bsd3;
      maintainers = with lib.maintainers; [ getchoo ];
      platforms = lib.platforms.linux;
    };
  } args'
)
