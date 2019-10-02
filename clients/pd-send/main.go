/*
 *  This is a basic client that can plug into Nagios.
 */
package main

import (
	"encoding/json"
	"fmt"
	"hash/crc32"
	"log"
	"os"
	"strings"
	"strconv"

	"github.com/jessevdk/go-flags"
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

	var opts struct {
		RoutingKey string `short:"k" long:"service-key" description:"Routing key to send to" required:"true"`
		EventAction string `short:"t" long:"event-type" description:"Event Action" default:"trigger" choice:"trigger" choice:"acknowledge" choice:"resolve"`
		Summary string `short:"d" long:"description" description:"Payload summary" required:"true"`
		DedupKey string `short:"i" long:"incident-key" description:"Deduplication key"`
		Client string `short:"c" long:"client" description:"Client Name"`
		ClientURL string `short:"u" long:"client-url" description:"Client URL"`
		Source string `short:"s" long:"source" description:"Payload source" default:"Unknown source"`
		Severity string `short:"p" long:"severity" description:"Payload severity" default:"critical" choice:"critical" choice:"error" choice:"warning" choice:"info"`
		Parallelism int `short:"l" long:"parallelism" description:"MUST be same as plugin parallelism setting" default:"0"`
		Fields []string `short:"f" long:"field" description:"Add given KEY=VALUE pair to the event details"`
	}

	_, err := flags.Parse(&opts)
	if err != nil {
	    os.Exit(1)
	}

	m["routing_key"] = opts.RoutingKey
	m["event_action"] = opts.EventAction
	if opts.DedupKey != "" {
		m["dedup_key"] = opts.DedupKey
	}

	if opts.Client != "" {
		m["client"] = opts.Client
	}
	if opts.ClientURL != "" {
		m["client_url"] = opts.ClientURL
	}

	payload := make(map[string]interface{})
	payload["summary"] = opts.Summary
	payload["source"] = opts.Source
	payload["severity"] = opts.Severity

	if len(opts.Fields) > 0 {
		custom_details := make(map[string]interface{})
		for _, field := range opts.Fields {
			field_split := strings.SplitN(field, "=", 2)
			if len(field_split) == 2 {
				custom_details[field_split[0]] = field_split[1]
			} else {
				fmt.Println("Warning: field argument '" + field + "' is not in KEY=VALUE form, ignoring.")
			}
		}
		payload["custom_details"] = custom_details
	}

	m["payload"] = payload


	body, err := json.Marshal(m)
	failOnError(err, "Could not encode JSON")

	amqp_routing_key := ""
	if opts.Parallelism > 0 {
		hash := crc32.ChecksumIEEE([]byte(opts.RoutingKey + opts.DedupKey))
		partition := (int(hash) % opts.Parallelism) + 1
		amqp_routing_key = strconv.Itoa(partition)
	}

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
	var message = "Event Processed."
	if routing_key != "" {
		message += " Routed to queue " + routing_key + "."
	}
	fmt.Println(message)
}
