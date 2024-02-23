defmodule WPWeb.WordForm do
  import Ecto.Changeset

  @fields %{
    prompt: :string,
    position: :integer,
    replace: :string
  }

  @defaults %{
    prompt: nil,
    position: 0,
    replace: " "
  }

  def parse(params) do
    {@defaults, @fields}
    |> cast(params, Map.keys(@fields), empty_values: [])
    |> validate_required([:prompt, :position, :replace])
    |> apply_action(:insert)
  end

  def defaults(), do: @defaults
end
