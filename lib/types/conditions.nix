{
  lib,
  util ? (import ./util.nix { inherit lib; }),
}:

let
  inherit (lib) types mkOption;
  inherit (util)
    removeNulls
    mkValid
    optional
    required
    ;

  frontmost_application_if = "frontmost_application_if";
  frontmost_application_unless = "frontmost_application_unless";
  device_if = "device_if";
  device_unless = "device_unless";
  keyboard_type_if = "keyboard_type_if";
  keyboard_type_unless = "keyboard_type_unless";
  input_source_if = "input_source_if";
  input_source_unless = "input_source_unless";
  variable_if = "variable_if";
  variable_unless = "variable_unless";

  frontmostApplicationOptions = {
    type = mkOption {
      type = types.enum [
        frontmost_application_if
        frontmost_application_unless
      ];
      description = "Condition based on the frontmost application.";
    };
    description = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional description for the condition.";
    };
    bundle_identifiers = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = "List of regexes to match bundle identifiers.";
      example = [ "^com\\.apple\\.finder$" ];
    };
    file_paths = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = "List of application file paths (regex allowed).";
    };
  };

  deviceOptions = {
    type = mkOption {
      type = types.enum [
        device_if
        device_unless
      ];
      description = "Condition type: device_if or device_unless.";
    };
    description = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional description for the condition.";
      example = "My external keyboard";
    };
    identifiers = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            vendor_id = mkOption {
              type = types.nullOr types.int;
              default = null;
            };
            product_id = mkOption {
              type = types.nullOr types.int;
              default = null;
            };
            is_keyboard = mkOption {
              type = types.nullOr types.bool;
              default = null;
            };
            is_pointing_device = mkOption {
              type = types.nullOr types.bool;
              default = null;
            };
            is_touch_bar = mkOption {
              type = types.nullOr types.bool;
              default = null;
            };
            is_built_in_keyboard = mkOption {
              type = types.nullOr types.bool;
              default = null;
            };
          };
        }
      );
      description = "List of device identifying properties. Required.";
      example = [
        {
          vendor_id = 1133;
          product_id = 49177;
        }
      ];
    };
  };

  keyboardTypeOptions = {
    type = mkOption {
      type = types.enum [
        keyboard_type_if
        keyboard_type_unless
      ];
      description = "Condition type: keyboard_type_if or keyboard_type_unless.";
    };
    description = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional description for the condition.";
    };
    keyboard_types = mkOption {
      type = types.listOf types.str;
      description = "List of keyboard type strings (e.g., 'ansi', 'iso'). Required.";
      example = [ "ansi" ];
    };
  };

  inputSourceOptions = {
    type = mkOption {
      type = types.enum [
        input_source_if
        input_source_unless
      ];
      description = "Condition type: input_source_if or input_source_unless.";
    };
    description = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional description for the condition.";
    };
    input_sources = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            language = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Language code regex (e.g., '^en$').";
            };
            input_source_id = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Input source ID regex (e.g., '^com\\.apple\\.keylayout\\.US$').";
            };
            input_mode_id = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Input mode ID regex.";
            };
          };
        }
      );
      description = "List of input source properties. Required.";
      example = [ { language = "^en$"; } ];
    };
  };

  variableOptions = {
    type = mkOption {
      type = types.enum [
        variable_if
        variable_unless
      ];
      description = "Condition type: variable_if or variable_unless.";
    };
    description = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional description for the condition.";
    };
    name = mkOption {
      type = types.str;
      description = "The name of the variable to check. Required.";
      example = "my_custom_mode";
    };
    value = mkOption {
      type =
        with types;
        oneOf [
          bool
          int
          str
        ];
      description = "The value to compare the variable against. Required.";
      example = 1;
    };
  };
