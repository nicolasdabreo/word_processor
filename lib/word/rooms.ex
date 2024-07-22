defmodule Word.Rooms do
  alias Word.Rooms.NameGenerator
  alias Word.Rooms.Room
  alias Word.Rooms.RoomManager
  alias Word.Rooms.RoomState
  alias Word.Events

  defp topic(), do: "rooms"
  defp topic(%Room{name: name}), do: "rooms:#{name}"

  @spec subscribe() :: :ok | {:error, {:already_registered, pid()}}
  def subscribe(), do: Phoenix.PubSub.subscribe(Word.PubSub, topic())

  @spec subscribe(Room.t()) :: :ok | {:error, {:already_registered, pid()}}
  def subscribe(%Room{} = room), do: Phoenix.PubSub.subscribe(Word.PubSub, topic(room))

  @spec broadcast(String.t()) :: :ok | {:error, term()}
  def broadcast(event), do: Phoenix.PubSub.broadcast(Word.PubSub, topic(), {__MODULE__, event})

  @spec broadcast(Room.t(), String.t()) :: :ok | {:error, term()}
  def broadcast(%Room{} = room, event),
    do: Phoenix.PubSub.broadcast(Word.PubSub, topic(room), {__MODULE__, event})

  def list_rooms() do
    RoomManager.list_rooms()
  end

  def get_room(room_name) do
    RoomManager.get_room(room_name)
  end

  def create_room() do
    room_name = NameGenerator.generate()
    {:ok, pid} = RoomManager.start_room(room_name)

    broadcast(%Events.RoomCreated{
      room_name: room_name
    })

    %Room{name: room_name, pid: pid, state: ""}
  end

  def close_room(%Room{name: _name}) do
    :ok
  end

  def insert_text(%Room{pid: pid} = room, position, new_text) do
    {_prev_state, new_state} = RoomState.insert(pid, position, new_text)

    broadcast(
      room,
      %Events.TextInserted{
        inserted_text: new_text,
        inserted_at: position
      }
    )

    %{room | state: new_state}
  end

  def delete_text(%Room{pid: pid} = room, text_to_delete) do
    {_prev_state, new_state} = RoomState.delete(pid, text_to_delete)

    broadcast(
      room,
      %Events.TextDeleted{
        deleted_text: text_to_delete
      }
    )

    %{room | state: new_state}
  end

  def replace_text(%Room{pid: pid} = room, substring, replacement_text) do
    {_prev_state, new_state} = RoomState.replace(pid, substring, replacement_text)

    broadcast(
      room,
      %Events.TextReplaced{
        query_text: substring,
        replaced_with: replacement_text
      }
    )

    %{room | state: new_state}
  end

  def search_text(%Room{name: _name}, _search_query) do
    :ok
  end
end
