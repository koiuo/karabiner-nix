# Assume lib, types, mkOption, mkValid, optional, required,
# fromEventType, postedEventType, conditionType are defined.
# { lib, fromEventType, postedEventType, conditionType, ... }:
# let inherit (lib) types mkOption; mkValid = ...; optional = ...; required = ...; in { ... }
{ lib }:

let
  inherit (builtins) mkOption;
  inherit (lib) types;

  /**
    Options for the 'global' configuration section.
  */
  globalOptions = {
    check_for_updates_on_startup = mkOption {
      type = types.bool;
      default = true;
    };
    show_in_menu_bar = mkOption {
      type = types.bool;
      default = true;
    };
    show_profile_name_in_menu_bar = mkOption {
      type = types.bool;
      default = false;
    };
    ask_for_confirmation_before_quitting = mkOption {
      type = types.bool;
      default = true;
    };
    unsafe_ui = mkOption {
      type = types.bool;
      default = false;
      description = "Enable potentially unsafe UI features (use with caution).";
    };
    # Add other global options as needed
  };
  /**
    Nix type for the 'global' configuration section.
  */
  global = types.submodule { options = globalOptions; };

  # --- Manipulator ---
  # (Represents a single entry in a complex modifications rule)

  /**
    Options for manipulator-specific parameters (timeouts etc.). Structure can vary.
  */
  manipulatorParametersOptions = types.attrsOf (
    types.oneOf [
      types.int
      types.bool
    ]
  ); # Allow basic types, adjust if needed
  /**
    Type for manipulator-specific parameters.
  */
  manipulatorParameters = types.submodule { freeformType = manipulatorParametersOptions; };

  /**
    Options for a single manipulator definition.
  */
  manipulatorOptions = {
    description = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional description for the manipulator.";
    };
    type = mkOption {
      type = types.nullOr (
        types.enum [
          "basic"
          "mouse_motion_to_scroll"
        ]
      );
      default = "basic";
      description = "Manipulator type.";
    };
    from = mkOption {
      type = fromEventType;
      description = "The event(s) that trigger this manipulator.";
    };
    to = mkOption {
      type = types.nullOr (types.listOf postedEventType);
      default = null;
      description = "Events posted when 'from' is triggered.";
    };
    to_if_alone = mkOption {
      type = types.nullOr (types.listOf postedEventType);
      default = null;
      description = "Events posted if 'from' key is pressed and released alone.";
    };
    to_if_held_down = mkOption {
      type = types.nullOr (types.listOf postedEventType);
      default = null;
      description = "Events posted if 'from' key is held down.";
    };
    to_after_key_up = mkOption {
      type = types.nullOr (types.listOf postedEventType);
      default = null;
      description = "Events posted after the 'from' key is released.";
    };
    parameters = mkOption {
      type = types.nullOr manipulatorParameters;
      default = null;
      description = "Manipulator-specific parameters (e.g., timeouts).";
    };
    conditions = mkOption {
      type = types.nullOr (types.listOf conditionType);
      default = null;
      description = "Conditions required for this manipulator to be active.";
    };
    # Add other specific manipulator options (e.g., for mouse_motion_to_scroll) if needed
  };
  /**
    Nix type for a single manipulator definition.
  */
  manipulator = types.submodule { options = manipulatorOptions; };

  /**
    Creates a validated manipulator definition.
  */
  mkManipulator =
    args:
    let
      # Required args
      from = required "from" args;
      # Optional args with defaults provided by mkOption
      description = optional "description" args null;
      type = optional "type" args "basic"; # Handled by mkOption default usually
      to = optional "to" args null;
      to_if_alone = optional "to_if_alone" args null;
      to_if_held_down = optional "to_if_held_down" args null;
      to_after_key_up = optional "to_after_key_up" args null;
      parameters = optional "parameters" args null;
      conditions = optional "conditions" args null;
    in
    mkValid manipulatorOptions {
      inherit
        description
        type
        from
        to
        to_if_alone
        to_if_held_down
        to_after_key_up
        parameters
        conditions
        ;
    };

  # --- Complex Modifications Rule ---

  /**
    Options for a complex modifications rule (group of manipulators).
  */
  complexRuleOptions = {
    description = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional description for the rule.";
    };
    manipulators = mkOption {
      type = types.listOf manipulator;
      default = [ ];
      description = "List of manipulators in this rule.";
    };
  };
  /**
    Nix type for a complex modifications rule.
  */
  complexRule = types.submodule { options = complexRuleOptions; };

  /**
    Creates a validated complex modifications rule.
  */
  mkComplexRule =
    args:
    let
      manipulators = required "manipulators" args; # Rule needs manipulators
      description = optional "description" args null;
    in
    mkValid complexRuleOptions {
      inherit description manipulators;
    };

  # --- Complex Modifications Section (in Profile) ---

  /**
    Options for global complex modification parameters.
  */
  complexParametersOptions = {
    # Using freeform for flexibility; define known ones for stricter validation
    # Example: "basic.to_if_alone_timeout_milliseconds" = mkOption { type = types.int; default = 1000; };
  } // lib.warn "Using freeform parameters for complex modifications." { };
  freeformType = types.oneOf [
    types.int
    types.bool
    types.float
  ]; # Adjust allowed types
  /**
    Type for global complex modification parameters.
  */
  complexParameters = types.submodule {
    freeformType = freeformType; # Allow any matching key=value
    options = complexParametersOptions; # Define specific known ones here
  };

  /**
    Options for the 'complex_modifications' section within a profile.
  */
  complexModificationsOptions = {
    parameters = mkOption {
      type = complexParameters;
      default = { };
      description = "Global parameters for complex modifications.";
    };
    rules = mkOption {
      type = types.listOf complexRule;
      default = [ ];
      description = "List of complex modification rules.";
    };
    # Potentially add 'fn_function_keys' here too if applicable separate from profile level? Check docs.
  };
  /**
    Nix type for the 'complex_modifications' section.
  */
  complexModifications = types.submodule { options = complexModificationsOptions; };

  # --- Simple Modification / Fn Function Key ---

  /**
    Options defining the simple 'from' part (key only, no modifiers/simultaneous).
  */
  simpleFromKeyOptions = {
    key_code = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
    consumer_key_code = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
    pointing_button = mkOption {
      type = types.nullOr types.str;
      default = null;
    };
  };
  /**
    Type for the simple 'from' part. Checks exactly one key is set.
  */
  simpleFromKey = types.submodule {
    options = simpleFromKeyOptions;
    check =
      cfg:
      let
        eventKeys = [
          "key_code"
          "consumer_key_code"
          "pointing_button"
        ];
        countSet = builtins.foldl' (
          acc: key: if builtins.hasAttr key cfg && cfg.${key} != null then acc + 1 else acc
        ) 0 eventKeys;
      in
      if countSet == 1 then
        true
      else
        throw "Simple modification 'from' must contain exactly one of: ${lib.concatStringsSep ", " eventKeys}";
  };

  /**
    Options for a simple modification or fn_function_key mapping.
  */
  simpleModificationOptions = {
    from = mkOption {
      type = simpleFromKey;
      description = "The single key/button to map from.";
    };
    to = mkOption {
      # 'to' in simple mods is usually just key codes, consumer keys, or pointing buttons
      # Define a simpler 'simplePostedEvent' type if needed, or use postedEventType if structure is identical
      # Using list of strings as a common simple case for key codes:
      type = types.listOf types.str;
      # Or for more complex simple 'to' events:
      # type = types.listOf simplePostedEventType;
      description = "The key(s) or event(s) to map to.";
      example = [ "left_shift" ];
    };
  };
  /**
    Nix type for a simple modification or fn_function_key mapping.
  */
  simpleModification = types.submodule { options = simpleModificationOptions; };
  /**
    Alias for clarity, uses the same structure.
  */
  fnFunctionKey = simpleModification;

  /**
    Creates a validated simple modification mapping.
  */
  mkSimpleModification =
    args:
    let
      from = required "from" args;
      to = required "to" args;
    in
    mkValid simpleModificationOptions { inherit from to; };

  /**
    Creates a validated fn_function_key mapping.
  */
  mkFnFunctionKey = mkSimpleModification; # Alias

  # --- Device Override ---

  /**
    Options defining device identifiers.
  */
  deviceIdentifierOptions = {
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
    # location_id = mkOption { type = types.nullOr types.int; default = null; }; # Deprecated?
  };
  /**
    Type for device identifiers.
  */
  deviceIdentifier = types.submodule { options = deviceIdentifierOptions; };

  /**
    Options for a device-specific override entry.
  */
  deviceOptions = {
    # Renamed from deviceOverrideOptions for consistency
    identifiers = mkOption {
      type = deviceIdentifier;
      description = "Device identifying properties. Required.";
    };
    ignore = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "Ignore this device completely.";
    };
    disable_built_in_keyboard_if_exists = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "Disable built-in keyboard when this device is connected.";
    };
    manipulate_caps_lock_led = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "Allow Karabiner to control the Caps Lock LED for this device.";
    };
    simple_modifications = mkOption {
      type = types.nullOr (types.listOf simpleModification);
      default = null;
      description = "Device-specific simple modifications.";
    };
    fn_function_keys = mkOption {
      type = types.nullOr (types.listOf fnFunctionKey);
      default = null;
      description = "Device-specific fn-key modifications.";
    };
    # Add other device-specific options if needed
  };
  /**
    Nix type for a device-specific override entry.
  */
  device = types.submodule { options = deviceOptions; }; # Renamed from deviceOverrideType

  /**
    Creates a validated device override configuration.
  */
  mkDevice =
    args:
    let
      identifiers = required "identifiers" args;
      ignore = optional "ignore" args null;
      disable_built_in_keyboard_if_exists = optional "disable_built_in_keyboard_if_exists" args null;
      manipulate_caps_lock_led = optional "manipulate_caps_lock_led" args null;
      simple_modifications = optional "simple_modifications" args null;
      fn_function_keys = optional "fn_function_keys" args null;
    in
    mkValid deviceOptions {
      inherit
        identifiers
        ignore
        disable_built_in_keyboard_if_exists
        manipulate_caps_lock_led
        simple_modifications
        fn_function_keys
        ;
    };

  # --- Virtual HID Keyboard Settings ---

  /**
    Options for the virtual HID keyboard settings.
  */
  virtualKeyboardOptions = {
    caps_lock_delay_milliseconds = mkOption {
      type = types.int;
      default = 0;
      description = "Delay for caps lock activation.";
    };
    keyboard_type = mkOption {
      type = types.str;
      default = "ansi";
      description = "Virtual keyboard layout type (e.g., 'ansi', 'iso', 'jis').";
    };
    country_code = mkOption {
      type = types.int;
      default = 0;
      description = "HID country code.";
    };
    # Add indicate_sticky_modifier_keys_state? Check docs.
  };
  /**
    Nix type for the virtual HID keyboard settings.
  */
  virtualKeyboard = types.submodule { options = virtualKeyboardOptions; };

  # --- Profile ---

  /**
    Options defining a single profile.
  */
  profileOptions = {
    name = mkOption {
      type = types.str;
      description = "Name of the profile. Required.";
    };
    selected = mkOption {
      type = types.bool;
      default = false;
      description = "Whether this profile is currently selected (only one should be true). Required.";
    };
    complex_modifications = mkOption {
      type = types.nullOr complexModifications;
      default = null;
      description = "Complex modifications for this profile.";
    };
    simple_modifications = mkOption {
      type = types.nullOr (types.listOf simpleModification);
      default = null;
      description = "Simple modifications for this profile.";
    };
    fn_function_keys = mkOption {
      type = types.nullOr (types.listOf fnFunctionKey);
      default = null;
      description = "Fn-key mappings for this profile.";
    };
    devices = mkOption {
      type = types.nullOr (types.listOf device);
      default = null;
      description = "Device-specific overrides for this profile.";
    };
    virtual_hid_keyboard = mkOption {
      type = types.nullOr virtualKeyboard;
      default = null;
      description = "Virtual keyboard settings for this profile.";
    };
    # parameters = mkOption { ... }; # Profile specific basic parameters? Check docs.
  };
  /**
    Nix type for a single profile.
  */
  profile = types.submodule { options = profileOptions; };

  /**
    Creates a validated profile configuration.
  */
  mkProfile =
    args:
    let
      name = required "name" args;
      selected = required "selected" args;
      complex_modifications = optional "complex_modifications" args null;
      simple_modifications = optional "simple_modifications" args null;
      fn_function_keys = optional "fn_function_keys" args null;
      devices = optional "devices" args null;
      virtual_hid_keyboard = optional "virtual_hid_keyboard" args null;
    in
    mkValid profileOptions {
      inherit
        name
        selected
        complex_modifications
        simple_modifications
        fn_function_keys
        devices
        virtual_hid_keyboard
        ;
    };

  # --- Root Configuration ---

  /**
    Options for the root karabiner.json configuration object.
  */
  karabinerJsonOptions = {
    global = mkOption {
      type = global;
      default = { };
      description = "Global settings.";
    };
    profiles = mkOption {
      type = types.listOf profile;
      default = [ ];
      description = "List of profiles.";
    };
  };
  /**
    Nix type for the root karabiner.json configuration object. Includes check for exactly one selected profile.
  */
  karabinerJson = types.submodule {
    options = karabinerJsonOptions;
    check =
      cfg:
      let
        selectedCount = builtins.foldl' (acc: p: if p.selected then acc + 1 else acc) 0 cfg.profiles;
      in
      if selectedCount == 1 then
        true
      else if selectedCount == 0 && cfg.profiles == [ ] then
        true # Allow empty profiles list
      else
        throw "Exactly one profile must have 'selected = true' (found ${toString selectedCount}).";
  };

  /**
    Creates a validated root karabiner.json configuration.
  */
  mkKarabinerJson =
    args:
    let
      global = optional "global" args { };
      profiles = optional "profiles" args [ ];
    in
    mkValid karabinerJsonOptions { inherit global profiles; };

