# tests/default.nix
# Main test suite definition, referenced by `flake.nix` checks.
{ pkgs, karabiner-lib }:

let
  lib = pkgs.lib;
  # Import individual test files
  frontmostTests = import ./frontmost.nix { inherit pkgs karabiner-lib; };

  typesConditionsTests = import ./types/conditions_test.nix {
    conditions = karabiner-lib.types.conditions;
  };

  # typesModifiersTests = import ./types/modifiers_test.nix {
  #   modifiers = karabiner-lib.types.modifiers;
  # };

  # Combine all test cases into a single attribute set
  allTests = typesConditionsTests; # // typesModifiersTests;

in
allTests
