defmodule CozyOSS.Config do
  @enforce_keys [:host, :access_key_id, :access_key_secret]
  defstruct @enforce_keys

  @typedoc """
  One of following formats:

  + `<bucket name>.<endpoint>`, such as `example-bucket.oss-cn-hangzhou.aliyuncs.com`.
  + custom domain name, such as `www.example.com`.
  """
  @type host() :: String.t()

  @type config() :: %{
          host: host(),
          access_key_id: String.t(),
          access_key_secret: String.t()
        }

  @type t :: %__MODULE__{
          host: host(),
          access_key_id: String.t(),
          access_key_secret: String.t()
        }

  @spec new!(config()) :: __MODULE__.t()
  def new!(config) when is_map(config) do
    config
    |> validate_required_keys!()
    |> as_struct!()
  end

  defp validate_required_keys!(
         %{
           host: host,
           access_key_id: access_key_id,
           access_key_secret: access_key_secret
         } = config
       )
       when is_binary(host) and
              is_binary(access_key_id) and
              is_binary(access_key_secret) do
    config
  end

  defp validate_required_keys!(_config) do
    raise ArgumentError,
          "config :host, :access_key_id, :access_key_secret are required"
  end

  defp as_struct!(config) do
    default_struct = __MODULE__.__struct__()
    valid_keys = Map.keys(default_struct)
    config = Map.take(config, valid_keys)
    Map.merge(default_struct, config)
  end
end
