defmodule WordWeb.Persona do
  @moduledoc """
  Plug that generates a random anonymous name and id, with an emoji representation.
  """

  import Plug.Conn

  alias Word.Persona

  def on_mount(:default, _params, %{"persona_id" => id, "persona_name" => name, "persona_emoji" => emoji}, socket) do
    {:cont,
      socket
      |> Phoenix.Component.assign(:persona, %Persona{id: id, name: name, emoji: emoji})}
  end

  def init(param), do: param

  def call(conn, _opts) do
    persona_id = get_session(conn, :persona_id)
    persona_name = get_session(conn, :persona_name)
    persona_emoji = get_session(conn, :persona_emoji)

    persona =
      if persona_id do
        %Persona{id: persona_id, name: persona_name, emoji: persona_emoji}
      else
        Persona.generate_persona()
      end

    conn
    |> put_session(:persona_id, persona.id)
    |> put_session(:persona_name, persona.name)
    |> put_session(:persona_emoji, persona.emoji)
    |> assign(:persona, persona)
  end
end
