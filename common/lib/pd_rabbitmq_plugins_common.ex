defmodule PdRabbitMQPluginsCommon do
  @moduledoc """
  Some handy utility functions for plugins.
  """
  require Logger

  @doc """
      The Elixir AMQP library does not support a direct (in-VM) connection. This
      does a direct connection and returns an AMQP library compatible connection.
      We only do a direct connection if RabbitMQ is already running.
  """
  def amqp_connect_direct() do
    in_rabbitmq_vm = Application.started_applications()
    |> Enum.map(fn {n, _d, _v} -> n end)
    |> Enum.member?(:rabbit)

    Logger.info("Connecting to RabbitMQ server. Direct mode is #{in_rabbitmq_vm}")

    amqp_connect_direct(in_rabbitmq_vm)
  end

  defp amqp_connect_direct(true) do
    import AMQP.Core
    {:ok, pid} = :amqp_connection.start(amqp_params_direct(node: node()))
    {:ok, %AMQP.Connection{pid: pid}}
  end

  defp amqp_connect_direct(false) do
    AMQP.Connection.open()
  end

end
