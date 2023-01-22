# CozyOSS

[![Hex.pm](https://img.shields.io/hexpm/v/cozy_oss.svg)](https://hex.pm/packages/cozy_oss)

> An SDK builder for RESTful API of Aliyun OSS / Alibaba Cloud OSS.

This package is an SDK builder. It provides utilities to reduce the cost of creating an SDK, such as:

- building request
- signing request
- converting the XML in the response to a map with snake-cased keys
- ...

It doesn't provide one-to-one mapping against the RESTful API of Aliyun OSS / Alibaba Cloud OSS. See the reason in [FAQ](#faq).

## A Plan

This package will be migrated as the `OSS` spec of [CozyAliyunOpenAPI](https://github.com/cozy-elixir/cozy_aliyun_open_api) in the future.

## Installation

Add `cozy_oss` to the list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cozy_oss, "~> <version>"}
  ]
end
```

## Usage

Suppose we want to create an SDK for manipulating files.

First, we create a module:

```elixir
defmodule Demo.FileStore do
  @moduledoc """
  Provides basic API to operate files.

  This module reads configs from following environment variables:

  + `FILE_STORE_OSS_HOST`
  + `FILE_STORE_OSS_ACCESS_KEY_ID`
  + `FILE_STORE_OSS_ACCESS_KEY_SECRET`
  + `FILE_STORE_OSS_BUCKET`

  """

  alias CozyOSS.Config

  def put_file(path, data) when is_binary(path) and is_binary(data) do
    response =
      config()
      |> CozyOSS.build!(%{
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
      |> CozyOSS.build!(%{
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
      |> CozyOSS.build!(%{
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
```

Then, put the configurations into `config/runtime.exs`:

```elixir
config :demo, Demo.FileStore,
  host: System.fetch_env!("FILE_STORE_OSS_HOST"),
  access_key_id: System.fetch_env!("FILE_STORE_OSS_ACCESS_KEY_ID"),
  access_key_secret: System.fetch_env!("FILE_STORE_OSS_ACCESS_KEY_SECRET"),
  bucket: System.fetch_env!("FILE_STORE_OSS_BUCKET")
```

Check out this [test](https://github.com/cozy-elixir/cozy_oss/tree/master/test/cozy_oss_test.exs) for a working example.

For more information, see the [documentation](https://hexdocs.pm/cozy_oss).

## FAQ

### Why not providing one-to-one mapping against the RESTful API?

Because:

- It's hard to do the mapping automatically:
  - The official API documentation isn't structured data.
  - It's hard to parse and map them to API requests.
- It's hard to do the mapping manually:
  - It's a tedius work.
  - It's error-prone.

In real apps, it's rare that all the API provided by OSS are required. In general, only a few API are required. So, mapping what is required is acceptable.

The simpler, the better.

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
