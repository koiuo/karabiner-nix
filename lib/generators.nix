# lib/generators.nix
# Contains low-level functions, potentially for generating Nix structures
# based on types or performing specific transformations.
# For now, it might be simple, relying on the types for structure.
{ lib, types }: # Pass lib and the defined types

{
  # Example: A generator that ensures a condition conforms to the type.
  # In practice, the DSL might handle this directly using the types.
  # This layer could be used for more complex default generation or transformations.
  mkConditionChecked =
    conditionData:
    let
      # Use lib.evalModules to validate against the type definition
      validated =
        lib.evalModules
          {
            modules = [
              {
                options.condition = types.frontmostApplicationCondition;
                config.condition = conditionData;
              }
            ];
          }
          .config.condition;
    in
    validated;

  # Example: Basic key press generator (might just return the input if DSL handles validation)
  mkBasicKeyPressChecked =
    keyPressData:
    let
      validated =
        lib.evalModules
          {
            modules = [
              {
                options.keyPress = types.basicKeyPress;
                config.keyPress = keyPressData;
              }
            ];
          }
          .config.keyPress;
    in
    validated;

  # Add other generator functions as needed...
}
