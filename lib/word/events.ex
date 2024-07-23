defmodule Word.Events do
  @moduledoc """
  ETS backed event log storage
  """

  alias :ets, as: ETS

  def init_table() do
    ETS.new(:events, [:duplicate_bag, :public, :named_table, read_concurrency: true])
  end

  def create_event(room_name, event) do
    ETS.insert(:events, {room_name, event})
  end

  def list_all_events(room_name) do
    ETS.lookup(:events, room_name)
    |> Enum.map(& elem(&1, 1))
  end

  defmodule TextInserted do
    defstruct raw_text: nil, inserted_text: nil, inserted_at: nil
  end

  defmodule TextReplaced do
    defstruct raw_text: nil, query_text: nil, replaced_with: nil
  end

  defmodule TextDeleted do
    defstruct raw_text: nil, deleted_text: nil
  end

  defmodule RoomCreated do
    defstruct room_name: nil
  end
end
