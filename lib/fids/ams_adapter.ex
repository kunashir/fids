defmodule FIDS.AMS do
  @moduledoc """
  Adapter for AMS airport
  """
  use Tesla
  adapter :httpc
  
  @credential [
    app_id: "ed3a14db",
    app_key: "411ef9f141a6c5305fc7d40b76897877",
    sort: "+scheduledate",
    includedelays: true
  ]


  plug Tesla.Middleware.BaseUrl, "https://api.schiphol.nl"
  plug Tesla.Middleware.Headers, %{
    "User-Agent" => "tesla",
    "ResourceVersion" => "v3"
  }
  plug Tesla.Middleware.JSON

  
  defp settings do
    @credential
  end


  def get_fids(direction) do
    # make fetching every page in a separate process
    # use Task for fetching and Agent for save state
    {:ok, body, header} = load_page(direction, 0)
    [_, last_page] = hd Regex.scan(~r/page=(\d{3})/, header["link"])
    flights = []
    pid = self()
    (0..String.to_integer(last_page)) 
      |> Task.async_stream(fn n -> load_page("D", n) end, max_concurrency: 10, timeout: 30_000, ordered: true)
      |> Stream.map(fn {:ok, data} -> data end)
      |> Enum.to_list()
  end

  def load_page( direction, page \\ 0) do
    response = request(method: :get, url: "/public-flights/flights", query: query(direction, page))
    if (:body in Map.keys(response)) do
      {:ok, response.body["flights"], response.headers}
    else
      {:error, 'Error!'}
    end
  end

  defp query(direction, page) do
    settings() ++ [page: page, flightdirection: direction]
  end

end