# With flake, you would build with
# `sudo nixos-rebuild switch --flake .#hostname`
# To update either input, you would do so with
# `nix flake update input_name`
# To see if anything is in the input is different from their remote counterpart:
# `nix flake metadata`, and compare the locked URL with that from `nix flake metadata url_to_input`
{
  inputs = {
    # These are fetched and nixpkgs and would result in an attr set
    # When you import these attr set, it would get coerced into set.outPath
    # See https://discourse.nixos.org/t/get-flake-input-store-path/20202
    # This means you can use these attr set like so: import nixpkgs-unstable { system = "x86_64-linux" }
    # Note that nixpkgs is already imported with system resolved (done by nixpkgs.lib.nixosSystem)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, ... }:
    let
      hostname = "nixos";
      system = "x86_64-linux";
      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit unstable; };
        modules = [ ./configuration.nix ];
      };
    };
}
