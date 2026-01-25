{
  config,
  lib,
  pkgs,
  ...
}:
# When you pass a function to mkDerivation instead
# of an attribute set, it receives the final arguments as its parameter.
# This is the finalAttrs pattern introduced in
# https://github.com/NixOS/nixpkgs/blob/master/doc/stdenv/stdenv.chapter.md.
let
  clawdbot = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "clawdbot";
    version = "2026.1.23";

    src = pkgs.fetchFromGitHub {
      owner = "clawdbot";
      repo = "clawdbot";
      rev = "v${finalAttrs.version}";
      hash = "sha256-egAHjt6CHz79fStSg42opVPHjquurAa6FcGpNkQ0UtA=";
    };

    pnpmDeps = pkgs.pnpm_9.fetchDeps {
      inherit (finalAttrs) pname version src;
      hash = "sha256-m7M+9U0caY5jBek64t/tDXEIRQfKUZSoeWlTSvaljjE=";
      fetcherVersion = 3;
    };

    nativeBuildInputs = [
      pkgs.nodejs_22
      pkgs.pnpm_9
      pkgs.pnpm_9.configHook
      pkgs.makeWrapper
    ];

    buildPhase = ''
      runHook preBuild
      pnpm ui:build
      pnpm build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin $out/lib/clawdbot
      cp -r . $out/lib/clawdbot

      # Create wrapper script
      # From the https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/s
      # etup-hooks/make-wrapper.sh:
      makeWrapper ${pkgs.nodejs_22}/bin/node $out/bin/clawdbot \
        --add-flags "$out/lib/clawdbot/dist/entry.js"

      runHook postInstall
    '';

    meta = with lib; {
      description = "Your own personal AI assistant. Any OS. Any Platform";
      homepage = "https://github.com/clawdbot/clawdbot";
      license = licenses.asl20;
      mainProgram = "clawdbot";
    };
  });
in
{
  environment.systemPackages = [ clawdbot ];
}
