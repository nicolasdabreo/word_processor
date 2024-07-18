defmodule Word.Agent do
  @moduledoc """
  Agent for storing the current state of processed text.

  Normally I would wrap this implementation in a protocol/behaviour and have a
  simple API module at the root level, this would allow for different implementations
  based on the data passed in or the compile time configuration of the app.

  Another example implementation might be utilising ets or Ecto for persistence.
  """

  use Agent

  alias Word.EventLog

  @doc """
  Starts an agent linked to the calling process.
  """
  def start_link(name) do
    opts = [
      name: {:via, Registry, {Word.RoomRegistry, name}}
    ]

    DynamicSupervisor.start_child(Word.RoomSupervisor, {__MODULE__, opts})
  end

  @doc """
  Retrieves the current state of the agent.
  """
  @spec current_state(String.t()) :: String.t()
  def current_state(room_name) do
    Agent.get(room_name, fn current_text -> current_text end)
  end

  @doc """
  Inserts the given substring at a position in the Word Processor's current state,
  broadcasting the new state of the Word Processor over PubSub.
  """
  @spec insert(String.t(), integer(), String.t()) :: :ok
  def insert(room_name, position, string) do
    {raw_text, processed_text} =
      Agent.get_and_update(room_name, fn current_state ->
        {before_state, after_state} = String.split_at(current_state, position)
        new_state = before_state <> string <> after_state

        {{current_state, new_state}, new_state}
      end)

    EventLog.broadcast(
      %EventLog.Events.TextInserted{
        inserted_text: string,
        inserted_at: position,
        raw_text: raw_text,
        processed_text: processed_text
      },
      room_name
    )
  end

  @doc """
  Deletes all matches of the given substring in the Word Processor's current state,
  broadcasting the new state of the Word Processor over PubSub.
  """
  @spec delete(String.t(), String.t()) :: :ok
  def delete(room_name, text_to_delete) do
    {raw_text, processed_text} =
      Agent.get_and_update(room_name, fn current_state ->
        new_state = String.replace(current_state, text_to_delete, "")
        {{current_state, new_state}, new_state}
      end)

    EventLog.broadcast(
      %EventLog.Events.TextDeleted{
        deleted_text: text_to_delete,
        raw_text: raw_text,
        processed_text: processed_text
      },
      room_name
    )
  end

  @doc """
  Replaces all matches of the given substring in the Word Processor's current state
  with a second substring, broadcasting the new state of the Word Processor over
  PubSub.
  """
  @spec replace(String.t(), String.t(), String.t()) :: :ok
  def replace(room_name, substring, replacement_text) do
    {raw_text, processed_text} =
      Agent.get_and_update(room_name, fn current_state ->
        new_state = String.replace(current_state, substring, replacement_text)
        {{current_state, new_state}, new_state}
      end)

    EventLog.broadcast(
      %EventLog.Events.TextReplaced{
        query_text: substring,
        replaced_with: replacement_text,
        raw_text: raw_text,
        processed_text: processed_text
      },
      room_name
    )
  end

  @doc """
  Searches for the given substring in the Word Processor's current state, the
  success/failure of a given search is broadcast over PubSub.
  """
  @spec search(String.t(), String.t()) :: :ok
  def search(room_name, substring) do
    {current_text, result} =
      Agent.get(room_name, fn current_state ->
        {current_state, String.contains?(current_state, substring)}
      end)

    EventLog.broadcast(
      %EventLog.Events.TextSearched{
        query_text: substring,
        processed_text: current_text,
        result: result
      },
      room_name
    )
  end
end
