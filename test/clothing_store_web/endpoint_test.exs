defmodule ClothingStoreWeb.EndpointTest do
  use ExUnit.Case, async: true

  test "the LiveView websocket caps the frame size and keeps the session connect_info" do
    {"/live", Phoenix.LiveView.Socket, opts} =
      List.keyfind(ClothingStoreWeb.Endpoint.__sockets__(), "/live", 0)

    websocket = opts[:websocket]
    assert websocket[:max_frame_size] == 1_000_000
    assert [session: _] = websocket[:connect_info]
  end

  test "Bandit caps fragmented websocket messages too" do
    # browsers split large messages into fragments, which max_frame_size doesn't see
    http = ClothingStoreWeb.Endpoint.config(:http)
    assert http[:websocket_options][:max_fragmented_message_size] == 1_000_000
    assert http[:port]
  end
end
