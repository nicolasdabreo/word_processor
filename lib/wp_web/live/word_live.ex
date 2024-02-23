defmodule WPWeb.WordLive do
  @moduledoc """
  The Word Processor LiveView, uses the submitter API to allow different types
  of button form submssions, streams for event log state, finally the process listens to
  PubSub changes to understand how the Word Processor's state has changed.
  """

  use WPWeb, :live_view

  alias WPWeb.WordForm

  defp initialise_state(socket) do
    if connected?(socket) do
      WP.start_link("")
      WP.EventLog.subscribe()
      assign(socket, :processed_text, WP.get_state())
    else
      assign(socket, :processed_text, "")
    end
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> initialise_state()
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
        WP.insert(position, text_to_insert)
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
        WP.replace(text_to_find, replacement_text)
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
        WP.delete(text_to_delete)
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
        WP.search(text_to_search)
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

  def handle_info({WP.EventLog, event}, socket) do
    {:noreply,
     socket
     |> assign(:processed_text, event.processed_text)
     |> update(:log_length, fn len -> len + 1 end)
     |> stream_insert(:event_log, event, at: 0)}
  end
end
