defmodule WordWeb.WordLive do
  @moduledoc """
  The Word Processor LiveView, uses the submitter API to allow different types
  of button form submssions, streams for event log state, finally the process listens to
  PubSub changes to understand how the Word Processor's state has changed.
  """

  use WordWeb, :live_view

  alias WordWeb.WordForm
  alias Word.Rooms

  def mount(%{"name" => name}, _session, socket) do
    room = Rooms.get_room(String.to_existing_atom(name))

    if connected?(socket) do
      Rooms.subscribe(room)
    end

    if is_nil(room) do
      {:ok,
      socket
      |> put_flash(:info, "That room has timed out")
      |> push_navigate(to: ~p"/")}
    else
      {:ok,
      socket
      |> assign(:room, room)
      |> assign(:mode, :insert)
      |> assign(:form, to_form(%{}, as: "word"))
      |> assign(:mode_form, to_form(%{}, as: "mode"))
      |> assign(:log_length, 0)
      |> stream_configure(:event_log,
      dom_id: fn _ -> "log-#{System.unique_integer([:positive, :monotonic])}" end
      )
      |> stream(:event_log, [])}
    end
  end

  def handle_event("submit", %{"submit" => "insert", "word" => params}, socket) do
    case WordForm.parse(params) do
      {:ok, %{prompt: text_to_insert, position: position}} ->
        room = Rooms.insert_text(socket.assigns.room, position, text_to_insert)
        {:noreply,
        socket
      |> assign(:room, room)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:form, to_form(changeset, as: "word"))}
    end
  end

  def handle_event("submit", %{"submit" => "replace", "word" => params}, socket) do
    case WordForm.parse(params) do
      {:ok, %{prompt: text_to_find, replace: replacement_text}} ->
        room = Rooms.replace_text(socket.assigns.room, text_to_find, replacement_text)
        {:noreply,
        socket
      |> assign(:room, room)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:form, to_form(changeset, as: "word"))}
    end
  end

  def handle_event("submit", %{"submit" => "delete", "word" => params}, socket) do
    case WordForm.parse(params) do
      {:ok, %{prompt: text_to_delete}} ->
        room = Rooms.delete_text(socket.assigns.room, text_to_delete)
        {:noreply,
        socket
      |> assign(:room, room)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:form, to_form(changeset, as: "word"))}
    end
  end

  def handle_event("submit", %{"submit" => "search", "word" => params}, socket) do
    case WordForm.parse(params) do
      {:ok, %{prompt: text_to_search}} ->
        Rooms.search_text(socket.assigns.room, text_to_search)
        {:noreply, socket}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:form, to_form(changeset, as: "word"))}
    end
  end

  def handle_event("change-mode", %{"mode" => %{"mode" => mode}}, socket) do
    {:noreply,
     socket
     |> assign(:mode, String.to_existing_atom(mode))}
  end

  def handle_info({Rooms, event}, socket) do
    {:noreply,
     socket
     |> update(:log_length, fn len -> len + 1 end)
     |> stream_insert(:event_log, event, at: 0)}
  end
end
