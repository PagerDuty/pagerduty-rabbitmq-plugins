# PdRabbitmqPluginsCommon

Common dependencies/code for PagerDuty RabbitMQ Plugins.

Collecting all the dependencies here makes sense for several reasons: first, we need to create `.ez` archives
to go into the RabbitMQ `plugins` directory for every OTP application we require; this takes some extra code
that makes sense to factor out. Second, given that we can only have a single OTP application for each dependency,
this means that all dependencies for the various plugins _must_ be the same version. Thus, it makes sense to
force this by having all the plugins collect their dependencies in a single place.

The small drawback is that when using a subset of the plugins, too many applications are started. Usually,
an idle OTP app takes very little resources so it's a minor drawback and the benefits vastly outweigh it.
