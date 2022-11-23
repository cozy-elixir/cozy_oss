defmodule CozyOSS.ApiClient do
  @moduledoc """
  Specification for a CozyOSS API client.

  It can be set to a client provided by CozyOSS, such as:

      config :cozy_oss, :api_client, CozyOSS.ApiClient.Finch

  Or, set it to your own API client, such as:

     config :cozy_oss, :api_client, MyApiClient

  """

  alias CozyOSS.ApiRequest

  @type status :: pos_integer()
  @type headers :: [{binary(), binary()}]
  @type body :: binary()

  @typedoc """
  The response of a request.
  """
  @type response() :: {:ok, status, headers, body} | {:error, term()}

  @doc """
  Callback to initialize the given API client.
  """
  @callback init() :: :ok

  @doc """
  Callback to send a request.
  """
  @callback request(ApiRequest.t()) :: response()

  @optional_callbacks init: 0

  @doc false
  def init do
    client = api_client()

    if Code.ensure_loaded?(client) and function_exported?(client, :init, 0) do
      :ok = client.init()
    end

    :ok
  end

  @doc false
  def request(%ApiRequest{} = req) do
    api_client().request(req)
  end

  defp api_client do
    Application.fetch_env!(:cozy_oss, :api_client)
  end
end
