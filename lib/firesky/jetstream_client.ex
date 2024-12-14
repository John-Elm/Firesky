defmodule Firesky.JetstreamClient do
  use GenServer

  @connect_opts %{
    connect_timeout: 60_000,
    retry: 10,
    retry_timeout: 300,
    transport: :tls,
    tls_opts: [
      verify: :verify_none,
      cacerts: :certifi.cacerts(),
      depth: 99,
      reuse_sessions: false
    ],
    http_opts: %{version: :"HTTP/1.1"},
    protocols: [:http],
  }

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    host = 'jetstream2.us-west.bsky.network'
    port = 443
    path = '/subscribe'

    {:ok, conn_pid} = :gun.open(host, port, @connect_opts)
    {:ok, _transport} = :gun.await_up(conn_pid)
    stream_ref = :gun.ws_upgrade(conn_pid, path, %{})

    # Set a timeout for the upgrade to complete
    Process.send_after(self(), :upgrade_timeout, 5000)

    {:ok, %{conn_pid: conn_pid, stream_ref: stream_ref, connected?: false}}
  end

  def handle_info({:gun_upgrade, _conn_pid, _stream_ref, ["websocket"], _headers}, state) do
    IO.puts("WebSocket connection established!")
    {:noreply, %{state | connected?: true}}
  end

  def handle_info({:gun_response, _conn_pid, _stream_ref, status, _resp_headers, _body}, state) do
    IO.puts("WebSocket upgrade failed with status: #{status}")
    {:stop, :normal, state}
  end

  def handle_info({:gun_ws, _conn_pid, _stream_ref, frame}, state) do
    IO.inspect(frame, label: "Received frame")
    {:text, json} = frame
    {:noreply, state}
  end

  def handle_info(:upgrade_timeout, %{connected?: false} = state) do
    IO.puts("Timed out waiting for WebSocket upgrade.")
    {:stop, :normal, state}
  end

  def handle_info(:upgrade_timeout, state) do
    # If we got here and connected is true, ignore the timeout.
    {:noreply, state}
  end
end
