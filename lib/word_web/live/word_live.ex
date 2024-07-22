defmodule WordWeb.WordLive do
  @moduledoc """
  The Word Processor LiveView, uses the submitter API to allow different types
  of button form submssions, streams for event log state, finally the process listens to
  PubSub changes to understand how the Word Processor's state has changed.
  """

  use WordWeb, :live_view

  alias WordWeb.WordForm
  alias Word.Rooms

  on_mount WordWeb.Persona
  on_mount WordWeb.Presence

  def mount(%{"name" => name}, _session, socket) do
    room = Rooms.get_room(name)

    if is_nil(room) do
      {:ok,
       socket
       |> put_flash(:error, "That room has timed out")
       |> push_navigate(to: ~p"/")}
    else
      if connected?(socket) do
        Rooms.subscribe(room)
      end

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

  def handle_info(_, socket) do
    {:noreply, socket}
  end


  attr :stream, :any, required: true
  attr :stream_length, :integer, required: true
  attr :persona, :any, required: true

  def event_log(assigns) do
    ~H"""
    <ul id="event" phx-update="stream" phx-page-loading class="flex flex-col gap-3">
      <li :for={{id, event} <- @stream} id={id}>
        <.log_entry event={event} persona={@persona} />
      </li>
    </ul>
    <div :if={@stream_length < 1} class="mt-5 text-base font-semibold text-center">
      Nothing has happened yet...
    </div>
    """
  end

  attr :event, :any, required: true
  attr :persona, :any, required: true

  defp log_entry(assigns) do
    ~H"""
    <div class="relative pb-8">
      <span class="absolute left-4 top-4 -ml-px h-full w-0.5 bg-gray-200" aria-hidden="true"></span>
      <div class="relative flex space-x-3">
        <div>
          <span class="flex items-center justify-center w-8 h-8 bg-gray-400 rounded-full ring-8 ring-white">
            <.icon name="hero-bars-3-bottom-left" class="w-5 h-5 text-white" />
          </span>
        </div>
        <div class="flex justify-between flex-1 min-w-0 space-x-4">
          <div>
            <div class="flex flex-row items-center justify-center gap-2">
              <p class="text-sm font-semibold text-zinc-600"><%= truncate_event_struct(@event.__struct__) %> by</p>
              <.tooltip>
                <div class="z-0 inline-flex w-8 h-8 rounded-full cursor-pointer bg-zinc-50">
                  <span class="flex items-center justify-center w-full h-full text-xl">
                    <%= @persona.emoji %>
                  </span>
                </div>
                <.tooltip_content side="right">
                  <%= @persona.name %>
                </.tooltip_content>
              </.tooltip>
            </div>
            <span class="text-sm text-zinc-900">
              <%= case truncate_event_struct(@event.__struct__) do %>
                <% "TextInserted" -> %>
                  "<%= @event.inserted_text %>" inserted
                <% "TextReplaced" -> %>
                  "<%= @event.query_text %>" replaced with "<%= @event.replaced_with %>"
                <% "TextDeleted" -> %>
                  "<%= @event.deleted_text %>" deleted
              <% end %>
            </span>
          </div>
          <div class="text-sm text-right text-gray-500 whitespace-nowrap">
            <time datetime="2020-09-20">Sep 20</time>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp truncate_event_struct(struct), do: struct |> Module.split() |> List.last()
end
