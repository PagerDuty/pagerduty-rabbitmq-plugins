.PHONY: clients target

CLIENTS := pd-send

dist: clean-ez ez-common ez-pdeaip clients
	curl -LO https://github.com/PagerDuty/pagerduty-rabbitmq-plugins/releases/download/elixir-20.3-1.8.1/elixir-1.8.1.ez
	curl -LO https://github.com/PagerDuty/pagerduty-rabbitmq-plugins/releases/download/elixir-20.3-1.8.1/logger-1.8.1.ez
	zip dist.zip *.ez

clean-ez:
	rm -f dist.zip *.ez

ez-common:
	cd common; mix deps.get; MIX_ENV=prod mix ez_archives; zip ../dist.zip *.ez

ez-pdeaip:
	cd pd-events-api-plugin; MIX_ENV=prod mix archive.build; zip ../dist.zip *.ez

clients:
	go get github.com/streadway/amqp
	go build ./...

clean: clean-ez
	rm -f */*.ez *.deb ${CLIENTS}
	rm -rf target

# Tested on Ubuntu 18.04
debian-dist: dist fpm debian-target
	fpm -s dir -t deb \
		--name "pagerduty-rabbitmq-plugins" \
		--version `cat VERSION`-1 \
	  --architecture x86_64 \
		--depends 'rabbitmq-server >= 3.6.10' \
    --after-install dist/debian-after-install.sh \
    -C target .

debian-target: target
	mkdir -p target/usr/lib/rabbitmq/plugins
	cd target/usr/lib/rabbitmq/plugins; rm *; unzip ../../../../../dist.zip
	mkdir -p target/usr/bin
	cp $(CLIENTS) target/usr/bin
	mkdir -p target/etc/rabbitmq
	cp pd-events-api-plugin/config/pd-events-api-plugin.json target/etc/rabbitmq

fpm:
	which fpm || gem install fpm

target:
	rm -rf target && mkdir target