in
{
  # --- Exported Types ---
  types = {
    # Root type
    inherit karabinerJson;
    # Top-level sections
    inherit global profile;
    # Profile subsections
    inherit
      complexModifications
      simpleModification
      fnFunctionKey
      device
      virtualKeyboard
      ;
    # Complex mod components
    inherit
      complexRule
      manipulator
      complexParameters
      manipulatorParameters
      ;
    # Device components
    inherit deviceIdentifier;
    # Simple mod components
    inherit simpleFromKey;
    # Assume fromEventType, postedEventType, conditionType are imported/available elsewhere
  };

  # --- Exported Options ---
  options = {
    inherit
      karabinerJsonOptions
      globalOptions
      profileOptions
      complexModificationsOptions
      simpleModificationOptions
      deviceOptions
      virtualKeyboardOptions
      complexRuleOptions
      manipulatorOptions
      complexParametersOptions
      manipulatorParametersOptions
      deviceIdentifierOptions
      simpleFromKeyOptions
      ;
  };

  # --- Exported Mk Functions ---
  mkFunctions = {
    inherit
      mkKarabinerJson
      mkProfile
      mkComplexRule
      mkManipulator
      mkSimpleModification
      mkFnFunctionKey
      mkDevice
      ;
    # Note: mk functions for smaller/simpler types like 'global', 'complexModifications'
    # 'virtualKeyboard', 'complexParameters' etc. are omitted as direct attrset definition
    # or defaulting via the parent type is usually sufficient.
  };
}
