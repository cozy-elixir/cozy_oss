defmodule CozyOSS.ExampleSdkTest do
  use ExUnit.Case

  defmodule FileStore do
    @moduledoc """
    Provides basic API to operate files.
    """

    alias CozyOSS.Config

    def put_file(path, data) when is_binary(path) and is_binary(data) do
      response =
        config()
        |> CozyOSS.build(%{
          bucket: bucket(),
          object: path,
          method: "PUT",
          path: Path.join("/", path),
          body: data
        })
        |> CozyOSS.request()

      with {:ok, 200, _headers, _body} <- response do
        {:ok, path}
      end
    end

    def get_file(path) when is_binary(path) do
      response =
        config()
        |> CozyOSS.build(%{
          bucket: bucket(),
          object: path,
          method: "GET",
          path: Path.join("/", path)
        })
        |> CozyOSS.request()

      with {:ok, 200, _headers, body} <- response do
        {:ok, body}
      end
    end

    def delete_file(path) when is_binary(path) do
      response =
        config()
        |> CozyOSS.build(%{
          bucket: bucket(),
          object: path,
          method: "DELETE",
          path: Path.join("/", path)
        })
        |> CozyOSS.request()

      with {:ok, 204, _headers, _body} <- response do
        {:ok, path}
      end
    end

    defp bucket() do
      System.fetch_env!("COZY_OSS_BUCKET")
    end

    defp config() do
      :demo
      |> Application.fetch_env!(__MODULE__)
      |> Config.new!()
    end
  end

  setup do
    Application.put_env(:demo, __MODULE__.FileStore, %{
      host: System.fetch_env!("COZY_OSS_HOST"),
      access_key_id: System.fetch_env!("COZY_OSS_ACCESS_KEY_ID"),
      access_key_secret: System.fetch_env!("COZY_OSS_ACCESS_KEY_SECRET")
    })

    :ok
  end

  test "an exmample SDK - FileStore works" do
    image_binary =
      __DIR__
      |> Path.join("example_sdk_test/files/lenna.png")
      |> File.read!()

    remote_path = "/images/lenna.png"

    assert {:ok, _path} = FileStore.put_file(remote_path, image_binary)
    assert {:ok, _data} = FileStore.get_file(remote_path)
    assert {:ok, _path} = FileStore.delete_file(remote_path)
  end
end
