defmodule CozyOSSTest do
  use ExUnit.Case
  doctest CozyOSS

  defmodule FileStore do
    @moduledoc """
    An example module provides basic API to operate files.
    """

    alias CozyOSS.Config

    def put_file(path, data) when is_binary(path) and is_binary(data) do
      response =
        config()
        |> CozyOSS.build!(
          %{
            bucket: bucket(),
            object: path,
            method: "PUT",
            path: Path.join("/", path),
            body: data
          },
          # sign by header
          sign_by: :header
        )
        |> CozyOSS.request()

      with {:ok, 200, _headers, _body} <- response do
        {:ok, path}
      end
    end

    def get_file(path) when is_binary(path) do
      response =
        config()
        |> CozyOSS.build!(
          %{
            bucket: bucket(),
            object: path,
            method: "GET",
            path: Path.join("/", path)
          },
          # sign by url
          sign_by: :url
        )
        |> CozyOSS.request()

      with {:ok, 200, _headers, body} <- response do
        {:ok, body}
      end
    end

    def delete_file(path) when is_binary(path) do
      response =
        config()
        |> CozyOSS.build!(
          %{
            bucket: bucket(),
            object: path,
            method: "DELETE",
            path: Path.join("/", path)
          }
          # by default, sign by header
          # sign_by: :header
        )
        |> CozyOSS.request()

      with {:ok, 204, _headers, _body} <- response do
        {:ok, path}
      end
    end

    def get_public_url(path) when is_binary(path) do
      config()
      |> CozyOSS.build!(
        %{
          bucket: bucket(),
          object: path,
          method: "GET",
          path: Path.join("/", path),
          headers: %{
            # a normal user has no ability to generate these header, so we skip check them by setting
            # them to "" or nil.
            "content-md5" => "",
            "content-type" => ""
          }
        },
        sign_by: :url,
        expiration_in_seconds: 300
      )
      # to_url!/1 requires the request is signed by URL.
      |> CozyOSS.to_url!()
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

  describe "an exmaple SDK - FileStore" do
    test "manages files" do
      image_binary =
        __DIR__
        |> Path.join("files/lenna.png")
        |> File.read!()

      remote_path = "/temporary/lenna.png"

      assert {:ok, _path} = FileStore.put_file(remote_path, image_binary)
      assert {:ok, _data} = FileStore.get_file(remote_path)
      assert {:ok, _path} = FileStore.delete_file(remote_path)
    end

    test "generates a signed URL which can be accessed in Web browser" do
      image_binary =
        __DIR__
        |> Path.join("files/lenna.png")
        |> File.read!()

      remote_path = "/persistent/lenna.png"

      assert {:ok, path} = FileStore.put_file(remote_path, image_binary)

      url = FileStore.get_public_url(path)
      assert {:ok, {{'HTTP/1.1', 200, 'OK'}, _header, _body}} = :httpc.request(url)
    end
  end
end
