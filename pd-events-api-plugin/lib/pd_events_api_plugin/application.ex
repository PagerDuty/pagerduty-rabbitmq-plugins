defmodule PdEventsApiPlugin.Application do
  use Application
  require Logger

  @default_app_file if Mix.env == :prod, do: "/etc/rabbitmq/pd-events-api-plugin.json", else: "config/pd-events-api-plugin.json"
  @default_exchange "pd-events-api-plugin"
  @default_queue    "pd-events"

  @doc """
  Application startup. The configuration file is hard-coded but you can override it by setting the
  `PD_EVENTS_API_PLUGIN_CONFIG_FILE` environment variable prior to RabbitMQ startup.
  """
  def start(_type, _args) do
    conf = System.get_env("PD_EVENTS_API_PLUGIN_CONFIG_FILE") || @default_app_file
    if not File.exists?(conf) do
      {:error, "Could not find config file #{conf}"}
    else
      Logger.info("Using configuration from #{conf}")

      config = with {:ok, contents} <- File.read(conf),
                    {:ok, map} <- Jason.decode(contents) do
                 map
               end

      log_level = Map.get(config, "log_level", "debug")
      Logger.configure(level: String.to_atom(log_level))

      exchange = Map.get(config, "exchange", @default_exchange)
      queue = Map.get(config, "queue", @default_queue)
      handler = &PdEventsApiPlugin.Handler.handle_message/1

      Supervisor.start_link([
        {PdEventsApiPlugin.Consumer, [exchange, queue, handler]}],
        strategy: :one_for_one,
        name: PdEventsApiPlugin.Supervisor)
    end
  end
end
