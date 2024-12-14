defmodule Firesky.JetstreamClient do
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
    host = 'jetstream2.us-west.bsky.network'
    port = 443
    path = '/subscribe'

    {:ok, conn_pid} = :gun.open(host, port, @connect_opts)
    {:ok, _http_version} = :gun.await_up(conn_pid)
    # Put conn_pid and stream_ref in state to match on incoming messages
    stream_ref = :gun.ws_upgrade(conn_pid, path, %{})

    receive do
      {:gun_upgrade, ^conn_pid, ^stream_ref, ["websocket"], headers} ->
        IO.puts("WebSocket connection established!")
        loop(conn_pid, stream_ref)

      {:gun_response, ^conn_pid, ^stream_ref, status, _resp_headers, _body} ->
        IO.puts("WebSocket upgrade failed with status: #{status}")
    after
      5000 ->
        IO.puts("Timed out waiting for WebSocket upgrade.")
    end
  end

  defp loop(conn_pid, stream_ref) do
    receive do
      {:gun_ws, ^conn_pid, ^stream_ref, frame} ->
        IO.inspect(frame, label: "Received frame")
        loop(conn_pid, stream_ref)
    after
      5000 ->
        IO.puts("No frames received.")
        loop(conn_pid, stream_ref)
    end
  end
end
