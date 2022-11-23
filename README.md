# CozyOSS

> SDK builder for RESTful API of Aliyun OSS / Alibaba Cloud OSS.

This package is an SDK builder.

It provides utilities to reduce the cost of creating an SDK, such as:

- building request
- signing request
- ...

## Installation

Add `cozy_oss` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cozy_oss, "~> 0.1.0"}
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
  + `FILE_STORE_ACCESS_KEY_ID`
  + `FILE_STORE_ACCESS_KEY_SECRET`
  + `FILE_STORE_BUCKET`
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
```

Then, put the configurations into `config/runtime.exs`:

```elixir
config :demo, Demo.FileStore,
  %{
    host: System.fetch_env!("COZY_OSS_HOST"),
    access_key_id: System.fetch_env!("COZY_OSS_ACCESS_KEY_ID"),
    access_key_secret: System.fetch_env!("COZY_OSS_ACCESS_KEY_SECRET")
  }
```

Check out this [test](https://github.com/cozy-elixir/cozy_oss/tree/master/test/example_sdk_test.exs) for a working example.

For more information, see the [documentation](https://hexdocs.pm/cozy_oss).

## Why not providing one-to-one mapping against the RESTful API ?

`cozy_oss` doesn't provide one-to-one mapping against the RESTful API of Aliyun OSS / Alibaba Cloud OSS, beacuse:

- The official API documentation isn't structured data. It is impossible to parse and map them to API requests.
- It is tedious and error-prone to do the mapping manually.

Considering that I'm only doing this in my spare time, the simpler the better.

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
