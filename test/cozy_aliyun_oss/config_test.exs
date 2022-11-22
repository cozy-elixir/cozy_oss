defmodule CozyAliyunOSS.ConfigTest do
  use ExUnit.Case
  alias CozyAliyunOSS.Config

  describe "new!/1" do
    test "creates a %Config{} struct" do
      assert %Config{host: _, access_key_id: _, access_key_secret: _} =
               Config.new!(%{
                 host: "...",
                 access_key_id: "...",
                 access_key_secret: "..."
               })
    end

    test "raises ArgumentError when required keys are missing" do
      assert_raise ArgumentError,
                   "config :host, :access_key_id, :access_key_secret are required",
                   fn ->
                     Config.new!(%{})
                   end
    end
  end
end
