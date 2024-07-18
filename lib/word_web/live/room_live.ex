defmodule WordWeb.RoomLive do
  @moduledoc """
  The Word Processor LiveView, uses the submitter API to allow different types
  of button form submssions, streams for event log state, finally the process listens to
  PubSub changes to understand how the Word Processor's state has changed.
  """

  use WordWeb, :live_view

  alias Word.Rooms

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Word.Rooms.subscribe()
    end

    {:ok,
     socket
     |> assign(:rooms, Rooms.list_rooms())}
  end

  def handle_event("create-room", _params, socket) do
    room_name = Rooms.start_room()

    {:noreply,
     socket
     |> put_flash(:info, "Started new room - #{room_name}")}
  end

  def handle_info({Word.Rooms, :room_created}, socket) do
    {:noreply,
     socket
     |> assign(:rooms, Rooms.list_rooms())}
  end
end
