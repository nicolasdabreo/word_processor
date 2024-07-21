defmodule Word.Rooms.RoomManager do
  alias Word.Rooms.Room
  alias Word.Rooms.RoomState
  alias Word.Rooms.RoomRegistry

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one, max_children: 100)
  end

  def start_room(name) do
    spec = %{
      id: name,
      start: {RoomState, :start_link, ["", name]},
      restart: :transient,
      type: :worker
    }

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, pid} ->
        {:ok, pid}

      error ->
        error
    end
  end

  def list_rooms do
    rooms = Registry.lookup(RoomRegistry, "rooms")

    for {_registering_pid, {name, room_pid}} <- rooms do
      state = RoomState.get(room_pid)
      %Room{pid: room_pid, name: name, state: state}
    end
  end

  def get_room(name) do
    Enum.find(list_rooms(), & &1.name == name)
  end

  def count_rooms() do
    Registry.count(RoomRegistry)
  end
end
