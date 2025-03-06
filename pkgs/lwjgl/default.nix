{
  lib,
  stdenv,
  breakpointHook,
  ant,
  buildPackages,
  dbus,
  fetchAntDeps,
  fetchFromGitHub,
  glib,
  gtk3,
  kotlin,
  libGLU,
  libffi,
  libglvnd,
  pkg-config,
  xorg,

  version,
  hash,
  antHash,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "lwjgl";
  inherit version;

  src = fetchFromGitHub {
    owner = "LWJGL";
    repo = "lwjgl3";
    tag = finalAttrs.version;
    inherit hash;
  };

  patches = [
    ./0001-build-use-pkg-config-for-linux-dependencies.patch
    ./0002-build-allow-local-kotlin.patch
    ./0003-build-allow-linking-against-system-libffi.patch
    ./0004-build-add-dbus-as-dependency-for-nfd_portal.patch
    ./0005-build-allow-setting-pkg-config-prefix-suffix.patch
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
  ] ++ lib.optional (lib.meta.availableOn stdenv.buildPlatform breakpointHook) breakpointHook;

  buildInputs = [
    dbus
    glib
    gtk3
    libGLU
    libffi
    xorg.libX11
    xorg.libXt
  ];

  antFlags =
    [
      "-Dgcc.libpath.opengl=${libglvnd}/lib"

      "-Dlibffi.path=${lib.getLib libffi}/lib"
      "-Duse.libffi.so=true"

      "-Dlocal.kotlin=${lib.getBin kotlin}"
    ]
    ++ lib.optionals (stdenv.buildPlatform != stdenv.hostPlatform) [
      "-Dgcc.prefix=${stdenv.cc.targetPrefix}"
      "-Dpkg-config.prefix=${stdenv.cc.targetPrefix}"
    ];

  env = {
    NIX_LDFLAGS = "-lffi";

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
      else
        throw "${stdenv.hostPlatform.cpu.name} is not a supported architecture";
    LWJGL_BUILD_OFFLINE = "yes";
    LWJGL_BUILD_TYPE = "release/${finalAttrs.version}";
  };

  # Put the dependencies we already downloaded in the right place
  # NOTE: This directory *must* be writable
  postConfigure = ''
    mkdir bin
    cp -dpr "$antDeps" ./bin/libs && chmod -R +w bin/libs
  '';

  postBuild = ''
    mkdir $out
    concatTo flagsArray buildFlags buildFlagsArray antFlags antFlagsArray
    ant compile-templates compile compile-native "''${flagsArray[@]}"
  '';

  postInstall = ''
    mkdir -p $out/lib
    find . -type f -name '*.so' -exec install -Dm755 -t $out/lib {} \;
  '';

  meta = {
    description = "Lightweight Java Game Library";
    homepage = "https://www.lwjgl.org/";
    changelog = "https://github.com/LWJGL/lwjgl3/releases/tag/${toString finalAttrs.src.tag}";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ getchoo ];
    platforms = lib.platforms.linux;
  };
})
