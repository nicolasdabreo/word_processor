defmodule Word.Rooms.Room do
  alias __MODULE__, as: Room
  defstruct name: nil, pid: nil, state: nil
  @type t() :: %Room{}
end
