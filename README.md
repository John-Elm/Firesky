# Phoenix LiveView Firesky

A proof-of-concept demonstrating just how easy it is to create real-time applications with LiveView.

Just `mix setup` followed by `iex -S mix phx.server`. Visit `localhost:4000` and watch the magic.

Inspired by https://firesky.tv

The magic code is:


```elixir
# lib/firesky_web/live/home_live.ex

def handle_info({:frame, json_map}, socket) do
  id = json_map["commit"]["cid"]
  json =
    json_map
    |> Jason.encode!()
    |> Jason.Formatter.pretty_print()
  socket = stream_insert(socket, :frames, {id, json}, limit: -10, at: 0)
  {:noreply, socket}
end
```

and

```elixir
def handle_info({:gun_ws, _conn_pid, _stream_ref, frame}, state) do
  {:text, raw_json} = frame
  json_map = Jason.decode!(raw_json)
  Phoenix.PubSub.broadcast(Firesky.PubSub, "firehose", {:frame, json_map})
  {:noreply, state}
end
```

## Demo Video


https://github.com/user-attachments/assets/ca32bffd-4c29-4b9a-8606-7f0a7b434552



