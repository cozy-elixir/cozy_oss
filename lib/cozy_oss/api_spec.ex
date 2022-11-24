defmodule CozyOSS.ApiSpec do
  @moduledoc """
  Describes the specification of an API.
  """

  @enforce_keys [
    :bucket,
    :object,
    :sub_resources,
    :method,
    :path,
    :query,
    :headers,
    :body
  ]
  defstruct bucket: nil,
            object: nil,
            sub_resources: %{},
            method: nil,
            path: nil,
            query: %{},
            headers: %{},
            body: nil

  @typedoc """
  API method.
  """
  @type method() :: String.t()

  @typedoc """
  API path.
  """
  @type path() :: String.t()

  @typedoc """
  API query.
  """
  @type query() :: %{
          optional(query_name :: String.t()) => query_value :: boolean() | number() | String.t()
        }

  @typedoc """
  API headers.
  """
  @type headers() :: %{optional(header_name :: String.t()) => header_value :: String.t()}

  @typedoc """
  Optional API body.
  """
  @type body() :: iodata() | nil

  @type config() :: %{
          method: method(),
          path: path(),
          query: query(),
          headers: headers(),
          body: body()
        }

  @type t :: %__MODULE__{
          method: method(),
          path: path(),
          query: query(),
          headers: headers(),
          body: body()
        }

  @spec build!(config()) :: t()
  def build!(config) when is_map(config) do
    config
    |> validate_required_keys!()
    |> normalize_config!()
    |> as_struct!()
  end

  defp validate_required_keys!(
         %{
           method: method,
           path: path
         } = config
       )
       when is_binary(method) and is_binary(path) do
    config
  end

  defp validate_required_keys!(_config) do
    raise ArgumentError,
          "key :method, :path are required in a spec"
  end

  defp normalize_config!(config) do
    Map.update!(config, :path, &add_prefix_slash/1)
  end

  defp add_prefix_slash(path) do
    Path.join("/", path)
  end

  defp as_struct!(config) do
    default_struct = __MODULE__.__struct__()
    valid_keys = Map.keys(default_struct)
    config = Map.take(config, valid_keys)
    Map.merge(default_struct, config)
  end
end
