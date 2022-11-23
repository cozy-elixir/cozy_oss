defmodule CozyOSS.ApiRequest do
  @moduledoc """
  Converts `%ApiSpec{}` to a `%ApiRequest{}`.
  """

  defstruct [
    :scheme,
    :host,
    :port,
    :method,
    :path,
    :query,
    :headers,
    :body,
    private: %{}
  ]

  @typedoc """
  Request scheme.
  """
  @type scheme() :: :https

  @typedoc """
  Request method.
  """
  @type method() :: String.t()

  @typedoc """
  Request path.
  """
  @type path() :: String.t()

  @typedoc """
  Optional request query.
  """
  @type query() :: %{
          optional(query_name :: String.t()) => query_value :: boolean() | number() | String.t()
        }

  @typedoc """
  Request headers.
  """
  @type headers() :: %{optional(header_name :: String.t()) => header_value :: String.t()}

  @typedoc """
  Optional request body.
  """
  @type body() :: iodata() | nil

  @type private_metadata() :: %{optional(atom()) => term()}

  @type t :: %__MODULE__{
          scheme: scheme(),
          host: String.t() | nil,
          port: :inet.port_number(),
          method: method(),
          path: String.t(),
          query: query(),
          headers: headers(),
          body: body(),
          private: %{}
        }

  alias CozyOSS.Config
  alias CozyOSS.ApiSpec

  @spec build!(Config.t(), ApiSpec.t(), keyword()) :: __MODULE__.t()
  def build!(%Config{} = config, %ApiSpec{} = api_spec, opts) do
    build_request(config, api_spec)
    |> set_essential_headers()
    |> then(&set_signature(config, &1, opts))
  end

  defp build_request(config, api_spec) do
    base_url = "https://#{config.host}"

    %{
      scheme: scheme,
      host: host,
      port: port
    } = parse_base_url(base_url)

    %{
      bucket: bucket,
      object: object,
      sub_resources: sub_resources,
      method: method,
      path: path,
      query: query,
      headers: headers,
      body: body
    } = api_spec

    %__MODULE__{
      scheme: scheme,
      host: host,
      port: port,
      method: method,
      path: path,
      query: query,
      headers: headers,
      body: body,
      private: %{
        bucket: bucket,
        object: object,
        sub_resources: sub_resources
      }
    }
  end

  defp parse_base_url(url) when is_binary(url) do
    url
    |> URI.parse()
    |> Map.take([:scheme, :host, :port])
  end

  defp set_essential_headers(%__MODULE__{} = req) do
    req
    |> set_header_lazy("content-md5", fn -> md5_hash(req.body) end)
    |> set_header_lazy("content-type", fn -> get_content_type(req) end)
    |> set_header_lazy("date", fn -> gmt_now() end)
  end

  defp get_content_type(_req) do
    "application/octet-stream"
  end

  defp set_signature(%Config{} = config, %__MODULE__{} = req, opts) do
    sign_on = Keyword.get(opts, :sign_on, :header)

    case sign_on do
      :header -> set_signature_on_header(config, req)
      :url -> set_signature_on_url(config, req, opts)
      _ -> raise ArgumentError, "unknown :sign_on value - #{inspect(sign_on)}"
    end
  end

  defp set_signature_on_header(%Config{} = config, %__MODULE__{} = req) do
    signature =
      req
      |> build_string_to_sign_for_header_signature()
      |> hmac_sha1(config.access_key_secret)

    set_header(req, "authorization", "OSS #{config.access_key_id}:#{signature}")
  end

  @doc false
  def build_string_to_sign_for_header_signature(%__MODULE__{} = req) do
    %{
      headers: headers,
      private: %{bucket: bucket, object: object, sub_resources: sub_resources}
    } = req

    [
      req.method,
      fetch_header!(req, "content-md5"),
      fetch_header!(req, "content-type"),
      fetch_header!(req, "date"),
      canonicalize_oss_headers(headers),
      canonicalize_resource(bucket, object, sub_resources)
    ]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
  end

  defp set_signature_on_url(%Config{} = config, %__MODULE__{} = req, opts) do
    five_minutes_in_seconds = 900
    expire_seconds = Keyword.get(opts, :expire_seconds, five_minutes_in_seconds)
    expires = get_expires(expire_seconds)

    signature =
      req
      |> build_string_to_sign_for_url_signature(expires)
      |> hmac_sha1(config.access_key_secret)

    req
    |> set_query("OSSAccessKeyId", config.access_key_id)
    |> set_query("Expires", expires)
    |> set_query("Signature", signature)
  end

  @doc false
  def build_string_to_sign_for_url_signature(%__MODULE{} = req, expires) do
    %{
      headers: headers,
      private: %{bucket: bucket, object: object, sub_resources: sub_resources}
    } = req

    [
      req.method,
      fetch_header!(req, "content-md5"),
      fetch_header!(req, "content-type"),
      expires,
      canonicalize_oss_headers(headers),
      canonicalize_resource(bucket, object, sub_resources)
    ]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
  end

  defp get_expires(expire_seconds) do
    DateTime.utc_now()
    |> DateTime.to_unix()
    |> Kernel.+(expire_seconds)
  end

  # creation of CanonicalizedOSSHeaders
  # https://www.alibabacloud.com/help/en/object-storage-service/latest/access-control-include-signatures-in-the-authorization-header#section-w2k-sw2-xdb
  @doc false
  def canonicalize_oss_headers(headers) when is_map(headers) do
    headers
    |> Enum.filter(fn {k, _v} -> String.match?(k, ~r/^x-oss-/i) end)
    |> Enum.sort_by(fn {k, _v} -> k end, :asc)
    |> Enum.map(fn
      {k, nil} -> to_string(k)
      {k, v} -> "#{k}:#{v}"
    end)
    |> Enum.join("\n")
  end

  # creation of CanonicalizedResource
  # https://www.alibabacloud.com/help/en/object-storage-service/latest/access-control-include-signatures-in-the-authorization-header#section-rvv-dx2-xdb
  @doc false
  def canonicalize_resource(bucket, object, sub_resources) do
    encoded_resource =
      cond do
        bucket && object -> Path.join(["/", bucket, object])
        bucket -> "/#{bucket}/"
        true -> "/"
      end

    encoded_sub_resource = encode_sub_resources(sub_resources)

    [
      encoded_resource,
      encoded_sub_resource
    ]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("?")
  end

  defp encode_sub_resources(sub_resources) do
    sub_resources
    |> Enum.sort_by(fn {k, _v} -> k end, :asc)
    |> Enum.map(fn
      {k, nil} -> to_string(k)
      {k, v} -> "#{k}=#{v}"
    end)
    |> Enum.join("&")
  end

  def set_query(%__MODULE__{} = req, name, value)
      when is_binary(name) do
    new_query = Map.put(req.query, name, value)
    %{req | query: new_query}
  end

  defp set_header(%__MODULE__{} = req, name, value)
       when is_binary(name) and is_binary(value) do
    name = String.downcase(name)
    new_headers = Map.put(req.headers, name, value)
    %{req | headers: new_headers}
  end

  defp set_header_lazy(%__MODULE__{} = req, name, fun)
       when is_binary(name) and is_function(fun, 0) do
    name = String.downcase(name)
    new_headers = Map.put_new_lazy(req.headers, name, fun)
    %{req | headers: new_headers}
  end

  defp fetch_header!(%__MODULE__{} = req, name) do
    Map.fetch!(req.headers, name)
  end

  @doc false
  def md5_hash(nil), do: md5_hash("")

  def md5_hash(data) do
    data
    |> then(&:crypto.hash(:md5, &1))
    |> Base.encode64()
  end

  @doc false
  def hmac_sha1(data, secret) do
    :crypto.mac(:hmac, :sha, secret, data)
    |> Base.encode64()
  end

  defp gmt_now() do
    now = DateTime.utc_now()
    Calendar.strftime(now, "%a, %d %b %Y %H:%M:%S GMT")
  end
end
