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
      start: {RoomState, :start_link, [""]},
      restart: :permanent,
      type: :worker
    }

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, pid} ->
        Registry.register(RoomRegistry, name, pid)
        {:ok, pid}

      error ->
        error
    end
  end

  def list_rooms do
    rooms = Registry.select(RoomRegistry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$3"}}]}])

    for {name, pid} <- rooms do
      state = RoomState.get(pid)
      %Room{pid: pid, name: name, state: state}
    end
  end

  def get_room(name) do
    Enum.find(list_rooms(), & &1.name == name)
  end
end
