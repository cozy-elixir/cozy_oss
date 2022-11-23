defmodule CozyOSS.XML do
  @moduledoc """
  XML helpers.
  """
  def to_map!(xml_string) do
    with {:ok, map} <- SAXMap.from_string(xml_string) do
      to_snake_case(map)
    else
      _ ->
        raise ArgumentError, "invalid XML string"
    end
  end

  # Converts all the keys in a map to snake case.
  # If the map is a struct with no `Enumerable` implementation, the struct is considered to be a single value.
  #
  # The code is borrowed from:
  # https://github.com/johnnyji/proper_case/blob/9dc5462d458b767a995ae8b22f9b906e8e80e4a4/lib/proper_case.ex#L89
  defp to_snake_case(map) when is_map(map) do
    try do
      for {key, val} <- map,
          into: %{},
          do: {snake_case(key), to_snake_case(val)}
    rescue
      # not Enumerable
      Protocol.UndefinedError -> map
    end
  end

  defp to_snake_case(list) when is_list(list) do
    Enum.map(list, &to_snake_case/1)
  end

  defp to_snake_case(other), do: other

  defp snake_case(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> Macro.underscore()
  end

  defp snake_case(value) when is_number(value) do
    value
  end

  defp snake_case(value) when is_binary(value) do
    value
    |> String.replace(" ", "")
    |> Macro.underscore()
  end
end
