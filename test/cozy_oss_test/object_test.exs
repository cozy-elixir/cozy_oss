defmodule CozyOSS.ObjectTest do
  use ExUnit.Case
  alias CozyOSS.Config
  alias CozyOSS.Object

  test "creates a %Config{} struct" do
    conditions = [
      ["eq", "$key", "lenna.png"],
      ["eq", "$x-oss-object-acl", "private"],
      ["content-length-range", 1, 1024 * 1024 * 5]
    ]

    config =
      Config.new!(%{
        host: "...",
        access_key_id: "...",
        access_key_secret: "..."
      })

    result = Object.sign_post_object_policy(config, conditions, 3600)

    assert Map.has_key?(result, :policy)
    assert Map.has_key?(result, :signature)
  end
end
