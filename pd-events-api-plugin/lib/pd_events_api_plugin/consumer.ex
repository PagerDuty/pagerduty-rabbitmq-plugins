defmodule PdEventsApiPlugin.Consumer do
  @moduledoc """
  RabbitMQ Consumer code.

  Mostly a copy from the `AMQP` package [readme](https://hexdocs.pm/amqp/readme.html).
  """
  use GenServer
  use AMQP
  require Logger

  defmodule State do
    defstruct [:chan, :exchange, :queue, :handler, :routing_key, :proxy]
  end

  @doc """
  Creates a new consumer. Arguments:

  * `exchange` - the exchange to use
  * `queue` - the queue to read from
  * `message_handler` - a function that accepts a message and returns `:ok`, `:retry` or `:error`
  * `routing_key` - nil or an explicit routing key that needs to be passed on configuring the exchange binding.
  * `proxy` - nil or a proxy url to use when sending events to PagerDuty, e.g. "https://user:pass@127.0.0.1:3188"

  A 'retry' will also do a 1-second sleep to throttle the client a bit.

  Note that "routing_key" has nothing to do with PagerDuty's routing key. It's just a number from 1..parallelism
  that indicates which bucket it falls in.

  """
  def start_link([exchange, queue, message_handler, routing_key, proxy]) do
    state = %State{exchange: exchange, queue: queue, handler: message_handler, routing_key: routing_key, proxy: proxy}
    GenServer.start_link(__MODULE__, state, [])
  end

  def init(state) do
    {:ok, conn} = PdRabbitMQPluginsCommon.amqp_connect_direct()
    {:ok, chan} = Channel.open(conn)
    state = %State{state | chan: chan}
    setup_queue(state)

    # Limit unacknowledged messages to 10
    :ok = Basic.qos(state.chan, prefetch_count: 10)
    {:ok, _consumer_tag} = Basic.consume(chan, state.queue)

    {:ok, state}
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, %{consumer_tag: consumer_tag}}, state) do
    {:noreply, state}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, %{consumer_tag: consumer_tag}}, state) do
    {:stop, :normal, state}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, %{consumer_tag: consumer_tag}}, state) do
    {:noreply, state}
  end

  def handle_info({:basic_deliver, payload, %{delivery_tag: tag, redelivered: redelivered}}, state) do
    consume(state, tag, redelivered, payload)
    {:noreply, state}
  end

  def handle_info({:ssl_closed, _gen_tcp}, state) do
    Logger.debug("SSL connection closed")
    {:noreply, state}
  end

  defp setup_queue(state) do
    error_queue = "#{state.exchange}-error"
    {:ok, _} = Queue.declare(state.chan, error_queue, durable: true)
    # Messages that cannot be delivered to any consumer in the main queue will be routed to the error queue
    {:ok, _} = Queue.declare(state.chan, state.queue,
                             durable: true,
                             arguments: [
                               {"x-dead-letter-exchange", :longstr, ""},
                               {"x-dead-letter-routing-key", :longstr, error_queue}
                             ]
                            )
    :ok = Exchange.topic(state.chan, state.exchange, durable: true)
    :ok = Queue.bind(state.chan, state.queue, state.exchange, routing_key: state.routing_key)
  end

  defp consume(state, tag, redelivered, payload) do
    # In case of errors, we retry unless it was already redelivered. In case
    # endless retries are wanted, the handler should return `:retry`
    Logger.debug("state = #{inspect state}")
    Logger.debug("consuming tag=#{tag}, redelivered=#{redelivered}, payload=#{inspect payload}")
    try do
      case state.handler.(payload, state.proxy) do
        :ok ->
          Logger.debug("Message #{tag} delivered")
          Basic.ack state.chan, tag
        :retry ->
          Logger.info("Message #{tag} queued for retry")
          Process.sleep(1_000)
          Basic.reject state.chan, tag, requeue: true
        :error ->
          Logger.error("Rejecting message #{tag}")
          Basic.reject state.chan, tag, requeue: not redelivered
      end
    rescue
      exception ->
        Logger.error("Unexpected exception during delivery of message #{tag}: #{inspect exception}")
        :ok = Basic.reject state.chan, tag, requeue: not redelivered
    end
  end
end
