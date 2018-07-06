defmodule Record do
  defstruct type: nil, id: nil, data: %{}
end

defimpl Poison.Encoder, for: Record do
  def encode(%{type: type, id: id, data: data}, options) do
    map = %{"_id" => "#{type}/#{id}"}

    map
    |> Map.merge(data)
    |> Poison.Encoder.Map.encode(options)
  end
end

defmodule SkygearContainer do
  defstruct endpoint: "", api_key: "", access_token: ""

  defp ensure_record_id(record) do
    case record.id do
      nil -> %{record | id: UUID.uuid4()}
      _ -> record
    end
  end

  def save(container, records) do
    save(container, records, "")
  end

  def save(container, records, database_id) when is_list(records) do
    payload = %{
      "database_id" => database_id,
      "records" => records |> Enum.map(&ensure_record_id(&1))
    }

    SkygearContainer.send_action(container, "record:save", payload)
  end

  def login(container = %SkygearContainer{}, auth_data, password) do
    resp =
      send_action(container, "auth:login", %{
        "auth_data" => auth_data,
        "password" => password
      })

    case resp do
      %{"result" => %{"access_token" => access_token}} ->
        {:ok, %{container | access_token: access_token}}

      _ ->
        {:error, resp}
    end
  end

  def send_action(
        %SkygearContainer{endpoint: endpoint, api_key: api_key, access_token: access_token},
        action_name,
        params
      ) do
    action_url = String.replace(action_name, ":", "/")

    url =
      case String.ends_with?(endpoint, "/") do
        true -> "#{endpoint}#{action_url}"
        false -> "#{endpoint}/#{action_url}"
      end

    %{
      "action" => action_name,
      "access_token" => access_token,
      "api_key" => api_key,
    }
    |> Enum.filter(fn {_, v} -> v != nil end)
    |> Enum.into(params)
    |> (&Skygear.send_action(url, &1)).()
  end
end

defmodule Skygear do
  def send_action(url, payload) do
    headers = %{
      "Content-type" => "application/json",
      "Accept" => "application/json"
    }

    response = HTTPoison.post!(url, Poison.encode!(payload), headers, recv_timeout: 60000)
    Poison.decode!(response.body)
  end
end
