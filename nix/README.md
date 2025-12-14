# Modules
These are largely taken from https://nix.dev/tutorials/module-system/deep-dive of things that I find noteworthy

[Official wiki link for modules](https://wiki.nixos.org/wiki/NixOS_modules)

`configuration.nix` is just a module. 

General structure of a module is a function. Generally: 
- Input: libs, pkgs, etc
- Output: an attribute set that includes `options` and `config`

`options`: type def for the config. It declares what can be configured and with what type of data
`config`: values for the options

Modules are evaluated with `libs.evalModules`
- [Doc link](https://nixos.org/manual/nixpkgs/stable/#module-system-lib-evalModules)
- The modules (the ones you pass into the `modules` param of `evalModules` function) can be a file path that contains a function
- Or the function can be written inline
- The functions are evaluated with [these args](https://nixos.org/manual/nixpkgs/stable/#module-system-module-arguments)
- As the doc has specified, the modules are [merged](https://nixos.org/manual/nixpkgs/stable/#module-system-lib-evalModules-param-modules). This is important because each function is evalauted with the merged modules.

You can define options without defining values for them in the config. But you cannot do the reverse.

**Imports and attribute merging**
[import](https://nix.dev/tutorials/nix-language.html#import) takes a nix file, evaluates it and spits out an expression.
If the path given is a directory, it will use the `default.nix` in that directory as entry point.
In a module, if `import` is called the attribute set returned is then merged with the one from the call site. 
The implication here is that in the importee attribute set, you are then free to call assign values defined in the options of the importer!!

Consider the following example from the tutorial:
```nix
# default.nix
{ lib, pkgs, config, ... }: {
  imports = [ ./marker.nix ];

  options = {
    scripts.output = lib.mkOption { type = lib.types.package; };

    requestParams = lib.mkOption { type = lib.types.listOf lib.types.str; };

    map = {
      zoom = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = 10;
      };

      center = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "switzerland";
      };
    };

    scripts.geocode = lib.mkOption { type = lib.types.package; };
  };

  config = {
    scripts.geocode = pkgs.writeShellApplication {
      name = "geocode";
      runtimeInputs = with pkgs; [ curl jq ];
      text = ''exec ${./geocode.sh} "$@"'';
    };

    scripts.output = pkgs.writeShellApplication {
      name = "map";
      runtimeInputs = with pkgs; [ curl feh ];
      text = ''
        ${./map.sh} ${lib.concatStringsSep " " config.requestParams} | feh -
      '';
    };

    requestParams = [
      "size=640x640"
      "scale=2"
      (lib.mkIf (config.map.zoom != null) "zoom=${toString config.map.zoom}")
      (lib.mkIf (config.map.center != null) ''
        center ="$(${config.scripts.geocode}/bin/geocode ${
          lib.escapeShellArg config.map.center
        })"'')
    ];
  };
}

# marker.nix
{ lib, config, ... }:
let
  markerType = lib.types.submodule {
    options = {
      locations = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
    };
  };
in {
  options = {
    map.markers = lib.mkOption { type = lib.types.listOf markerType; };
  };

  config = {
    map.markers = [{ locations = "new york"; }];

    map.center = lib.mkIf (lib.length config.map.markers >= 1) null;

    map.zoom = lib.mkIf (lib.length config.map.markers >= 2) null;

    requestParams = let
      paramForMarker = builtins.map (marker:
        "$(${config.scripts.geocode}/bin/geocode ${
          lib.escapeShellArg marker.locations
        })") config.map.markers;
    in [ ''markers="${lib.concatStringsSep "|" paramForMarker}"'' ];
  };
}
```

The imported attribute set is merged with `options` and `config`.

# Lazy Evaluation
This is how the nix engine evaluate things - Values do not get filled in until the attributes is used. 
This allows you to do some circular dependencies: 
```nix
# Pseudo-code
let
  # Call all module functions and collect their returned configs
  module1Result = module1 { config = finalConfig; };  # ← Pass finalConfig
  module2Result = module2 { config = finalConfig; };  # ← Pass finalConfig
  
  # Merge all the configs together
  finalConfig = merge [
    module1Result.config  # { bar = "value is: ${config.foo}"; }
    module2Result.config  # { foo = "hello"; }
  ];
  # finalConfig = { foo = "hello"; bar = "value is: ${finalConfig.foo}"; }
  #                                                    ^^^^^^^^^^^^ self-reference
in
  finalConfig
```
