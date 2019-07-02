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

# Notable configuration settings

* `log_level` - you probably want to set this to `info` because with the default level, debug
  logging is enabled.
* `paralellism` - by default this is disabled; if you enable it, then multiple queues will be
  created. See below for more details. Note that RabbitMQ probably has some limitations in this
  area as well.

# Parallelism

By default, one queue is created, bound to the exchange with a default routing key, and you
publish to there (with the empty `""` routing key). However, this serializes all calls to the
PD Events API which may be too slow.

Simple doing things in parallel won't work: events for individual routing keys _must_ arrive in order
of how they were generated so triggers, acks, and resolves arrive in the correct order at PagerDuty. Not
doing this will mean that you could acknowledge an old incident, or worse, resolve the wrong one.

The `parallelism` setting offers a simple way out - you specify how many queues are created, and each
one gets a consumer. Then, based on either manual mapping, or a hash function, you calculate the
RabbitMQ routing key for publication. This way there is complete control over which events get processed
in parallel (hopefully mapped so that they are fully independent) and which ones will wait for each other.
