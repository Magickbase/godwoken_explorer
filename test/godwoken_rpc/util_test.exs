defmodule GodwokenRPC.UtilTest do
  use GodwokenExplorer.DataCase

  alias GodwokenRPC.Util

  describe "parse_polyjuice_args" do
    test "when is native transfer" do
      result =
        Util.parse_polyjuice_args(
          "ffffff504f4c590068bf00000000000000a007c2da51000000000000000000000000e867ce97461d310000000000000000000000715ab282b873b79a7be8b0e8c13c4e8966a52040"
        )

      assert result == [
               false,
               49000,
               90_000_000_000_000,
               906_000_000_000_000_000_000,
               0,
               "0x",
               "0x715ab282b873b79a7be8b0e8c13c4e8966a52040"
             ]
    end

    test "when is other polyjuice args" do
      result =
        Util.parse_polyjuice_args(
          "ffffff504f4c590000c076000000000001e40b540200000000000000000000000002000000000000000000000000000000000000"
        )

      assert result == [false, 7_782_400, 10_000_000_001, 512, 0, "0x", nil]
    end
  end
end
