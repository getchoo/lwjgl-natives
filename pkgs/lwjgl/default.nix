{
  lib,
  stdenv,
  breakpointHook,
  ant,
  at-spi2-atk,
  buildPackages,
  cairo,
  dbus,
  fetchAntDeps,
  fetchFromGitHub,
  gdk-pixbuf,
  glib,
  gtk3,
  harfbuzz,
  kotlin,
  libGLU,
  libffi,
  libglvnd,
  pango,
  replaceVars,
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
    (replaceVars ./fix-library-paths.patch (
      lib.mapAttrs (lib.const lib.getDev) {
        inherit
          at-spi2-atk
          cairo
          dbus
          gdk-pixbuf
          glib
          gtk3
          harfbuzz
          pango
          ;
      }
    ))
  ];

  antJdk = buildPackages.jdk_headless;
  antDeps = fetchAntDeps {
    inherit (finalAttrs)
      pname
      version
      src
      antJdk
      ;
    hash = antHash;
  };

  strictDeps = true;

  nativeBuildInputs = [
    ant
    kotlin
  ] ++ lib.optional (lib.meta.availableOn stdenv.buildPlatform breakpointHook) breakpointHook;

  buildInputs = [
    at-spi2-atk
    cairo
    dbus
    gdk-pixbuf
    glib
    gtk3
    harfbuzz
    libGLU
    libffi
    pango
    xorg.libX11
    xorg.libXt
  ];

  env = {
    NIX_CFLAGS = "-funroll-loops -I${lib.getDev gtk3}/include/gtk-3.0";
    NIX_LDFLAGS = "-lffi";

    JAVA_HOME = finalAttrs.antJdk.home;
    JAVA8_HOME = buildPackages.jdk8_headless.home;

    # https://github.com/LWJGL/lwjgl3/tree/e8552d53624f789c8f8c3dc35976fa02cba73cff/doc#build-configuration
    LWJGL_BUILD_OFFLINE = "yes";
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
  };

  # Put the dependencies we already downloaded in the right place
  # NOTE: This directory *must* be writable
  postConfigure = ''
    mkdir bin
    cp -dpr "$antDeps" ./bin/libs && chmod -R +w bin/libs
  '';

  postBuild = ''
    mkdir $out
    ant \
      -emacs \
      -Dgcc.libpath.opengl=${libglvnd}/lib \
    	compile-templates compile-native
  '';

  postInstall = ''
    exit 1
  '';

  meta = {
    platforms =

      let
        architectures = lib.flatten [
          lib.platforms.x86_64
          lib.platforms.i686
          lib.platforms.aarch64
          lib.platforms.armv7
          lib.platforms.riscv64
        ];
      in

      lib.intersectLists architectures lib.platforms.linux;
  };
})
