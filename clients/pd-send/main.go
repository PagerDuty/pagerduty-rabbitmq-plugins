/*
 *  This is a basic client that can plug into Nagios.
 */
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"hash/crc32"
	"log"
	"os"
	"strconv"

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

func makeBody() (string, []byte) {
	m := make(map[string]interface{})

	// Required stuff
	var routing_key = flag.String("routing-key", "", "Routing key to send to")
	var event_action = flag.String("event-action", "trigger", "Event action (default=trigger)")
	var summary = flag.String("summary", "", "Payload summary")
	var source = flag.String("source", "", "Payload source")
	var severity = flag.String("severity", "", "Payload severity")

	// flags for optional stuff
	var parallelism = flag.Int("parallelism", 0, "MUST be same as plugin parallelism setting")

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

	body, err := json.Marshal(m)
	failOnError(err, "Could not encode JSON")

	amqp_routing_key := ""
	if *parallelism > 0 {
		hash := crc32.ChecksumIEEE([]byte(*routing_key))
		partition := (int(hash) % *parallelism) + 1
		amqp_routing_key = strconv.Itoa(partition)
	}
	fmt.Println("Amqp routing key", amqp_routing_key)
	return amqp_routing_key, body
}

func main() {
	url := getEnvWithDefault("PD_SEND_AMQP_URL", "amqp://guest:guest@localhost:5672")
	exchange := getEnvWithDefault("PD_SEND_EXCHANGE", "pd-events-exchange")

	routing_key, body := makeBody()

	conn, err := amqp.Dial(url)
	failOnError(err, "Failed to connect to RabbitMQ")
	defer conn.Close()

	ch, err := conn.Channel()
	failOnError(err, "Failed to open a channel")
	defer ch.Close()

	err = ch.Publish(
		exchange,
		routing_key,
		true,  // mandatory
		false, // immediate
		amqp.Publishing{
			ContentType: "text/plain",
			Body:        body,
		})
	failOnError(err, "Failed to publish a message")
}
