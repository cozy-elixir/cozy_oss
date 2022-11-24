defmodule CozyOSS.Object do
  @moduledoc """
  Provides object related helpers.
  """

  import CozyOSS.Crypto, only: [hmac_sha1: 2]
  alias CozyOSS.Config

  @doc """
  Signs policy for PostObject, and returns the encoded policy and its signature.

  See more at [PostObject](https://www.alibabacloud.com/help/en/object-storage-service/latest/postobject) in
  the official documentation.

  ## Examples

      conditions = [
        ["eq", "$key", "lenna.png"],
        ["eq", "$x-oss-object-acl", "private"],
        ["content-length-range", 1, 1024 * 1024 * 5]
      ]

      sign_post_object_policy(config, conditions, 3600)

  """
  @spec sign_post_object_policy(Config.t(), list(), pos_integer()) :: %{
          policy: String.t(),
          signature: String.t()
        }
  def sign_post_object_policy(%Config{} = config, conditions, expiration_in_seconds)
      when is_list(conditions) and is_integer(expiration_in_seconds) do
    policy = %{
      expiration: get_expiration(expiration_in_seconds),
      conditions: conditions
    }

    encoded_policy =
      policy
      |> CozyOSS.json_library().encode!()
      |> Base.encode64()

    %{
      policy: encoded_policy,
      signature: hmac_sha1(encoded_policy, config.access_key_secret)
    }
  end

  defp get_expiration(seconds) do
    DateTime.utc_now()
    |> DateTime.add(seconds, :second)
    |> DateTime.truncate(:second)
    |> DateTime.to_iso8601()
  end
end
