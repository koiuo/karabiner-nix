{ }:

{
  assertThrows =
    e:
    let
      eval = (builtins.tryEval (builtins.toJSON e));
    in
    {
      expr = eval.success;
      expected = false;
    };

}
