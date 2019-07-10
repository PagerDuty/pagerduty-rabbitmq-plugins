/*
 *  This is a basic client that can plug into Nagios.
 */
package main

import (
	"flag"
	"log"
	"os"

	"encoding/json"

	"github.com/streadway/amqp"
)

func failOnError(err error, msg string) {
	if err != nil {
		log.Fatalf("%s: %s", msg, err)
	}
}

func getEnvWithDefault(env string, default_value string) string {
	var v = os.Getenv(env)
	if len(v) == 0 {
		v = default_value
	}
	return v
}

func makeBody() []byte {
	m := make(map[string]interface{})

	// Required stuff
	var routing_key = flag.String("routing-key", "", "Routing key to send to")
	var event_action = flag.String("event-action", "trigger", "Event action (default=trigger)")
	var summary = flag.String("summary", "", "Payload summary")
	var source = flag.String("source", "", "Payload source")
	var severity = flag.String("severity", "", "Payload severity")

	// TODO flags for optional stuff

	// Process everything and check required things.
	flag.Parse()

	if len(*routing_key) == 0 {
		log.Fatalf("routing-key not specified")
	}
	if len(*event_action) == 0 {
		log.Fatalf("event-action not specified")
	}
	if len(*summary) == 0 {
		log.Fatalf("summary not specified")
	}
	if len(*source) == 0 {
		log.Fatalf("source not specified")
	}
	if len(*severity) == 0 {
		log.Fatalf("severity not specified")
	}

	m["routing_key"] = routing_key
	m["event_action"] = event_action
	payload := make(map[string]interface{})
	payload["summary"] = summary
	payload["source"] = source
	payload["severity"] = severity
	m["payload"] = payload

	b, err := json.Marshal(m)
	failOnError(err, "Could not encode JSON")

	return b
}

func main() {
	url := getEnvWithDefault("PD_SEND_AMQP_URL", "amqp://guest:guest@localhost:5672")
	exchange := getEnvWithDefault("PD_SEND_EXCHANGE", "pd-events-exchange")

	body := makeBody()

	conn, err := amqp.Dial(url)
	failOnError(err, "Failed to connect to RabbitMQ")
	defer conn.Close()

	ch, err := conn.Channel()
	failOnError(err, "Failed to open a channel")
	defer ch.Close()

	err = ch.Publish(
		exchange, // exchange
		"",       // routing key
		true,     // mandatory
		false,    // immediate
		amqp.Publishing{
			ContentType: "text/plain",
			Body:        []byte(body),
		})
	failOnError(err, "Failed to publish a message")
}
