defmodule TaxiBeWeb.Geolocator do
  @geocodingURL "https://api.mapbox.com/geocoding/v5/mapbox.places/"
  @directionsURL "https://api.mapbox.com/directions/v5/mapbox/driving/"
  @distanceMatrixURL "https://api.mapbox.com/directions-matrix/v1/mapbox/driving/"

  @token "pk.eyJ1IjoibGdiYW51ZWxvcyIsImEiOiJjbHdxdDFoa3cwNTJrMmtxNndpMnMxNzk5In0.v9tER9kbYqqcQFEUpuncMQ"

  def geocode(address) do
    case HTTPoison.get(
      @geocodingURL <> URI.encode(address) <>
      ".json?access_token=" <> @token
    ) do
      {:ok, %{body: bodyStr}} ->
        { :ok,
          bodyStr
          |> Jason.decode!
          |> Map.fetch!("features")
          |> hd
          |> Map.fetch!("center")
        }
      _ -> {:error, "Something wrong with Mapbox call"}
    end
  end

  def distance_and_duration({_, origin_coord}, {_, destination_coord}) do
    %{body: body} =
      HTTPoison.get!(
        @directionsURL <>
        "#{Enum.join(origin_coord, ",")};#{Enum.join(destination_coord, ",")}" <>
        "?access_token=" <> @token)

    %{"duration" => duration, "distance" => distance} =
      body
      |> Jason.decode!
      |> Map.fetch!("routes")
      |> hd
    {distance, duration}
  end


  def destination_and_duration(driver_coords, destination_coords) do
    list_of_coords = [destination_coords|driver_coords]
    %{body: body} = HTTPoison.get!(@distanceMatrixURL <>
      "#{
        Enum.map(list_of_coords, fn coords -> Enum.join(coords, ",") end)
        |> Enum.join(";")}" <>
      "?sources=0&access_token=" <> @token)

    body
    |> Jason.decode!
    |> Map.fetch!("durations")
    |> List.flatten
    |> tl
  end
end
