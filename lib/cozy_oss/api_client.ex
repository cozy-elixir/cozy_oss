defmodule CozyOSS.ApiClient do
  @moduledoc """
  Specification for a CozyOSS API client.

  It can be set to a client provided by CozyOSS, such as:

      config :cozy_oss, :api_client, CozyOSS.ApiClient.Finch

  Or, set it to your own API client, such as:

      config :cozy_oss, :api_client, MyApiClient

  """

  alias CozyOSS.ApiRequest
  alias CozyOSS.XML

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

  @doc """
  Send a struct `%CozyOSS.ApiRequest{}` as an HTTP request by the given API client.

  When the `Content-Type` header of the response is `"application/xml"`, this function will try to convert
  the XML content to a map with snaked-cased keys.

  """
  @spec request(ApiRequest.t()) :: response()
  def request(%ApiRequest{} = req) do
    req
    |> api_client().request()
    |> maybe_to_map()
  end

  defp maybe_to_map({:ok, status, headers, body} = response) do
    case List.keyfind(headers, "content-type", 0) do
      {"content-type", "application/xml"} ->
        {:ok, status, headers, XML.to_map!(body)}

      _ ->
        response
    end
  end

  defp maybe_to_map(response), do: response

  defp api_client do
    Application.fetch_env!(:cozy_oss, :api_client)
  end
end
