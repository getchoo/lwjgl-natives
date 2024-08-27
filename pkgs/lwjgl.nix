{
  lib,
  stdenv,
  breakpointHook,
  ant,
  at-spi2-atk,
  buildPackages,
  dbus,
  fetchAntDeps,
  fetchFromGitHub,
  gdk-pixbuf,
  gtk3,
  kotlin,
  libGLU,
  libglvnd,
  xorg,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "lwjgl";
  version = "3.3.4";

  src = fetchFromGitHub {
    owner = "LWJGL";
    repo = "lwjgl3";
    tag = finalAttrs.version;
    hash = "sha256-U0pPeTqVoruqqhhMrBrczy0qt83a8atr8DyRcGgX/yI=";
  };

  antJdk = buildPackages.jdk_headless;
  antDeps = fetchAntDeps {
    inherit (finalAttrs)
      pname
      version
      src
      antJdk
      ;
    hash = "sha256-7jVlKBia8dJGuBjNwaljHBrXUep9KjOHHyZESayFnhs=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    ant
    kotlin
  ] ++ lib.optional (lib.meta.availableOn stdenv.buildPlatform breakpointHook) breakpointHook;

  buildInputs = [
    at-spi2-atk
    dbus
    gdk-pixbuf
    gtk3
    libGLU
    xorg.libX11
    xorg.libXt
  ];

  env = {
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
