defmodule Firesky.HomeLive do
  use FireSky, :live_view


  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
