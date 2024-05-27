defmodule TaxiBeWeb.BookingController do
  use TaxiBeWeb, :controller
  alias TaxiBeWeb.TaxiAllocationJob
  def create(conn, req) do
    IO.inspect(req)
    booking_id = UUID.uuid1()
    TaxiAllocationJob.start_link(
      req |> Map.put("booking_id", booking_id),
      String.to_atom(booking_id)
    )
    conn
    |> put_resp_header("Location", "/api/bookings/" <> booking_id)
    |> put_status(:created)
    |> json(%{msg: "We are processing your request, please be patient"})
  end
  def update(conn, %{"action" => "accept", "username" => username, "id" => id}) do
    IO.inspect("'#{username}' is accepting a booking request")
    GenServer.cast(id |> String.to_atom(), {:handle_accept, username})
    json(conn, %{msg: "We will process your acceptance"})
  end
  def update(conn, %{"action" => "reject", "username" => username, "id" => _id}) do
    IO.inspect("'#{username}' is rejecting a booking request")
    json(conn, %{msg: "We will process your rejection"})
  end
  def update(conn, %{"action" => "cancel", "username" => username, "id" => _id}) do
    IO.inspect("'#{username}' is cancelling a booking request")
    json(conn, %{msg: "We will process your cancelation"})
  end
end
