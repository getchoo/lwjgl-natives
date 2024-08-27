{
  fetchFromGitHub,
  maven,
  temurin-bin,
}:

maven.buildMavenPackage {
  pname = "lwjgl";
  version = "3.3.4";

  src = fetchFromGitHub {
    owner = "LWJGL";
    repo = "lwjgl3";
    rev = "3.3.4";
    hash = "sha256-U0pPeTqVoruqqhhMrBrczy0qt83a8atr8DyRcGgX/yI=";
  };

  mvnHash = "sha256-QVRwMC4FREgwojlX5JzTap2eg7HPFNgElIeCVycPOAI=";
  # (Mainly) useful on riscv64 where we would have to build the entire JDK
  mvnJdk = temurin-bin.override {
    gtkSupport = false; # If only there was a headless version of this package...
  };

  postInstall = ''
    mkdir $out
    install -Dm644 target/*.jar $out/
  '';
}
