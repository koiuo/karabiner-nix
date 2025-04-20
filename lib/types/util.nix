{ lib }:

let
  removeNulls =
    arg:
    let
      f = lib.filterAttrs (_: v: v != null);
    in
    if lib.isAttrs arg then
      lib.mapAttrs (_: value: removeNulls value) (f arg)
    else if lib.isList arg then
      map removeNulls arg
    else
      arg;

  /**
    mkValid leverages lib.evalModules to ensure that config conforms to the type definition options.
  */
  mkValid =
    options: config:
    let
      moduleList = [ { inherit options config; } ];

      # Pass 'lib' via 'specialArgs' so it's available within mkOption definitions
      evaluated = lib.evalModules {
        modules = moduleList;
        specialArgs = { inherit lib; };
      };

      result = removeNulls evaluated.config;
    in
    result;

  # Nix evaluation order doesn't allow to catch errors thrown during argument bindings, which comes in handy during tests,
  # hence instead of
  #
  #   { foo, bar }: ...
  #
  # we need to resort to dirty hacks like
  #
  #   args: required "foo" arg

  optional =
    name: args: defaultValue:
    if builtins.hasAttr name args then args.${name} else defaultValue;

  required =
    name: args: if builtins.hasAttr name args then args.${name} else throw "${name} is required";
in
{
  inherit
    removeNulls
    mkValid
    optional
    required
    ;
}
