defmodule CozyOSS do
  @moduledoc """
  SDK builder for RESTful API of Aliyun OSS / Alibaba Cloud OSS.
  """

  alias __MODULE__.Config
  alias __MODULE__.ApiSpec
  alias __MODULE__.ApiRequest
  alias __MODULE__.ApiClient
  alias __MODULE__.Object

  @doc """
  Bulid a struct `%CozyOSS.ApiRequest{}`.

  This function has built-in signing support, and it's controlled by option `:sign_by`:

  + `sign_by: :header` (default) - add signatures to request headers.
  + `sign_by: :url` - add signatures to URL.

  When using `sign_by: :url`, an extra option `:expiration_in_seconds` is supported.

  See `CozyOSS.ApiRequest.build!/3` for more information.

  """
  @spec build!(Config.t(), ApiSpec.config()) :: any()
  def build!(%Config{} = config, api_spec_config, opts \\ []) do
    api_spec = ApiSpec.build!(api_spec_config)
    ApiRequest.build!(config, api_spec, opts)
  end

  defdelegate request(api_request), to: ApiClient

  defdelegate to_url!(api_request), to: ApiRequest

  defdelegate sign_post_object_policy(config, conditions, expiration_in_seconds), to: Object

  @doc false
  def json_library, do: Application.fetch_env!(:cozy_oss, :json_library)
end
