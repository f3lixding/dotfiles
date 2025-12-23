# Overview and docs 
In general I find nix docs to be a shitshow. The docs are just all over the place and extremely fragmented. 
It helps to navigate if the general categories of concerns are first understood: 

1. Nix Manual - The Nix package manager itself
- https://nixos.org/manual/nix/stable/
- Covers: nix commands, language basics, store, derivations

2. Nixpkgs Manual - Package collection and build helpers
- https://nixos.org/manual/nixpkgs/stable/
- Covers: stdenv.mkDerivation, overlays, cross-compilation, pkgs.write* functions

3. NixOS Manual - The Linux distribution
- https://nixos.org/manual/nixos/stable/
- Covers: module system, lib.types, configuration.nix, services

4. Nix Pills - Tutorial series
- https://nixos.org/guides/nix-pills/
- Covers: learning Nix from scratch, derivation internals

5. nix.dev - Community-maintained learning resource
- https://nix.dev/
- Covers: tutorials, guides, best practices

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

# String interpolation
`${}` expands the expression passed to it. 
The actual expansion logic depends on what is passed to it: 
```nix
# Strings - just inserts the value
name = "felix";
"Hello ${name}"  # => "Hello felix"

# Numbers - converts to string
count = 42;
"Count: ${toString count}"  # Need toString for numbers

# Paths - converts to string path
myPath = ./some/file;
"${myPath}"  # => "/nix/store/...-some-file" (copies to store)

# Derivations - converts to output path
drv = pkgs.hello;
"${drv}/bin/hello"  # => "/nix/store/...-hello-2.x/bin/hello"

# Lists/attrsets - error (must convert first)
"${[1 2 3]}"  # ERROR
"${toString [1 2 3]}"  # => "1 2 3"
```

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

This is somewhat tricky to think about. An easy way to just "accept" it is to think of the lazily evaluated value as values that you will eventually end up with.

# REPL
`nix repl` is how you can explore modules and derivations imperatively.

[Documentation](https://nix.dev/manual/nix/2.24/command-ref/new-cli/nix3-repl)

You can view the available variables after loading with `:l` with the following:
- `<TAB>`
- And you can print what they are with typing out their variable names
- If you wish to see what attributes they have, do it with `builtins.attrNames ${variable}`

# MediaTek WiFi
So this is specific to the framework desktop, which uses a MediaTek mt7925e WiFi. 
The mt7925e is notoriously aggresive about roaming (i.e. where it switches from one access point to another). And every time this happens, there is a 200 to 500 ms where packets are lost.
What this looks like when you are using any application that requires to have a constant connection (i.e. games) is server side stuttering. 
And you can see this by looking at the kernal log: 
```
dmesg -w
```

And this will show up as something like this: 
```
[  440.809628] wlp192s0: disconnect from AP xxxxx for new auth to xxxxx
```

To combat this, the roaming needs to be turned off: 
```
// First we need to find the network interface being used:
// The return of which shall be referred to as $netint
ip link show 

// And then we will need to see the access point it is connected to
// The return of which shall be referred to as $ap
nix-shell -p wirelesstools --command "iwconfig $netint"

// Find the BSSID (Basic Service Set Identifier. It is the MAC address of a specific WiFi access point's radio)
// The answer of which shall be referred to as $bssid
nmcli connection show $SSID | grep bssid

// Explicitly specify the AP:
sudo nmcli connection modify $SSID $bssid $ap
// Shut it down
sudo nmcli connection down $SSID
// Bring it back up again
sudo nmcli connection up $SSID

// And then verify this was changed 
nmcli connection show $SSID | grep bssid
```
