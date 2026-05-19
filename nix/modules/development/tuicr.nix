{
  config,
  lib,
  pkgs,
  ...
}:
let
  tuicr = pkgs.rustPlatform.buildRustPackage rec {
    pname = "tuicr";
    version = "0.15.0";

    src = pkgs.fetchCrate {
      inherit pname version;
      hash = "sha256-oBx+UCu+hD+AJREZ/M7uCtJIqXfJh9AcU+eBIBa7tLE=";
    };

    cargoHash = "sha256-+ZQBqF6L72yHo1/ln6PPLUPBW3e8G7wjyKlX0K/sohQ=";

    nativeBuildInputs = with pkgs; [
      pkg-config
    ];

    buildInputs = with pkgs; [
      openssl
    ];

    # for some reason the test fails
    doCheck = false;

    meta = {
      description = "Review AI-generated diffs like a GitHub pull request, right from your terminal";
      homepage = "https://github.com/agavra/tuicr";
      license = lib.licenses.mit;
      mainProgram = "tuicr";
      platforms = lib.platforms.unix;
    };
  };
in
{
  environment.systemPackages = [ tuicr ];
}
