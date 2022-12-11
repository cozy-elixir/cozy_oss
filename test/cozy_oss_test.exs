defmodule CozyOSSTest do
  use ExUnit.Case
  doctest CozyOSS

  @image_binary __DIR__
                |> Path.join("files/lenna.png")
                |> File.read!()

  defmodule FileStore do
    @moduledoc """
    An example module provides basic API to operate files.
    """

    alias CozyOSS.Config
    alias CozyOSS.Object

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

    def get_access_url(path) when is_binary(path) do
      config()
      |> CozyOSS.build!(
        %{
          bucket: bucket(),
          object: path,
          method: "GET",
          path: Path.join("/", path),
          headers: %{
            # a normal user has no ability to generate these headers, so we skip checking them by
            # setting them to "" or nil.
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

    @acl "private"
    @max_size_in_bytes 1024 * 1024 * 100
    @expiration_in_seconds 1800
    def presign_file(path) when is_binary(path) do
      config = config()

      %{host: host, access_key_id: access_key_id} = config

      conditions = [
        ["eq", "$key", path],
        ["eq", "$x-oss-object-acl", @acl],
        ["content-length-range", 1, @max_size_in_bytes]
      ]

      %{policy: policy, signature: signature} =
        Object.sign_post_object_policy(config, conditions, @expiration_in_seconds)

      %{
        method: "POST",
        url: "https://#{host}",
        key: path,
        acl: @acl,
        access_key_id: access_key_id,
        policy: policy,
        signature: signature
      }
    end

    defp bucket() do
      :demo
      |> Application.fetch_env!(__MODULE__)
      |> Keyword.fetch!(:bucket)
    end

    defp config() do
      :demo
      |> Application.fetch_env!(__MODULE__)
      |> Enum.into(%{})
      |> Config.new!()
    end
  end

  setup do
    Application.put_env(:demo, __MODULE__.FileStore,
      host: System.fetch_env!("COZY_OSS_HOST"),
      access_key_id: System.fetch_env!("COZY_OSS_ACCESS_KEY_ID"),
      access_key_secret: System.fetch_env!("COZY_OSS_ACCESS_KEY_SECRET"),
      bucket: System.fetch_env!("COZY_OSS_BUCKET")
    )

    :ok
  end

  describe "an exmaple SDK - FileStore" do
    test "manages files" do
      remote_path = "temporary/lenna.png"

      assert {:ok, _path} = FileStore.put_file(remote_path, @image_binary)
      assert {:ok, _data} = FileStore.get_file(remote_path)
      assert {:ok, _path} = FileStore.delete_file(remote_path)
    end

    test "generates a signed URL which can be accessed in Web browser" do
      remote_path = "persistent/lenna.png"

      assert {:ok, path} = FileStore.put_file(remote_path, @image_binary)

      url = FileStore.get_access_url(path)
      assert {:ok, %{status: 200}} = Tesla.get(url)
    end

    test "presigns a URL for uploading file by PostObject" do
      alias Tesla.Multipart

      remote_path = "presign/lenna.png"

      %{
        url: url,
        method: _method,
        key: key,
        acl: acl,
        access_key_id: access_key_id,
        policy: policy,
        signature: signature
      } = FileStore.presign_file(remote_path)

      mp =
        Multipart.new()
        |> Multipart.add_field("key", key)
        |> Multipart.add_field("x-oss-object-acl", acl)
        |> Multipart.add_field("OSSAccessKeyId", access_key_id)
        |> Multipart.add_field("policy", policy)
        |> Multipart.add_field("Signature", signature)
        |> Multipart.add_file_content(@image_binary, "lenna.png")

      assert {:ok, %{status: 204}} = Tesla.post(url, mp)

      url = FileStore.get_access_url(remote_path)
      assert {:ok, %{status: 200}} = Tesla.get(url)
    end
  end
end
