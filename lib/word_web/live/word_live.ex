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
    room_pid = Rooms.get_room(name)

    if connected?(socket) do
      Word.EventLog.subscribe(name)
      assign(socket, :processed_text, Word.Agent.current_state(name))
    else
      assign(socket, :processed_text, "")
    end

    {:ok,
     socket
     |> assign(:room_name, name)
     |> assign(:room_pid, room_pid)
     |> assign(:mode, :insert)
     |> assign(:form, to_form(%{}, as: "word"))
     |> assign(:mode_form, to_form(%{}, as: "mode"))
     |> assign(:log_length, 0)
     |> stream_configure(:event_log,
       dom_id: fn _ -> "log-#{System.unique_integer([:positive, :monotonic])}" end
     )
     |> stream(:event_log, [])}
  end

  def handle_event("submit", %{"submit" => "insert", "word" => params}, socket) do
    case WordForm.parse(params) do
      {:ok, %{prompt: text_to_insert, position: position}} ->
        Word.Agent.insert(socket.assigns.room_name, position, text_to_insert)
        {:noreply, socket}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:form, to_form(changeset, as: "word"))}
    end
  end

  def handle_event("submit", %{"submit" => "replace", "word" => params}, socket) do
    case WordForm.parse(params) do
      {:ok, %{prompt: text_to_find, replace: replacement_text}} ->
        Word.Agent.replace(socket.assigns.room_name, text_to_find, replacement_text)
        {:noreply, socket}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:form, to_form(changeset, as: "word"))}
    end
  end

  def handle_event("submit", %{"submit" => "delete", "word" => params}, socket) do
    case WordForm.parse(params) do
      {:ok, %{prompt: text_to_delete}} ->
        Word.Agent.delete(socket.assigns.room_name, text_to_delete)
        {:noreply, socket}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:form, to_form(changeset, as: "word"))}
    end
  end

  def handle_event("submit", %{"submit" => "search", "word" => params}, socket) do
    case WordForm.parse(params) do
      {:ok, %{prompt: text_to_search}} ->
        Word.Agent.search(socket.assigns.room_name, text_to_search)
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

  def handle_info({Word.EventLog, event}, socket) do
    {:noreply,
     socket
     |> assign(:processed_text, event.processed_text)
     |> update(:log_length, fn len -> len + 1 end)
     |> stream_insert(:event_log, event, at: 0)}
  end
end
