{
  lib,
  modifier ? (import ./modifier.nix { inherit lib; }),
  util ? (import ./util.nix { inherit lib; }),
}:
let
  inherit (lib) types mkOption;
  inherit (util) mkValid required optional;

  modifiersOptions = {
    mandatory = mkOption {
      type = types.nullOr (types.listOf modifier.type);
      default = null;
      description = "List of modifier keys that must be pressed.";
      example = [
        "left_shift"
        "left_control"
      ];
    };
    optional = mkOption {
      type = types.listOf modifier.type;
      default = [ "any" ];
      description = "List of modifier keys that can optionally be pressed. Use ['any'] for any combination.";
      example = [ "any" ];
    };
  };

  modifiers = types.submodule { options = modifiersOptions; };

  keyCodeOptions = {
    key_code = mkOption {
      type = types.oneOf [
        types.str
        types.int
      ];
      description = "The key code that triggers the event. Required.";
      example = "spacebar";
    };
    modifiers = mkOption {
      type = types.nullOr modifiers;
      default = null;
      description = "Optional modifiers.";
    };
  };

  consumerKeyCodeOptions = {
    consumer_key_code = mkOption {
      type = types.str;
      description = "The consumer key code that triggers the event. Required.";
      example = "volume_increment";
    };
    modifiers = mkOption {
      type = types.nullOr modifiers;
      default = null;
      description = "Optional modifiers.";
    };
  };

in
rec {
  inherit modifiers;

  mkModifiers =
    args:
    let
      mandatory = required "mandatory" args;
      optional = util.optional "optional" args [ "any" ];
    in
    mkValid modifiersOptions { inherit mandatory optional; };

  /**
    Type for a 'from' event triggered by a specific key code.
  */
  keyCode = types.submodule { options = keyCodeOptions; };

  /**
    Creates a validated 'from' event triggered by a key_code.

    # Inputs

    `key_code`
    : int or str key code

    `modifiers`
    : use mkModifiers
  */
  mkKeyCode =
    args:
    let
      key_code = required "key_code" args;
      modifiers = optional "modifiers" args null;
    in
    mkValid keyCodeOptions { inherit key_code modifiers; };

  /**
    Type for a 'from' event triggered by a consumer key code.
  */
  consumerKeyCode = types.submodule { options = consumerKeyCodeOptions; };

  /**
    Creates a validated 'from' event triggered by a consumer_key_code.

    # Inputs

    `consumer_key_code`
    : str key code

    `modifiers`
    : use mkModifiers
  */
  mkConsumerKeyCode =
    args:
    let
      consumer_key_code = required "consumer_key_code" args.consumer_key_code;
      modifiers = optional "modifiers" args null;
    in
    mkValid consumerKeyCodeOptions { inherit consumer_key_code modifiers; };

  /**
    Nix type definition for a complete Karabiner 'from' event object.
    It must be one of the specific 'from' event types.
  */
  type = types.oneOf [
    keyCode
    consumerKeyCode
  ];
}
