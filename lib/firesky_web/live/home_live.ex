defmodule FireskyWeb.HomeLive do
  @moduledoc false
  use FireskyWeb, :live_view

  @interval 100

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
      |> stream(:frames, [], limit: 50)
      |> assign(:buffer, [])

    flush()

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:frame, json_map}, socket) do
    id = json_map["commit"]["cid"]
    json = # inspect(json_map)
      json_map
      |> Jason.encode!()
      |> Jason.Formatter.pretty_print()
    socket = update(socket, :buffer, &[{id, json} | &1])

    {:noreply, socket}
  end

  def handle_info(:flush, socket) do
    %{buffer: buffer} = socket.assigns

    socket =
      socket
      |> assign(:buffer, [])
      |> stream(:frames, Enum.reverse(buffer), at: 0, limit: 50)

    flush()

    {:noreply, socket}
  end

  defp flush, do: Process.send_after(self(), :flush, @interval)
end
