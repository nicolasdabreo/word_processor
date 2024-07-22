defmodule Word.Persona do
  @animals [
    {"Antelope", "🦌"},
    {"Badger", "🦡"},
    {"Cat", "🐱"},
    {"Dog", "🐶"},
    {"Elephant", "🐘"},
    {"Fox", "🦊"},
    {"Giraffe", "🦒"},
    {"Hedgehog", "🦔"},
    {"Iguana", "🦎"},
    {"Jaguar", "🐆"},
    {"Kangaroo", "🦘"},
    {"Lion", "🦁"},
    {"Monkey", "🐒"},
    {"Narwhal", "🦄"},
    {"Owl", "🦉"},
    {"Panda", "🐼"},
    {"Quokka", "🐿️"},
    {"Rabbit", "🐰"},
    {"Sloth", "🦥"},
    {"Tiger", "🐯"},
    {"Unicorn", "🦄"},
    {"Vulture", "🦅"},
    {"Wolf", "🐺"},
    {"Xerus", "🦔"},
    {"Yak", "🦬"},
    {"Zebra", "🦓"}
  ]

  defstruct name: nil, id: nil, emoji: nil

  def generate_persona() do
    {animal, emoji} = Enum.random(@animals)

    %__MODULE__{
      id: System.unique_integer([:positive, :monotonic]),
      name: "Anonymous #{animal}",
      emoji: emoji
    }
  end
end
