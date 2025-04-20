{
  lib,
  modifier ? (import ./modifier.nix { inherit lib; }),
  util ? (import ./util.nix { inherit lib; }),
}:

# Assume lib, types, mkOption, and mkValid are defined in the surrounding scope.
# { lib }: let inherit (lib) types mkOption; mkValid = ...; in { ... }
let
  inherit (lib) types mkOption;
  inherit (util) mkValid required optional;

  # TODO clarify if can be used with anything but key-related options
  commonKeyOptions = {
    halt = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "If true, Karabiner stops processing subsequent 'to' events in the same list.";
    };
    lazy = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "Defers the execution of this event until other non-lazy events are done and modifiers are released.";
    };
    repeat = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "If true, the event repeats as long as the original 'from' key is held down.";
    };
    hold_down_milliseconds = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = "Holds the event (e.g., key press) down for the specified duration.";
    };
    modifiers = mkOption {
      type = types.nullOr (types.listOf modifier.type);
      default = null;
      description = "Apply temporary modifiers simultaneously with this event.";
    };
  };

  keyCodeOptions = commonKeyOptions // {
    key_code = mkOption {
      type = types.str;
      description = "The key code to post. Required.";
      example = "spacebar";
    };
  };

  consumerKeyCodeOptions = commonKeyOptions // {
    consumer_key_code = mkOption {
      type = types.str;
      description = "The consumer key code to post. Required.";
      example = "volume_increment";
    };
  };

  pointingButtonOptions = {
    # commonKeyOptions probaly don't work here
    pointing_button = mkOption {
      type = types.str;
      description = "The pointing button to post. Required.";
      example = "button1";
    };
  };

  selectInputSourceOptions = {
    select_input_source = mkOption {
      type = types.submodule {
        options = {
          language = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "en";
          };
          input_source_id = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "^com\\.apple\\.keylayout\\.US$";
          };
          input_mode_id = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
        };
      };
      example = {
        language = "^en$";
        input_source_id = "^com\\.apple\\.keylayout\\.US$";
        input_mode_id = "^com\\.apple\\.inputmethod\\.Japanese\\.Hiragana$";
      };
    };
  };

  setVariableOptions = {
    set_variable = mkOption {
      type = types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            description = "Variable name.";
            example = "my_mode";
          };
          value = mkOption {
            type =
              with types;
              oneOf [
                bool
                int
                str
              ];
            description = "Value to set (0, 1, true, false, string).";
            example = 1;
          };
        };
      };
      description = "Variable name and value (0, 1, true, false, string)";
      example = {
        name = "my_mode";
        value = true;
      };
    };
  };

  setNotificationMessageOptions = {
    set_notification_message = mkOption {
      type = types.submodule {
        options = {
          id = mkOption {
            type = types.str;
            description = "Unique ID for the notification.";
            example = "mode-change";
          };
          text = mkOption {
            type = types.str;
            description = "Text content of the notification.";
            example = "Mode Changed";
          };
        };
      };
      description = "Notification ID and text. Required.";
      example = {
        id = "mode-change";
        text = "Mode changed";
      };
    };
  };

  mouseKeyOptions = {
    mouse_key = mkOption {
      type = types.submodule {
        options = {
          x = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = "Horizontal movement distance.";
          };
          y = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = "Vertical movement distance.";
          };
          vertical_wheel = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = "Vertical scroll amount.";
          };
          horizontal_wheel = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = "Horizontal scroll amount.";
          };
          speed_multiplier = mkOption {
            type = types.nullOr types.float;
            default = null;
            description = "Multiplier for movement/scroll speed.";
          };
        };
      };
      description = "Mouse movement distance and scroll amount";
      example = {
        x = 5;
        y = 5;
      };
    };
  };

  shellCommandOptions = {
    shell_command = mkOption {
      type = types.str;
      description = "The shell command to execute. Required.";
      example = "open -a Finder";
    };
  };

  stickyModifierOptions = {
    sticky_modifier = mkOption {
      type = types.attrsOf (
        types.enum [
          "on"
          "off"
          "toggle"
        ]
      );
      description = "Modifier(s) and action (on/off/toggle). Required.";
      example = {
        left_shift = "toggle";
      };
    };
  };

  softwareFunctionOptions = {
    software_function = mkOption {
      type = types.raw;
      description = "Software function definition (structure varies). Required.";
      example = ''{ cg_event_double_click = { button = 1; }; }'';
    };
  };

