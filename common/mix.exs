defmodule PdRabbitmqPluginsCommon.MixProject do
  use Mix.Project

  def project do
    [
      app: :pd_rabbitmq_plugins_common,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # We collect all dependencies here. That way, we do not need to replicate the
      # Makefile that creates all the `.ez` files for every application.
      {:amqp, "~> 1.2"},
      {:httpoison, "~> 1.5"}
    ]
  end
end
