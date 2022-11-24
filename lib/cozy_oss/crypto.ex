defmodule CozyOSS.Crypto do
  @moduledoc false

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
end
