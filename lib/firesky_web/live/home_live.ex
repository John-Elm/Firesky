defmodule FireskyWeb.HomeLive do
  @moduledoc false
  use FireskyWeb, :live_view

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.header>
      LiveView Firesky
      <:subtitle>The Live Bluesky Feed</:subtitle>
    </.header>

    <div id="feed" phx-update="stream" class="flex flex-col gap-y-4">
      <div :for={{id, {_id, frame}} <- @streams.frames} id={id}>
        {frame}
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(Firesky.PubSub, "firehose")

    socket =
      socket
      |> stream_configure(:frames, dom_id: &elem(&1, 0))
      |> stream(:frames, [], limit: 100)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:frame, json_map}, socket) do
    id = json_map["commit"]["cid"]
    json = Jason.encode!(json_map)
                   |> Jason.Formatter.pretty_print()
    socket = stream_insert(socket, :frames, {id, json}, limit: -10, at: 0)
    {:noreply, socket}
  end
end
