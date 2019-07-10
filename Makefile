.PHONY: clients

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
	go build ./...
