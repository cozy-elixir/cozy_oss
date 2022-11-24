defmodule CozyOSS.ApiClient.Finch do
  @moduledoc """
  Finch-based API client for CozyOSS.

      config :cozy_oss, :api_client, CozyOSS.ApiClient.Finch

  In order to use `Finch` API client, you must start `Finch` and provide a `:name`.
  Often in your supervision tree:

      children = [
        {Finch, name: CozyOSS.Finch}
      ]

  Or, in rare cases, dynamically:

      Finch.start_link(name: CozyOSS.Finch)

  If a name different from `CozyOSS.Finch` is used, or you want to use an existing Finch instance,
  you can provide the name via the config:

      config :cozy_oss,
        api_client: CozyOSS.ApiClient.Finch,
        finch_name: My.Custom.Name

  """

  require Logger
  alias CozyOSS.ApiRequest

  @behaviour CozyOSS.ApiClient

  @impl true
  def init do
    unless Code.ensure_loaded?(Finch) do
      Logger.error("""
      Could not find finch dependency.

      Please add :finch to your dependencies:

          {:finch, "~> 0.13"}

      Or set your own CozyOSS.ApiClient:

          config :cozy_oss, :api_client, MyAPIClient

      """)

      raise "missing finch dependency"
    end

    _ = Application.ensure_all_started(:finch)
    :ok
  end

  @impl true
  def request(%ApiRequest{} = req) do
    method = build_method(req)
    url = ApiRequest.to_url(req)
    headers = build_headers(req)
    body = build_body(req)

    request = Finch.build(method, url, headers, body)

    case Finch.request(request, finch_name()) do
      {:ok, response} ->
        {:ok, response.status, response.headers, response.body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_method(req), do: req.method

  defp build_headers(req) do
    Enum.map(req.headers, fn {k, v} ->
      {to_string(k), to_string(v)}
    end)
  end

  defp build_body(req), do: req.body

  defp finch_name do
    Application.get_env(:cozy_oss, :finch_name, CozyOSS.Finch)
  end
end
