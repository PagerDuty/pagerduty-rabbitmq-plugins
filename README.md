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
  
## Clients

Some command-line clients to make interacting with the system easier are provided (or planned). The current list:

* `pd-send` - send an event. This is a very simple first integration point. For options, please
  refer to the [source code](clients/pd-send/main.go#L36). There are also two environment variables
  you can set, again see the [source code](clients/pd-send/main.go#L86).

## Installation

Assuming that you have the correct Erlang and Elixir versions installed (check [.tool-versions](.tool-versions)
for the required versions) and after making sure that this version is compatible with your RabbitMQ version,
you can just do:

```
make
```

to build a `dist.zip` file. This file can be unpacked in the RabbitMQ plugins directory (`/usr/lib/rabbitmq/plugins`
on Ubuntu Bionic). Restarting RabbitMQ will make all the plugins available. `rabbitmq-plugins enable <plugin-name>`
will then enable the plugin you want to use. Please check the plugin documentation first though for extra details.

Note that it is best to run this on the target platform; while compiled `.beam` files are portable, it might
be that plugin code (indirectly) depends on applications that have native functions; in that case, the `.ez`
file will contain platform-dependent object code.

### Installation on Debian/Ubuntu

Make or download the distribution file (`make debian-dist`). Then

```
sudo apt install ./pagerduty-rabbitmq-plugins_1.0.0-1_amd64.deb
sudo rabbitmq-plugins enable pd_events_api_plugin
```

To install everything and enable the plugin.

## Post-installation steps

RabbitMQ ships with a default `guest/guest` user account that has wide access. At the minimum, post installation,
change the guest password:

```
sudo rabbitmqctl change_password guest <new_password>
```

See [User Management](https://www.rabbitmq.com/rabbitmqctl.8.html#User_Management) in the RabbitMQ documentation
for more information.


# License

Copyright 2019, PagerDuty Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
