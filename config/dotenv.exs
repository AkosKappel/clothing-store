defmodule ClothingStore.DotEnv do
  @moduledoc false
  # Tiny .env reader for dev/test config: KEY=VALUE lines, # comments, no quoting rules.
  def load(path) do
    file_env =
      if File.exists?(path) do
        path
        |> File.read!()
        |> String.split("\n")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == "" or String.starts_with?(&1, "#")))
        |> Enum.flat_map(fn line ->
          case String.split(line, "=", parts: 2) do
            [k, v] -> [{String.trim(k), String.trim(v)}]
            _ -> []
          end
        end)
        |> Map.new()
      else
        %{}
      end

    fn key, default ->
      case System.get_env(key) || Map.get(file_env, key) do
        nil -> default
        "" -> default
        value -> value
      end
    end
  end
end
