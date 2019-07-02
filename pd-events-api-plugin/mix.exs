defmodule PdEventsApiPlugin.MixProject do
  use Mix.Project

  def project do
    [
      app: :pd_events_api_plugin,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    # We only require a wait for the main RabbitMQ server app when
    # we're running as an actual plugin, which is when we're compiled
    # as prod.
    extras = if Mix.env != :prod, do: [:logger], else: [:logger, :rabbit]
    [
      mod: {PdEventsApiPlugin.Application, []},
      extra_applications: extras
    ]
  end

  defp deps do
    [
      {:pd_rabbitmq_plugins_common, path: "../common"}
    ]
  end
end
