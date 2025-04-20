# Main entrypoint for the library. Imports and combines the different parts.
{ lib }: # Takes pkgs.lib as input

let
  # Import the type definitions
  types = import ./types { inherit lib; };

  # Import generator functions (passing types)
  generators = import ./generators.nix { inherit lib types; };

  # Import DSL functions (passing types and generators)
  dsl = import ./dsl.nix { inherit lib types; };

in
# Expose the public API of the library
{
  # Expose the types for users who need lower-level access
  inherit types;

  # Expose the DSL functions as the primary interface
  inherit dsl;

  # Optionally expose generators if needed, or keep them internal
  # inherit generators;

  # Example: A helper function that might use the DSL internally
  # This could be part of the top-level API or within the DSL itself.
  generateExampleConfig = {
    # Example using the DSL functions to build a simple config structure
    # This is just a placeholder structure
    global = {
      check_for_updates_on_startup = false;
    };
    profiles = [
      {
        name = "Default";
        complex_modifications = {
          rules = [
            (dsl.mkRule {
              description = "Example Rule";
              manipulators = [
                {
                  # Simplified manipulator structure for example
                  type = "basic";
                  from = {
                    key_code = "caps_lock";
                  };
                  to = [ (dsl.mkBasicKey "escape") ];
                  conditions = [
                    (dsl.mkFrontmostCondition {
                      type = "unless";
                      bundles = [ "^com\\.googlecode\\.iterm2$" ];
                    })
                  ];
                }
              ];
            })
          ];
        };
      }
    ];
  };
}