in
{
  /**
    Nix type definition for a Karabiner `frontmost_application_if` or `frontmost_application_unless` condition.
  */
  frontmostApplication = types.submodule { options = frontmostApplicationOptions; };

  /**
    Creates a validated `frontmost_application_if` condition attrset.

    # Inputs

    `bundle_identifiers`
    : Optional list of bundle ID regexes (e.g., `["^com\.apple\.finder$"]`). Matched against the frontmost application's bundle identifier.

    `file_paths`
    : Optional list of file path regexes. Matched against the frontmost application's executable path.

    `description`
    : Optional string description.
  */
  mkFrontmostApplicationIf =
    args:
    let
      bundle_identifiers = optional "bundle_identifiers" args null;
      file_paths = optional "file_paths" args null;
      description = optional "description" args null;
    in
    mkValid frontmostApplicationOptions {
      type = "frontmost_application_if"; # Corrected: Added quotes
      inherit bundle_identifiers file_paths description;
    };

  /**
    Creates a validated `frontmost_application_unless` condition attrset.

    # Inputs

    `bundle_identifiers`
    : Optional list of bundle ID regexes (e.g., `["^com\.apple\.finder$"]`). Matched against the frontmost application's bundle identifier.

    `file_paths`
    : Optional list of file path regexes. Matched against the frontmost application's executable path.

    `description`
    : Optional string description.
  */
  mkFrontmostApplicationUnless =
    args:
    let
      bundle_identifiers = optional "bundle_identifiers" args null;
      file_paths = optional "file_paths" args null;
      description = optional "description" args null;
    in
    mkValid frontmostApplicationOptions {
      type = "frontmost_application_unless"; # Corrected: Added quotes
      inherit bundle_identifiers file_paths description;
    };

  /**
    Nix type definition for a Karabiner `device_if` or `device_unless` condition.
  */
  device = types.submodule { options = deviceOptions; };

  /**
    Creates a validated `device_if` condition attrset.

    # Inputs

    `identifiers`
    : Required list of device identifier attrsets. Example: `[{ vendor_id = 1133; product_id = 49177; }]`

    `description`
    : Optional string description.
  */
  mkDeviceIf =
    args:
    let
      identifiers = required "identifiers" args;
      description = optional "description" args null;
    in
    mkValid deviceOptions {
      type = "device_if"; # Corrected: Added quotes
      inherit identifiers description;
    };

  /**
    Creates a validated `device_unless` condition attrset.

    # Inputs

    `identifiers`
    : Required list of device identifier attrsets. Example: `[{ vendor_id = 1133; product_id = 49177; }]`

    `description`
    : Optional string description.
  */
  mkDeviceUnless =
    args:
    let
      identifiers = required "identifiers" args;
      description = optional "description" args null;
    in
    mkValid deviceOptions {
      type = "device_unless"; # Corrected: Added quotes
      inherit identifiers description;
    };

  /**
    Nix type definition for a Karabiner `keyboard_type_if` or `keyboard_type_unless` condition.
  */
  keyboardType = types.submodule { options = keyboardTypeOptions; };

  /**
    Creates a validated `keyboard_type_if` condition attrset.

    # Inputs

    `keyboard_types`
    : Required list of keyboard type strings (e.g., `[ansi, "iso"]`).

    `description`
    : Optional string description.
  */
  mkKeyboardTypeIf =
    args:
    let
      keyboard_types = required "keyboard_types" args;
      description = optional "description" args null;
    in
    mkValid keyboardTypeOptions {
      type = "keyboard_type_if"; # Corrected: Added quotes
      inherit keyboard_types description;
    };

  /**
    Creates a validated `keyboard_type_unless` condition attrset.

    # Inputs

    `keyboard_types`
    : Required list of keyboard type strings (e.g., `[ansi, "iso"]`).

    `description`
    : Optional string description.
  */
  mkKeyboardTypeUnless =
    args:
    let
      keyboard_types = required "keyboard_types" args;
      description = optional "description" args null;
    in
    mkValid keyboardTypeOptions {
      type = "keyboard_type_unless"; # Corrected: Added quotes
      inherit keyboard_types description;
    };

  /**
    Nix type definition for a Karabiner `input_source_if` or `input_source_unless` condition.
  */
  inputSource = types.submodule { options = inputSourceOptions; };

  /**
    Creates a validated `input_source_if` condition attrset.

    # Inputs

    `input_sources`
    : Required list of input source attrsets. Example: `[{ language = ^en$; }]`

    `description`
    : Optional string description.
  */
  mkInputSourceIf =
    args:
    let
      input_sources = required "input_sources" args;
      description = optional "description" args null;
    in
    mkValid inputSourceOptions {
      type = "input_source_if"; # Corrected: Added quotes
      inherit input_sources description;
    };

  /**
    Creates a validated `input_source_unless` condition attrset.

    # Inputs

    `input_sources`
    : Required list of input source attrsets. Example: `[{ language = ^en$; }]`

    `description`
    : Optional string description.
  */
  mkInputSourceUnless =
    args:
    let
      input_sources = required "input_sources" args;
      description = optional "description" args null;
    in
    mkValid inputSourceOptions {
      type = "input_source_unless"; # Corrected: Added quotes
      inherit input_sources description;
    };

  /**
    Nix type definition for a Karabiner `variable_if` or `variable_unless` condition.
  */
  variableCondition = types.submodule { options = variableOptions; };

  /**
     Creates a validated `variable_if` condition attrset.

    `name`
    : Required string name of the variable.

    `value`
    : Required value to compare against (integer, boolean, or string).

    `description`
    : Optional string description.
  */
  mkVariableIf =
    args:
    let
      name = required "name" args;
      value = required "value" args;
      description = optional "description" args null;
    in
    mkValid variableOptions {
      type = "variable_if"; # Corrected: Added quotes
      inherit name value description;
    };

  /**
    Creates a validated `variable_unless` condition attrset.

    # Inputs

    `name`
    : Required string name of the variable.

    `value`
    : Required value to compare against (integer, boolean, or string).

    `description`
    : Optional string description.
  */
  mkVariableUnless =
    args:
    let
      name = required "name" args;
      value = required "value" args;
      description = optional "description" args null;
    in
    mkValid variableOptions {
      type = "variable_unless";
      inherit name value description;
    };

}
