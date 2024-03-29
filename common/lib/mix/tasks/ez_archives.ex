defmodule Mix.Tasks.EzArchives do
  @moduledoc """
  Create Erlang archives (`.ez` files) for myself and all dependencies.
  """

  require Logger

  # Generated by ls /usr/lib/rabbitmq/lib/rabbitmq_server-3.6.10/plugins/*.ez|xargs -n1 basename|sed -e 's/-.*/,/' -e 's/^/:/'
  # Could be done in a macro but that'd require a specific RabbitMQ installation during compile time.
  @rabbitmq_included_deps [
    :amqp_client,
    :cowboy,
    :cowlib,
    :rabbit_common,
    :rabbitmq_amqp1_0,
    :rabbitmq_auth_backend_ldap,
    :rabbitmq_auth_mechanism_ssl,
    :rabbitmq_consistent_hash_exchange,
    :rabbitmq_event_exchange,
    :rabbitmq_federation,
    :rabbitmq_federation_management,
    :rabbitmq_jms_topic_exchange,
    :rabbitmq_management,
    :rabbitmq_management_agent,
    :rabbitmq_management_visualiser,
    :rabbitmq_mqtt,
    :rabbitmq_recent_history_exchange,
    :rabbitmq_sharding,
    :rabbitmq_shovel,
    :rabbitmq_shovel_management,
    :rabbitmq_stomp,
    :rabbitmq_top,
    :rabbitmq_tracing,
    :rabbitmq_trust_store,
    :rabbitmq_web_dispatch,
    :rabbitmq_web_mqtt,
    :rabbitmq_web_mqtt_examples,
    :rabbitmq_web_stomp,
    :rabbitmq_web_stomp_examples,
    :ranch,
    :sockjs
  ]

  def run(_) do
    build_archives(Mix.Dep.cached)
    Mix.shell().cmd("MIX_ENV=prod mix archive.build")
  end

  defp build_archives(deps) do
    deps
    |> Enum.map(&build_archive/1)
  end

  defp build_archive(dep = %Mix.Dep{app: app}) when app in @rabbitmq_included_deps do
    Logger.info("Dependency #{app} is included in RabbitMQ, skipping")
  end
  defp build_archive(dep = %Mix.Dep{app: app}) do
    Logger.info("Building .ez archive for #{app}")
    Mix.Dep.in_dependency(dep, [], fn _ ->
      do_build_archive(dep, dep.manager)
      Mix.shell().cmd("mv *.ez ../..") # TODO equivalent that does not require a POSIX shell
    end)
  end

  defp do_build_archive(dep, :mix) do
    Mix.shell().cmd("MIX_ENV=prod mix do deps.get, compile, archive.build")
  end

  defp do_build_archive(dep, :rebar3) do
    Mix.shell().cmd("rebar3 compile")
    # For Erlang packages, we create a temporary link to the correct spot.
    {:ok, version} = dep.status
    basename = "#{dep.app}-#{version}"
    Mix.shell().cmd("rm -f #{basename}; ln -sf _build/default/lib/#{dep.app} #{basename}")
    Mix.shell().cmd("zip -r #{basename}.ez #{basename}; rm #{basename}")
  end

  defp do_build_archive(_, manager) do
    raise("Do not know how to build archives for #{manager} packages")
  end

end
