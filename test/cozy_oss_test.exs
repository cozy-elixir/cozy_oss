defmodule CozyOSSTest do
  use ExUnit.Case
  alias CozyOSS.Config
  doctest CozyOSS

  test "build and request an API" do
    config =
      Config.new!(%{
        host: System.fetch_env!("COZY_OSS_HOST"),
        access_key_id: System.fetch_env!("COZY_OSS_ACCESS_KEY_ID"),
        access_key_secret: System.fetch_env!("COZY_OSS_ACCESS_KEY_SECRET")
      })

    bucket = System.fetch_env!("COZY_OSS_BUCKET")

    assert {:ok, _} =
             config
             |> CozyOSS.build(%{
               bucket: bucket,
               object: "hello.png",
               method: "GET",
               path: "/hello.png"
             })
             |> CozyOSS.request()
  end
end
