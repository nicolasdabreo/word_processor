defmodule Word.Rooms.RoomManager do
  alias Word.Rooms.Room
  alias Word.Rooms.RoomState
  alias Word.Rooms.RoomRegistry

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one, max_children: 10)
  end

  def start_room(name) do
    spec = %{
      id: name,
      start: {RoomState, :start_link, ["", name]},
      restart: :transient,
      type: :worker
    }

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  def list_rooms do
    rooms = Registry.lookup(RoomRegistry, "rooms")

    for {_registering_pid, {name, room_pid}} <- rooms do
      state = RoomState.get(room_pid)
      %Room{pid: room_pid, name: name, state: state}
    end
  end

  def get_room(name) do
    Registry.lookup(RoomRegistry, "rooms")
    |> Enum.find(fn {_, {room_name, _}} -> room_name == name end)
    |> case do
      nil ->
        nil

      {_, {_, room_pid}} ->
        state = RoomState.get(room_pid)
        %Room{pid: room_pid, name: name, state: state}
    end
  end

  def count_rooms() do
    Registry.count(RoomRegistry)
  end
end
