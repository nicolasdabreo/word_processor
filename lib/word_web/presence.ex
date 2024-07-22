defmodule WordWeb.Presence do
  use Phoenix.Presence,
    otp_app: :word_processor,
    pubsub_server: Word.PubSub

  alias Phoenix.LiveView

  ### API

  def list_online_users(), do: list("online_users") |> Enum.map(fn {_id, presence} -> presence end)

  def track_user(persona_id, persona_name, room_name), do: track(self(), "online_users", persona_id, %{
    name: persona_name,
    joined_at: :os.system_time(:seconds),
    room_name: room_name
  })

  def subscribe(), do: Phoenix.PubSub.subscribe(Word.PubSub, "proxy:online_users")

  ### Server

  def init(_opts) do
    {:ok, %{}}
  end

  def fetch(_topic, presences) do
    for {key, %{metas: [meta | metas]}} <- presences, into: %{} do
      # user can be populated here from the database here we populate
      # the name for demonstration purposes
      {key, %{metas: [meta | metas], id: meta.name, user: %{name: meta.name}}}
    end
  end

  def handle_metas(topic, %{joins: joins, leaves: leaves}, presences, state) do
    for {user_id, presence} <- joins do
      user_data = %{id: user_id, user: presence.user, metas: Map.fetch!(presences, user_id)}
      msg = {__MODULE__, {:join, user_data}}
      Phoenix.PubSub.local_broadcast(Word.PubSub, "proxy:#{topic}", msg)
    end

    for {user_id, presence} <- leaves do
      metas =
        case Map.fetch(presences, user_id) do
          {:ok, presence_metas} -> presence_metas
          :error -> []
        end

      user_data = %{id: user_id, user: presence.user, metas: metas}
      msg = {__MODULE__, {:leave, user_data}}
      Phoenix.PubSub.local_broadcast(Word.PubSub, "proxy:#{topic}", msg)
    end

    {:ok, state}
  end

  ### LiveView

  def on_mount(:default, params, session, socket) do
    socket = Phoenix.Component.assign(socket, :presences, [])

    socket =
      if LiveView.connected?(socket) do
        if params["name"] do
          track_user(session["persona_id"], session["persona_name"], params["name"])
        end
        subscribe()
        Phoenix.Component.assign(socket, :presences, list_online_users())
      else
        socket
      end

    {:cont,
      socket
      |> LiveView.attach_hook(:presence_hooks, :handle_info, fn
        {WordWeb.Presence, {:join, _presence}}, socket ->
          {:cont, Phoenix.Component.assign(socket, :presences, list_online_users())}

        {WordWeb.Presence, {:leave, presence}}, socket ->
          if presence.metas == [] do
            {:cont, Phoenix.Component.assign(socket, :presences, list_online_users())}
          else
            {:cont, Phoenix.Component.assign(socket, :presences, list_online_users())}
          end

        _event, socket ->
          {:cont, socket}
      end)}
  end
end
