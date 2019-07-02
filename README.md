# PagerDuty RabbitMQ Plugins

This repository contains plugins to connect RabbitMQ to PagerDuty. Currently, it
contains a single plugin but more are expected.

## Why?

Since the early days of PagerDuty, the [PagerDuty Agent](https://github.com/PagerDuty/pdagent)
has enabled customers to route messages to PagerDuty through an on-premises agent. This agent
can buffer and retry delivery and it works well in that respect, but it does not scale very
well.

When looking for a solution, we considered a number of solutions, all revolving around the
same principle: have some persistence as a queue and do delivery from there, but then faster
than PD Agent. However, wheel reinvention is not our thing; when we realized that RabbitMQ
was written in Erlang (with bits in Elixir), and runs on the very VM we use in production,
it was an easy decision to farm out "the hard parts" (queueing) to an already proven system
and just write plugins.

This way, we hit multiple goals at once:

* RabbitMQ is very scalable; with the plugin, we are too.
* How to operate RabbitMQ is very well documented and has a wide array of support options.
* There is already packaging/distribution for many operating systems so all we need
  to add is our plugin, which is a handful of simple files to be dropped in the correct spot.

By tapping into the power of RabbitMQ, we can focus on plugin functionality and not worry
about things that are in the category "harder than you'd expect", like performant message
queueing.

## Plugin list

Current list of plugins:

* [pd-events-api-plugin](pd-events-api-plugin) - A queue consumer that talks to the PagerDuty
  Events API.

## Installation

t.b.d.
