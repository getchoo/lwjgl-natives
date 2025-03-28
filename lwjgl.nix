{
  lwjgl = {
    # Targets we want to build for
    targets = [
      "x86_64-unknown-linux-gnu"
      "aarch64-unknown-linux-gnu"
      "armv7l-unknown-linux-gnueabihf"
      # TODO: Backport support to 3.3.3
      # "powerpc64le-unknown-linux-gnu"
      "riscv64-unknown-linux-gnu"
    ];

    # Versions we're building
    versions = {
      "3.3.3" = {
        hash = "sha256-5Zyl1UmfWGdxLWfQwdCO04pVcRUZh6QpV/ND5u4CYx8=";
        antHash = "sha256-wh15d3DPaIegkaA/AWvuGIxPFSOHmGA9iADy4B45IAs=";
      };

      "3.3.4" = {
        hash = "sha256-U0pPeTqVoruqqhhMrBrczy0qt83a8atr8DyRcGgX/yI=";
        antHash = "sha256-BE2sSPgYELCkww8aJV5DYTgHy4LT14RTVh6gRXA64+Q=";
      };

      "3.3.6" = {
        hash = "sha256-iXwsTo394uoq8/jIlfNuQlXW1lnuge+5/+00O4UdvyA=";
        antHash = "sha256-n2ON2eMBWZbu4A2yPBR4wN17dpWkBrf+1nq2l4uK3yk=";
      };
    };
  };
}
