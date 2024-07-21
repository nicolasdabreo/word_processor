defmodule WordWeb.RoomLive do
  @moduledoc """
  The Word Processor LiveView, uses the submitter API to allow different types
  of button form submssions, streams for event log state, finally the process listens to
  PubSub changes to understand how the Word Processor's state has changed.
  """

  use WordWeb, :live_view

  alias Word.Events.RoomCreated
  alias Word.Rooms

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Rooms.subscribe()
    end

    {:ok,
     socket
     |> assign(:rooms, Rooms.list_rooms())
     |> assign(:room_count, Rooms.RoomManager.count_rooms())}
  end

  def handle_event("create-room", _params, socket) do
    Rooms.create_room()

    {:noreply,
     socket
     |> put_flash(:info, "Started new room")}
  end

  def handle_info({Rooms, %RoomCreated{room_name: name}}, socket) do
    {:noreply,
     socket
     |> update(:rooms, fn rooms -> rooms ++ [Rooms.get_room(name)] end)}
  end


  slot :room do
    attr :navigate, :any
    attr :active_users, :integer
  end

  slot :empty

  def room_list(assigns) do
    ~H"""
    <div class="my-14">
      <ul role="list" class="grid grid-cols-1 gap-5 mt-3 sm:grid-cols-2 sm:gap-6">
        <li :for={room <- @room} class="flex col-span-1 rounded-md shadow-sm">
          <div class="flex items-center justify-between flex-1 truncate bg-white border border-gray-200 rounded-md">
            <.link href={room.navigate} class="font-medium text-center text-gray-900 hover:text-gray-600">
              <div class="px-4 py-2 text-sm text-center truncate">
                <%= render_slot(room) %>
              </div>
            </.link>
            <span class="px-4 py-2 text-sm font-bold text-center truncate">
              <%= room[:active_users] || 0 %>
            </span>
          </div>
        </li>
      </ul>
      <%= if Enum.empty?(@room) do %>
        <%= render_slot(@empty) %>
      <% end %>
    </div>
    """
  end
end