in
rec {
  /**
    Type for a 'to' event posting a key code.
  */
  keyCode = types.submodule { options = keyCodeOptions; };

  /**
    Creates a validated 'to' event posting a key_code.
  */
  mkKeyCode =
    args:
    let
      key_code = required "key_code" args;
      halt = optional "halt" args null;
      lazy = optional "lazy" args null;
      repeat = optional "repeat" args null;
      hold_down_milliseconds = optional "hold_down_milliseconds" args null;
      modifiers = optional "modifiers" args null;
    in
    mkValid keyCodeOptions {
      inherit
        key_code
        halt
        lazy
        repeat
        hold_down_milliseconds
        modifiers
        ;
    };

  /**
    Type for a 'to' event posting a consumer key code.
  */
  consumerKeyCode = types.submodule { options = consumerKeyCodeOptions; };

  /**
    Creates a validated 'to' event posting a consumer_key_code.
  */
  mkConsumerKeyCode =
    args:
    let
      consumer_key_code = required "consumer_key_code" args;
      halt = optional "halt" args null;
      lazy = optional "lazy" args null;
      repeat = optional "repeat" args null;
      hold_down_milliseconds = optional "hold_down_milliseconds" args null;
      modifiers = optional "modifiers" args null;
    in
    mkValid consumerKeyCodeOptions {
      inherit
        consumer_key_code
        halt
        lazy
        repeat
        hold_down_milliseconds
        modifiers
        ;
    };

  /**
    Type for a 'to' event posting a pointing button.
  */
  pointingButton = types.submodule { options = pointingButtonOptions; };
  /**
    Creates a validated 'to' event posting a pointing_button.
  */
  mkPointingButton =
    args:
    let
      pointing_button = required "pointing_button" args; # Required
    in
    mkValid pointingButtonOptions { inherit pointing_button; };

  /**
    Type for a 'to' event selecting an input source.
  */
  selectInputSource = types.submodule { options = selectInputSourceOptions; };
  /**
    Creates a validated 'to' event selecting an input source.
  */
  mkSelectInputSource =
    args:
    let
      select_input_source = required "select_input_source" args;
    in
    mkValid selectInputSourceOptions { inherit select_input_source; };

  /**
    Type for a 'to' event setting a variable.
  */
  setVariable = types.submodule { options = setVariableOptions; };

  /**
    Creates a validated 'to' event setting a variable.
  */
  mkSetVariable =
    args:
    let
      set_variable = required "set_variable" args;
    in
    mkValid setVariableOptions { inherit set_variable; };

  /**
    Type for a 'to' event setting a notification message.
  */
  setNotificationMessage = types.submodule { options = setNotificationMessageOptions; };

  /**
    Creates a validated 'to' event posting a notification.
  */
  mkSetNotificationMessage =
    args:
    let
      set_notification_message = required "set_notification_message" args;
    in
    mkValid setNotificationMessageOptions { inherit set_notification_message; };

  /**
    Type for a 'to' event controlling the mouse.
  */
  mouseKey = types.submodule { options = mouseKeyOptions; };

  /**
    Creates a validated 'to' event controlling the mouse.
  */
  mkMouseKey =
    args:
    let
      mouse_key = required "mouse_key" args; # Required (should be the nested attrset { x=..., y=... })
      halt = optional "halt" args null;
      lazy = optional "lazy" args null;
      repeat = optional "repeat" args null;
      hold_down_milliseconds = optional "hold_down_milliseconds" args null;
      modifiers = optional "modifiers" args null;
    in
    mkValid mouseKeyOptions {
      inherit
        mouse_key
        halt
        lazy
        repeat
        hold_down_milliseconds
        modifiers
        ;
    };

  /**
    Type for a 'to' event executing a shell command.
  */
  shellCommand = types.submodule { options = shellCommandOptions; };

  /**
    Creates a validated 'to' event executing a shell_command.
  */
  mkShellCommand =
    args:
    let
      shell_command = required "shell_command" args;
    in
    mkValid shellCommandOptions { inherit shell_command; };

  /**
    Type for a 'to' event setting a sticky modifier.
  */
  stickyModifier = types.submodule { options = stickyModifierOptions; };

  /**
    Creates a validated 'to' event setting a sticky modifier.
  */
  mkStickyModifier =
    args:
    let
      # TODO validate that attr key is a valid modifier
      sticky_modifier = required "sticky_modifier" args; # Required (should be the nested attrset { modifier = action; })
    in
    mkValid stickyModifierOptions { inherit sticky_modifier; };

  /**
    Type for a 'to' event triggering a software function.
  */
  softwareFunction = types.submodule { options = softwareFunctionOptions; };

  /**
    Creates a validated 'to' event triggering a software function.
  */
  mkSoftwareFunction =
    args:
    let
      software_function = required "software_function" args; # Required (raw value)
    in
    mkValid softwareFunctionOptions { inherit software_function; };

  /**
    Nix type definition for a complete Karabiner 'to' event object.
    It must be one of the specific 'to' event types.
  */
  toEvent = types.oneOf [
    keyCode
    consumerKeyCode
    pointingButton
    shellCommand
    selectInputSource
    setVariable
    setNotificationMessage
    mouseKey
    stickyModifier
    softwareFunction
  ];

}
