defmodule Word.Rooms do
  alias Word.Rooms.NameGenerator

  defp topic(), do: "rooms"

  def subscribe() do
    Phoenix.PubSub.subscribe(Word.PubSub, topic())
  end

  def broadcast(event) do
    Phoenix.PubSub.broadcast(Word.PubSub, topic(), {__MODULE__, event})
  end

  def create_room() do
    room_name = NameGenerator.generate()

    case Registry.lookup(Word.RoomRegistry, room_name) do
      [] ->
        Word.Agent.start_link(room_name)

      _ ->
        :ok
    end

    room_name
  end

  def get_room(name) do
    case Registry.lookup(Word.RoomRegistry, name) do
      [{_, pid}] ->
        {pid, name, Word.Agent.current_state(pid)}

      [] ->
        :error
    end
  end

  def list_rooms() do
    DynamicSupervisor.which_children(Word.RoomSupervisor) |> IO.inspect()
  end
end
