import Meeseeks.XPath

defmodule SkygearWebScrapper do
  def main(path) when is_bitstring(path) do
    File.cwd!()
    |> Path.join(path)
    |> YamlElixir.read_from_file!()
    |> Config.from_map()
    |> SkygearWebScrapper.main()
  end

  def main(%Config{actions: actions}) do
    # hard coded
    container = %SkygearContainer{
      endpoint: "https://keymanager.skygeario.com/",
      api_key: "ed38b3f082144883902c68c3bad23d97"
    }

    {:ok, container} = SkygearContainer.login(container, %{"username" => "admin"}, "secret")

    for action <- actions do
      data = fetch_data(action)
      records = to_record(action.name, data)
      SkygearContainer.save(container, records)
    end
  end

  defp fetch_data(%Action{type: "single", url: url, selector: selector, mapper: mapper}) do
    body = HTTPoison.get!(url).body

    body
    |> Meeseeks.one(xpath(selector))
    |> to_data(mapper)
  end

  defp fetch_data(%Action{type: "multi", url: url, selector: selector, mapper: mapper}) do
    body = HTTPoison.get!(url).body

    body
    |> Meeseeks.all(xpath(selector))
    |> Enum.map(&to_data(&1, mapper))
  end

  defp to_data(result, mapper) when is_map(mapper) do
    Enum.reduce(mapper, %{}, fn {key, selector}, acc ->
      selector
      |> xpath
      |> (&Meeseeks.one(result, &1)).()
      |> Meeseeks.text()
      |> (&Map.put(acc, key, &1)).()
    end)
  end

  defp to_record(type, data) when is_list(data) do
    Enum.map(data, &to_record(type, &1))
  end

  defp to_record(type, data) do
    Enum.reduce(data, %Record{type: type}, fn {key, value}, acc ->
      case key do
        "_id" -> %{acc | id: value}
        _ -> %{acc | data: Map.put(acc.data, key, value)}
      end
    end)
  end
end
