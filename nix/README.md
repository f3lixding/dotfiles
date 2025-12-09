# Modules
These are largely taken from https://nix.dev/tutorials/module-system/deep-dive of things that I find noteworthy

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
