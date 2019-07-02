# PdRabbitmqPluginsCommon

Common dependencies/code for PagerDuty RabbitMQ Plugins.

Collecting all the dependencies here makes sense for several reasons: first, we need to create `.ez` archives
to go into the RabbitMQ `plugins` directory for every OTP application we require; this takes some extra code
that makes sense to factor out. Second, given that we can only have a single OTP application for each dependency,
this means that all dependencies for the various plugins _must_ be the same version. Thus, it makes sense to
force this by having all the plugins collect their dependencies in a single place.

The only drawback of this method is that you may have some unnecessary `.ez` files in your RabbitMQ plugins
directory.
