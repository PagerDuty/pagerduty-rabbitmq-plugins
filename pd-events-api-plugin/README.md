# PdEventsApiPlugin

This plugin is very simple: it reads from the configured queue and publishes whatever it finds
to

# Installation

TODO

# Performance

By default, the queue gets processed in a linear fashion. This is to prevent messages from
landing out-of-order. There are various ways to speed this up:

* Allow a larger backlog.
* Wrap calls to `consume/4` in `Task.await/1` to run them in parallel.
* Setup routing keys and multiple queues on the exchange.
* Combinations of the above.

By default, this code is created as "safety first", but feel free to deviate.
