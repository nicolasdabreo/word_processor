defmodule WordWeb.Presence do
  use Phoenix.Presence,
    otp_app: :word_processor,
    pubsub_server: Word.PubSub
end
