{
  conditions,
  util ? (import ./util.nix { }),
}:

let
  inherit (util) assertThrows;
in
{
  # frontmost_application

  testFrontmostAppIfSuccess = {
    expr = conditions.mkFrontmostApplicationIf {
      bundle_identifiers = [ "^com\\.apple\\.Safari$" ];
      description = "Safari Only";
    };
    expected = {
      type = "frontmost_application_if";
      bundle_identifiers = [ "^com\\.apple\\.Safari$" ];
      description = "Safari Only";
    };
  };

  testFrontmostAppUnlessSuccess = {
    expr = conditions.mkFrontmostApplicationUnless {
      file_paths = [ "^/Applications/" ];
    };
    expected = {
      type = "frontmost_application_unless";
      file_paths = [ "^/Applications/" ];
    };
  };

  testFrontmostAppIfInvalidType = assertThrows (
    conditions.mkFrontmostApplicationIf { bundle_identifiers = "not-a-list"; }
  );

  testFrontmostAppIfInvalidElementType = assertThrows (
    conditions.mkFrontmostApplicationIf {
      bundle_identifiers = [ 1 ];
    }
  );

  # device

  testDeviceIfSuccess =
    let
      ids = [
        {
          vendor_id = 1;
          product_id = 2;
          is_keyboard = true;
        }
      ];
    in
    {
      expr = conditions.mkDeviceIf {
        identifiers = ids;
        description = "Test KB";
      };
      expected = {
        type = "device_if";
        identifiers = ids;
        description = "Test KB";
      };
    };

  testDeviceUnlessSuccess =
    let
      ids = [ { is_pointing_device = true; } ];
    in
    {
      expr = conditions.mkDeviceUnless { identifiers = ids; };
      expected = {
        type = "device_unless";
        identifiers = ids;
      };
    };

  testDeviceIfInvalidIdentifierType = assertThrows (
    conditions.mkDeviceIf {
      identifiers = {
        vendor_id = 1;
      };
    }
  );

  testDeviceIfInvalidVendorIdType = assertThrows (
    conditions.mkDeviceIf { identifiers = [ { vendor_id = "123"; } ]; }
  );

  # Keyboard Type

  testKeyboardTypeIfSuccess =
    let
      typesList = [
        "ansi"
        "iso"
      ];
    in
    {
      expr = conditions.mkKeyboardTypeIf { keyboard_types = typesList; };
      expected = {
        type = "keyboard_type_if";
        keyboard_types = typesList;
      };
    };

  testKeyboardTypeUnlessSuccess =
    let
      typesList = [ "jis" ];
    in
    {
      expr = conditions.mkKeyboardTypeUnless {
        keyboard_types = typesList;
        description = "Not JIS";
      };
      expected = {
        type = "keyboard_type_unless";
        keyboard_types = typesList;
        description = "Not JIS";
      };
    };

  testKeyboardTypeIfMissingType = assertThrows (
    conditions.mkKeyboardTypeIf { description = "Missing type"; }
  );

  testKeyboardTypeIfInvalidType = assertThrows (
    conditions.mkKeyboardTypeIf { keyboard_types = [ 123 ]; }
  );

  # Input Source

  testInputSourceIfSuccess =
    let
      sources = [
        {
          language = "^en$";
          input_source_id = "com.apple.keylayout.ABC";
        }
      ];
    in
    {
      expr = conditions.mkInputSourceIf { input_sources = sources; };
      expected = {
        type = "input_source_if";
        input_sources = sources;
      };
    };

  testInputSourceUnlessSuccess =
    let
      sources = [ { input_mode_id = "roman"; } ];
    in
    {
      expr = conditions.mkInputSourceUnless {
        input_sources = sources;
        description = "Not Roman";
      };
      expected = {
        type = "input_source_unless";
        input_sources = sources;
        description = "Not Roman";
      };
    };

  testInputSourceIfMissingSources = assertThrows (
    conditions.mkInputSourceIf { description = "No sources"; }
  );

  testInputSourceIfInvalidSourceType = assertThrows (
    conditions.mkInputSourceIf { input_sources = [ { language = 123; } ]; }
  );

  # Variable

  testVariableIfSuccessInt = {
    expr = conditions.mkVariableIf {
      name = "mode";
      value = 1;
      description = "Mode 1";
    };
    expected = {
      type = "variable_if";
      name = "mode";
      value = 1;
      description = "Mode 1";
    };
  };

  testVariableUnlessSuccessBool = {
    expr = conditions.mkVariableUnless {
      name = "active";
      value = false;
    };
    expected = {
      type = "variable_unless";
      name = "active";
      value = false;
    };
  };

  testVariableIfSuccessStr = {
    expr = conditions.mkVariableIf {
      name = "state";
      value = "on";
    };
    expected = {
      type = "variable_if";
      name = "state";
      value = "on";
    };
  };

  testVariableIfMissingName = assertThrows (conditions.mkVariableIf { value = 1; });

  testVariableIfMissingValue = assertThrows (conditions.mkVariableIf { name = "test"; });

  testVariableIfInvalidNameType = assertThrows (
    conditions.mkVariableIf {
      name = 123;
      value = 1;
    }
  );

  testVariableIfInvalidValueType = assertThrows (
    conditions.mkVariableIf {
      name = "test";
      value = [ ];
    }
  );
}
