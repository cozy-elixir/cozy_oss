defmodule CozyOSS.CryptoTest do
  use ExUnit.Case
  alias CozyOSS.Crypto

  test "md5_hash/1" do
    assert Crypto.md5_hash("0123456789") == "eB5eJF1ptWaXm4bijSPyxw=="
  end
end
