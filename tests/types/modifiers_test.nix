{
  modifiers,
  utils ? (import ./utils.nix { }),
}:

let
  inherit (utils) assertThrows;
in
{
  testModifiersIfSuccess = {
    expr = modifiers.mkModifiers {
      mandatory = [ modifiers.names.control ];
      optional = [ modifiers.names.shift ];
    };
    expected = {
      mandatory = [ modifiers.names.control ];
      optional = [ modifiers.names.shift ];
    };
  };

}
