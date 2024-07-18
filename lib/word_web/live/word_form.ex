defmodule WordWeb.WordForm do
  @moduledoc """
  An Ecto schemaless changeset, great for validating data and converting to Phoenix
  forms when you don't have traditional struct/changeset database persistence set up.

  Great for forms like sorting/filtering/searching too
  """

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

  @doc """
  Parses form params against the spec and returns a struct/changeset for converting
  back to form state.
  """
  def parse(params) do
    {@defaults, @fields}
    |> cast(params, Map.keys(@fields), empty_values: [])
    |> validate_required([:prompt, :position, :replace])
    |> apply_action(:insert)
  end
end
