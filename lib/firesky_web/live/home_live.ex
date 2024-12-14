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

    <div id="feed" phx-update="stream">
      <div :for={{id, frame} <- @streams.frames} id={id}>
        {inspect(frame)}
      </div>
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(Firesky.PubSub, "firehose")

    socket =
      socket
      |> stream_configure(:frames, dom_id: & &1["commit"]["cid"])
      |> stream(:frames, [], limit: 50)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:frame, json}, socket) do
    socket = stream_insert(socket, :frames, json, limit: -10)
    {:noreply, socket}
  end
end
