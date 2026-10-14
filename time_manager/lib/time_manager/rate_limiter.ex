defmodule TimeManager.RateLimiter do
  @moduledoc """
  A tiny in-memory rate limiter backed by an ETS table.

  It counts how many times a key (e.g. "sign_in:1.2.3.4") is hit inside a
  time window. Over the limit -> :blocked. Used to stop password brute-force.
  No external service needed: the counts live in RAM and reset each window.
  """
  use GenServer

  @table :rate_limiter
  @sweep_every_ms 60_000

  def start_link(_opts), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @doc """
  Records one hit for `key`. Returns :ok if still under `limit` within
  `window_ms`, or :blocked once the limit is reached.
  Fails open: if the table isn't ready, it allows the request rather than crashing.
  """
  def hit(key, limit, window_ms) do
    now = System.system_time(:millisecond)
    bucket = div(now, window_ms)
    ets_key = {key, bucket}

    try do
      # Atomically add 1 (creating the row at 0 first if it doesn't exist)
      count = :ets.update_counter(@table, ets_key, {2, 1}, {ets_key, 0})
      if count <= limit, do: :ok, else: :blocked
    rescue
      ArgumentError -> :ok
    end
  end

  # --- GenServer: owns the table and cleans old buckets ---

  @impl true
  def init(_) do
    :ets.new(@table, [:named_table, :public, :set, write_concurrency: true])
    schedule_sweep()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:sweep, state) do
    # Drop every bucket older than the current one to free memory
    current = div(System.system_time(:millisecond), @sweep_every_ms)
    :ets.select_delete(@table, [{{{:_, :"$1"}, :_}, [{:<, :"$1", current - 1}], [true]}])
    schedule_sweep()
    {:noreply, state}
  end

  defp schedule_sweep, do: Process.send_after(self(), :sweep, @sweep_every_ms)
end