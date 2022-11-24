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
    private: %{},
    meta: %{}
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

  @type private() :: %{optional(atom()) => term()}

  @type meta() :: %{optional(atom()) => term()}

  @type t :: %__MODULE__{
          scheme: scheme(),
          host: String.t() | nil,
          port: :inet.port_number(),
          method: method(),
          path: String.t(),
          query: query(),
          headers: headers(),
          body: body(),
          private: private(),
          meta: meta()
        }

  import CozyOSS.Crypto, only: [md5_hash: 1, hmac_sha1: 2]
  alias CozyOSS.Config
  alias CozyOSS.ApiSpec

  @default_expiration_in_seconds_for_signing_on_url 900

  @doc """
  Bulid a struct `%CozyOSS.ApiRequest{}` from `%CozyOSS.Config{}` and `%CozyOSS.ApiSpec{}`.

  This function has built-in signing support, and it's controlled by option `:sign_by`:

  + `sign_by: :header` - add signatures to request headers.
  + `sign_by: :url` - add signatures to URL.

  When using `sign_by: :url`, an extra option `:expiration_in_seconds` is supported. The default value
  is `#{inspect(@default_expiration_in_seconds_for_signing_on_url)}`.

  """
  @spec build!(Config.t(), ApiSpec.t(), keyword()) :: t()
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
    |> set_header_lazy("content-type", fn -> detect_content_type(req) end)
    |> set_header_lazy("date", fn -> gmt_now() end)
  end

  defp detect_content_type(%__MODULE__{} = req) do
    case Path.extname(req.path) do
      "." <> name -> MIME.type(name)
      _ -> "application/octet-stream"
    end
  end

  defp set_signature(%Config{} = config, %__MODULE__{} = req, opts) do
    sign_by = Keyword.get(opts, :sign_by, :header)
    req = set_meta(req, :sign_by, sign_by)

    case sign_by do
      :header -> set_signature_on_header(config, req)
      :url -> set_signature_on_url(config, req, opts)
      _ -> raise ArgumentError, "unknown :sign_by value - #{inspect(sign_by)}"
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

    part1 = [
      req.method,
      fetch_header!(req, "content-md5"),
      fetch_header!(req, "content-type"),
      fetch_header!(req, "date")
    ]

    part2 =
      Enum.reject(
        [
          canonicalize_oss_headers(headers),
          canonicalize_resource(bucket, object, sub_resources)
        ],
        &(&1 == "")
      )

    Enum.join(part1 ++ part2, "\n")
  end

  defp set_signature_on_url(%Config{} = config, %__MODULE__{} = req, opts) do
    expiration_in_seconds =
      Keyword.get(opts, :expiration_in_seconds, @default_expiration_in_seconds_for_signing_on_url)

    expires = get_expires(expiration_in_seconds)

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

    part1 = [
      req.method,
      fetch_header!(req, "content-md5"),
      fetch_header!(req, "content-type"),
      expires
    ]

    part2 =
      Enum.reject(
        [
          canonicalize_oss_headers(headers),
          canonicalize_resource(bucket, object, sub_resources)
        ],
        &(&1 == "")
      )

    Enum.join(part1 ++ part2, "\n")
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

  defp set_query(%__MODULE__{} = req, name, value)
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

  defp set_meta(%__MODULE__{} = req, name, value) do
    new_meta = Map.put(req.meta, name, value)
    %{req | meta: new_meta}
  end

  defp gmt_now() do
    now = DateTime.utc_now()
    Calendar.strftime(now, "%a, %d %b %Y %H:%M:%S GMT")
  end

  @doc false
  def to_url(%__MODULE__{} = req) do
    query = encode_query(req.query)

    %URI{
      scheme: req.scheme,
      host: req.host,
      port: req.port,
      path: req.path,
      query: query
    }
    |> URI.to_string()
  end

  defp encode_query(query) when query == %{}, do: nil
  defp encode_query(query) when is_map(query), do: URI.encode_query(query)

  @doc """
  Converts a request to a signed URL.
  """
  @spec to_url!(t()) :: binary()
  def to_url!(%__MODULE__{meta: %{sign_by: :url}} = req), do: to_url(req)

  def to_url!(%__MODULE__{}) do
    raise ArgumentError,
          "to_url!/1 only supports requests built by build!(config, api_spec, sign_by: :url)"
  end
end
