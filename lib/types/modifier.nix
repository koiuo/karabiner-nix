{ lib }:

let
  inherit (lib) types;

  /**
    Modifiers supported by Karabiner
    https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/from/modifiers/
  */
  names = [
    "caps_lock"
    "left_command"
    "left_control"
    "left_option"
    "left_shift"
    "right_command"
    "right_control"
    "right_option"
    "right_shift"
    "fn"
    "command" # Either left command or right command is pressed
    "control" # Either left control or right control is pressed
    "option" # Either left option or right option is pressed
    "shift" # Either left shift or right shift is pressed
    "left_alt" # Alias of left_option (available since Karabiner-Elements 12.3.0)
    "left_gui" # Alias of left_command (available since Karabiner-Elements 12.3.0)
    "right_alt" # Alias of right_option (available since Karabiner-Elements 12.3.0)
    "right_gui" # Alias of right_command (available since Karabiner-Elements 12.3.0)
    "any" # Any modifiers
  ];
  all = builtins.foldl' (acc: elem: { "${elem}" = elem; } // acc) { } names;

in
{
  inherit names;
  type = types.enum names;
}
// all
