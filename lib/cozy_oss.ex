defmodule CozyOSS do
  @moduledoc """
  SDK builder for RESTful API of Aliyun OSS / Alibaba Cloud OSS.
  """

  alias __MODULE__.Config
  alias __MODULE__.ApiSpec
  alias __MODULE__.ApiRequest
  alias __MODULE__.ApiClient

  @spec build(Config.t(), ApiSpec.config()) :: any()
  def build(%Config{} = config, api_spec_config, opts \\ []) do
    api_spec = ApiSpec.build!(api_spec_config)
    ApiRequest.build!(config, api_spec, opts)
  end

  @spec request(ApiRequest.t()) :: ApiClient.response()
  defdelegate request(api_request), to: ApiClient
end
