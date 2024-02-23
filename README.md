# WP

The project has been set up with no database so start up is as simple as:

```elixir
mix setup
iex -S mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Initial thoughts

As this application is stateful utilising a supervised process to persist state 
across actions will likely be best. Agents fit this purpose for the simplest option,
ETS would also work well but operations are not atomic (iirc) so it would need 
a intermediary process managing state updates which complicates things and kills
the benefits of ETS.

As text needs to be concurrently editable, Agent should be supervised at the 
application level

Gonna use LiveView because LiveView is the bomb

## Update 1

Realised that I don't need the actual text to be editable and that state maintained
in the Agent, all statemanagement should happen through thhe actions laid out in 
the spec. Moving to a switchable mode form

## Update 2

I added PubSub to sync the state with events and a little ephemeral log. Also
now using a schemaless changeset to handle the validations. Pretty happy with it.

I wasn't entirely sure which way to take searching so I just went with a true/false
indicator.
