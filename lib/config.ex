defmodule Action do
  defstruct name: "", type: "", url: "", selector: "", mapper: %{}

  def from_map(%{
        "name" => name,
        "type" => type,
        "url" => url,
        "selector" => selector,
        "mapper" => mapper
      }) do
    %Action{
      :name => name,
      :type => type,
      :url => url,
      :selector => selector,
      :mapper => mapper
    }
  end
end

defmodule Config do
  defstruct actions: []

  def from_map(%{"actions" => actions}) do
    %Config{
      :actions => Enum.map(actions, &Action.from_map(&1))
    }
  end
end
