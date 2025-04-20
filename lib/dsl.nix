{
  lib, # nixpkgs.lib
  types, # karabiner.lib.types
}:

let

  /**
    # Inputs

    `type`
    : "key_code" or "consumer_key_code"

    `eventOrKey`
    : object to coerce
  */
  _coerce =
    type: eventOrKey:
    if eventOrKey ? _ast_key then
      # already coerced
      eventOrKey
    else if (builtins.isString eventOrKey) || (builtins.isInt eventOrKey) then
      {
        _ast_key = true;
        "${type}" = eventOrKey;
        modifiers = [ ];
      }
    else
      throw "Can't coerce to ${type}: ${eventOrKey}";

  coerce = {
    consumer_key = eventOrKey: _coerce "consumer_key_code" eventOrKey;
    key = eventOrKey: _coerce "key_code" eventOrKey;
  };

  modify =
    modifier: event:
    with builtins;
    let
      modified =
        if event ? _ast_key then
          event // { modifiers = [ modifier ] ++ event.modifiers; }
        else if isFunction event then
          (x: modify modifier (event x))
        else
          modify modifier (coerce.key event);
    in
    modified;

  /**
    Contains a set of functions like control, left_command, etc..

    # Example

    control "x"

    control shift "x"
  */
  modifiers = builtins.foldl' (
    acc: elem: { "${elem}" = (prev: modify elem prev); } // acc
  ) { } types.modifier.names;

  # A friendlier version of split
  split = regex: str: builtins.filter builtins.isString (builtins.split regex str);

  # Parse simplified string representation of a skhd-like key chord into a typed structure
  parseSkhdChord =
    chord:
    let
      tokens = split " - " chord;
      event =
        if builtins.length tokens == 2 then
          {
            key_code = lib.strings.trim (builtins.elemAt tokens 1);
            modifiers = map lib.strings.trim (split " \\+ " (builtins.elemAt tokens 0));
          }
        else
          {
            key_code = lib.strings.trim chord;
            modifiers = [ ];
          };
    in
    event // { _ast_key = true; };

in
rec {

  #
  # Conditions
  #

  /**
    Apply conditions to a list of modifiers
  */
  when =
    conditions: modifiers:
    map (e: e // { conditions = (lib.flatten conditions); }) (lib.flatten modifiers);

  /**
    Reverse a condition
  */
  not =
    condition:
    if builtins.isFunction condition then
      (arg: not (condition arg))
    else
      let
        oldType = if condition ? type then condition.type else throw "not a condition: ${condition}";
        typeLength = builtins.stringLength oldType;
        type =
          if lib.strings.hasSuffix "_if" oldType then
            # replace _if with _unless
            (builtins.substring 0 (typeLength - 3) oldType) + "_unless"
          else
            # replace _unless with _if
            (builtins.substring 0 (typeLength - 7) oldType) + "_if";
      in
      condition // { inherit type; };

  /**
    Construct a `frontmost_application_if` condition
  */
  application =
    apps:
    let
      appsList = lib.flatten apps;
      bundle_identifiers = builtins.filter builtins.isString appsList;
      file_paths = map builtins.toString (builtins.filter builtins.isPath appsList);
    in
    types.conditions.mkFrontmostApplicationIf { inherit bundle_identifiers file_paths; };

  #
  # Monipulators
  #

  /**
    Parse manipulators from an attrset reminding skhd syntax

    Example
    ```
    {
       "control - x" = "left_command - x";
       "shift + control - x" = "shift + left_command - x";
    }
    ```
  */
  skhd =
    manipulatorsAttrset:
    lib.mapAttrsToList (
      fromChord: toChords:
      let
        # Parse the 'from' key string
        fromEvent = parseSkhdChord fromChord;
        from = types.from.mkKeyCode {
          inherit (fromEvent) key_code;
          modifiers.mandatory = fromEvent.modifiers;
        };

        # Parse each 'to' key string in the list
        to = map (chord: types.to.mkKeyCode (parseSkhdChord chord)) (lib.flatten toChords);
      in

      # Construct the final manipulator object for Karabiner
      #
      {
        inherit from to;
        type = "basic";
      }
    ) manipulatorsAttrset;

  bind =
    fromEventOrKey: toEventOrKey:
    let
      # If fromEventOrKey is a primitive, coerce it to key_code
      fromEvent = coerce.key fromEventOrKey;
      from = types.from.mkKeyCode {
        key_code = fromEvent.key_code;
        modifiers = types.from.mkModifiers { mandatory = fromEvent.modifiers; };
      };

      to = map (
        x:
        let
          # If toEventOrKey is a primitive, coerce it to key_code
          e = coerce.key x;
        in
        types.to.mkKeyCode { inherit (e) key_code modifiers; }
      ) (lib.flatten toEventOrKey);
    in
    {
      inherit from to;
    };

  complexModification = title: rulesSet: {
    title = title;
    rules = lib.mapAttrsToList (description: manipulators: {
      description = "${title}: ${description}";
      inherit manipulators;
    }) rulesSet;
  };

  # Example

  nix =
    with modifiers;
    complexModification "Nix" {
      "Slack" =
        when
          [
            (not application [
              "slack"
              /usr/bin/slack
            ])
          ]
          [
            (bind "home" (left_command "left_arrow"))
            (bind "end" (left_command "right_arrow"))
          ];
    };
}
// modifiers
