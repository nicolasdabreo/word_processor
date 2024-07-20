defmodule Word.Rooms.RoomState do
  @moduledoc """
  Agent for storing the current state of processed text.

  Normally I would wrap this implementation in a protocol/behaviour and have a
  simple API module at the root level, this would allow for different implementations
  based on the data passed in or the compile time configuration of the app.

  Another example implementation might be utilising ets or Ecto for persistence.
  """

  use Agent

  @doc """
  Starts an agent linked to the calling process.
  """
  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end)
  end

  @doc """
  Retrieves the current state of the agent.
  """
  @spec get(String.t()) :: String.t()
  def get(pid) do
    Agent.get(pid, fn current_text -> current_text end)
  end

  @doc """
  Inserts the given substring at a position in the Word Processor's current state,
  broadcasting the new state of the Word Processor over PubSub.
  """
  @spec insert(String.t(), integer(), String.t()) :: :ok
  def insert(pid, position, string) do
    Agent.get_and_update(pid, fn current_state ->
      {before_state, after_state} = String.split_at(current_state, position)
      new_state = before_state <> string <> after_state

      {{current_state, new_state}, new_state}
    end)
  end

  @doc """
  Deletes all matches of the given substring in the Word Processor's current state,
  broadcasting the new state of the Word Processor over PubSub.
  """
  @spec delete(String.t(), String.t()) :: :ok
  def delete(pid, text_to_delete) do
    Agent.get_and_update(pid, fn current_state ->
      new_state = String.replace(current_state, text_to_delete, "")
      {{current_state, new_state}, new_state}
    end)
  end

  @doc """
  Replaces all matches of the given substring in the Word Processor's current state
  with a second substring, broadcasting the new state of the Word Processor over
  PubSub.
  """
  @spec replace(String.t(), String.t(), String.t()) :: :ok
  def replace(pid, substring, replacement_text) do
    Agent.get_and_update(pid, fn current_state ->
      new_state = String.replace(current_state, substring, replacement_text)
      {{current_state, new_state}, new_state}
    end)
  end

  @doc """
  Searches for the given substring in the Word Processor's current state, the
  success/failure of a given search is broadcast over PubSub.
  """
  @spec search(String.t(), String.t()) :: :ok
  def search(pid, substring) do
    Agent.get(pid, fn current_state ->
      {current_state, String.contains?(current_state, substring)}
    end)
  end
end
