defmodule Word.EventLog do
  @moduledoc """
  Defines Event structs for use for the log and the PubSub interface for
  pubbing and subbing to the log
  """

  defp topic(room_name), do: "rooms:#{room_name}"

  def subscribe(room_name) do
    Phoenix.PubSub.subscribe(Word.PubSub, topic(room_name))
  end

  def broadcast(event, room_name) do
    Phoenix.PubSub.broadcast(Word.PubSub, topic(room_name), {__MODULE__, event})
  end

  defmodule Events.TextInserted do
    defstruct raw_text: nil, inserted_text: nil, inserted_at: nil, processed_text: nil
  end

  defmodule Events.TextReplaced do
    defstruct raw_text: nil, query_text: nil, replaced_with: nil, processed_text: nil
  end

  defmodule Events.TextDeleted do
    defstruct raw_text: nil, deleted_text: nil, processed_text: nil
  end

  defmodule Events.TextSearched do
    defstruct query_text: nil, processed_text: nil, result: nil
  end
end
