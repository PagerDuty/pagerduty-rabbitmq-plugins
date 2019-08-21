defmodule PdEventsApiPlugin.Handler do
  @moduledoc """
  Default handler for the PD Events API Plugin.
  """

  require Logger

  @events_api "https://events.pagerduty.com/v2/enqueue"
  @response_codes %{
    200 => :ok,
    202 => :ok,
    400 => :error
  }
  @default_response_code :retry

  @doc """
  Callback function for the `Consumer` module. We assume that the message body is in
  CEF format so we can just pass it on.
  """
  def handle_message(message, proxy) do
    Logger.debug("Received message: #{inspect message}")
    try do
      options = unless proxy == nil, do: [proxy: proxy], else: []
      {:ok, response} = HTTPoison.post(@events_api, message, [{"Content-Type", "application/json"}], options)
      Logger.debug("HTTP response: #{inspect response}")
      Map.get(@response_codes, response.status_code, @default_response_code)
    rescue
      exception ->
        Logger.error("Unexpected exception during delivery")
        :error
    end
  end
end
