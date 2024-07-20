defmodule Word.Events.TextInserted do
  defstruct raw_text: nil, inserted_text: nil, inserted_at: nil
end

defmodule Word.Events.TextReplaced do
  defstruct raw_text: nil, query_text: nil, replaced_with: nil
end

defmodule Word.Events.TextDeleted do
  defstruct raw_text: nil, deleted_text: nil
end

defmodule Word.Events.RoomCreated do
  defstruct room_name: nil
end

defmodule Word.Events.RoomJoined do
  defstruct room_name: nil
end

defmodule Word.Events.RoomLeft do
  defstruct room_name: nil
end

defmodule Word.Events.RoomTimedOut do
  defstruct room_name: nil
end
