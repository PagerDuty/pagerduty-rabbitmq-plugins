# PdEventsApiPlugin

This plugin is very simple: it reads from the configured queue and publishes whatever it finds
to the PagerDuty V2 Events API.

# Installation

See the [top-level README](../README.md) for general installation. After that is done, you
need to create a file `/etc/rabbitmq/pd-events-api-plugin.json` with any configuration. The
file is mandatory but can be just an empty JSON map (`{}`). For details, see the
[example config file](config/pd-events-api-plugin.json).

After that, you can enable this plugin with

```
rabbitmq-plugins enable pd_events_api_plugin
```

which should result in a message saying `started X plugins` where `X` is some high-ish number
(depending on all the dependencies; at time of writing, it is 16). You should now, with
default configuration, be able to send a CEF event to the `pd-events-api-plugin` exchange. Say,
with the command line tool contained in the RabbitMQ Management plugin:

```
rabbitmqadmin publish routing_key='' exchange='pd-events-api-plugin' </tmp/event.json
```

# Performance

By default, the queue gets processed in a linear fashion. This is to prevent messages from
landing out-of-order. There are various ways to speed this up:

* Allow a larger backlog.
* Wrap calls to `consume/4` in `Task.await/1` to run them in parallel.
* Setup routing keys and multiple queues on the exchange.
* Combinations of the above.

By default, this code is created as "safety first", but feel free to deviate.
