# tests/frontmost.nix
# Contains tests specifically for the frontmostApplicationCondition type and DSL.
{ pkgs, karabiner-lib }:

let
  # Alias for convenience
  lib = pkgs.lib;
  dsl = karabiner-lib.dsl;
  types = karabiner-lib.types;

  # Helper to check if a value conforms to the type
  checkType =
    value: type:
    let
      m = lib.evalModules {
        modules = [
          {
            options.test = lib.mkOption { inherit type; };
            config.test = value;
          }
        ];
      };
    in
    builtins.tryEval (builtins.deepSeq m m);

in
{
  testOk = {
    expr = true;
    expected = false;
  };

  # Test case 1: Valid 'if' condition using DSL
  testValidIf = {
    expr = rec {
      condition = dsl.mkFrontmostCondition {
        type = "if";
        bundles = [ ".*" ];
      };
      # typeOk = checkType condition types.frontmostApplicationCondition;
    };
    expected = {
      condition = {
        type = "frontmost_application_if";
        bundle_identifiers = [ ".*" ];
        file_paths = null;
      };
      typeOk = true;
    };
  };

  testValidIfBad = {
    expr = {
      typeOk = checkType { ba = "bar"; } types.thetype;
      # typeOk = true;
    };
    expected = {
      typeOk = true;
    };
  };

  # Test case 2: Valid 'unless' condition using DSL
  # testValidUnless =
  #   let condition = dsl.mkFrontmostCondition { type = "unless"; paths = [ "\\.nix" ]; };
  #   in lib.assertTrue (
  #        condition.type == "frontmost_application_unless" &&
  #        condition.bundle_identifiers == null &&
  #        condition.file_paths == [ "\\.nix" ] &&
  #        checkType condition types.frontmostApplicationCondition # Validate against the type
  #      );

  # # Test case 3: Default type is 'if'
  # testDefaultType =
  #   let condition = dsl.mkFrontmostCondition { bundles = [ "a" ]; }; # Omit type
  #   in lib.assertTrue (
  #        condition.type == "frontmost_application_if" &&
  #        checkType condition types.frontmostApplicationCondition
  #      );

  # Add more tests, e.g., for error conditions if desired (might need builtins.tryEval)
}
