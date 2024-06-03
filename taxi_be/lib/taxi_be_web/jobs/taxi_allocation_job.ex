defmodule TaxiBeWeb.TaxiAllocationJob do
  use GenServer

  def start_link(request, name) do
    GenServer.start_link(__MODULE__, request, name: name)
  end

  def init(request) do
    Process.send(self(), :step1, [:nosuspend])
    {:ok, %{request: request}}
  end

  def handle_info(:step1, %{request: request}) do

    # task = Task.async(fn -> select_candidate_taxis(request) |> hd end)

    # compute_ride_fare(request)
    # |> notify_customer_ride_fare()

    # taxi = Task.await(task)


    task = Task.async(fn ->
      compute_ride_fare(request)
      |> notify_customer_ride_fare()
    end)

    taxis = select_candidate_taxis(request)

    Task.await(task)

    Process.send(self(), :bloque2, [:nosuspend])
    {:noreply, %{request: request, taxis: taxis}}
  end

  def handle_info(:bloque2, %{request: request, taxis: taxis} = state) do
      taxi = hd(taxis)
        # Forward request to taxi driver
        %{
          "pickup_address" => pickup_address,
          "dropoff_address" => dropoff_address,
          "booking_id" => booking_id
        } = request
        TaxiBeWeb.Endpoint.broadcast(
          "driver:" <> taxi.nickname,
          "booking_request",
           %{
             msg: "Viaje de '#{pickup_address}' a '#{dropoff_address}'",
             bookingId: booking_id
            })
    # Process.send_after(self(), :timeout, 10000)
    {:noreply, %{state | taxis: tl(taxis)}}
  end



  def handle_cast({:handle_accept, driver_username}, %{request: req} = state) do
    %{"username" => username} = req
    TaxiBeWeb.Endpoint.broadcast("customer:" <> username, "booking_request", %{msg: "Tu taxi esta en camino, llegará en 5 minutos."})

    {:noreply, state}
  end

  def compute_ride_fare(request) do
    %{
      "pickup_address" => pickup_address,
      "dropoff_address" => dropoff_address
     } = request

    coord1 = TaxiBeWeb.Geolocator.geocode(pickup_address)
    coord2 = TaxiBeWeb.Geolocator.geocode(dropoff_address)
    {distance, _duration} = TaxiBeWeb.Geolocator.distance_and_duration(coord1, coord2)
    {request, Float.ceil(distance/300)}
  end

  def notify_customer_ride_fare({request, fare}) do
    %{"username" => customer} = request
   TaxiBeWeb.Endpoint.broadcast("customer:" <> customer, "booking_request", %{msg: "Ride fare: #{fare}"})
  end

  def select_candidate_taxis(%{"pickup_address" => _pickup_address}) do
    [
      %{nickname: "frodo", latitude: 19.0319783, longitude: -98.2349368},
      %{nickname: "samwise", latitude: 19.0061167, longitude: -98.2697737},
      %{nickname: "merry", latitude: 19.0092933, longitude: -98.2473716}
    ]
  end
end
