package main

import (
	"flag"
	"fmt"
	"os"

	log "github.com/sirupsen/logrus"
)

func usage() {
	fmt.Fprintf(os.Stderr, "Usage... <items>\n"+
		"where <items> is the not currently used\n\nOptions...\n")

	flag.PrintDefaults()
}

type Config struct {
	FlagSet  *flag.FlagSet
	LogLevel *string
	Verbose  *bool
}

func setup() *Config {
	config := &Config{}
	// Log as JSON instead of the default ASCII formatter.
	log.SetFormatter(&log.JSONFormatter{})

	config.LogLevel = flag.String("log-level", "info", "logging level.")
	config.Verbose = flag.Bool("verbose", false, "set verbose output mode, defaults to off.")

	config.FlagSet = flag.CommandLine
	flag.Usage = usage
	flag.Parse()

	level, err := log.ParseLevel(*config.LogLevel)
	if err != nil {
		log.Warnf("failed to set log level %s", err)
		log.Warnf("invalid log level: %s, using default level", *config.LogLevel)
	} else {
		log.SetLevel(level)
	}
	log.Infof("logging at level: %s", log.GetLevel().String())
	return config
}

func main() {
	config := setup()
	if *config.Verbose {
		fmt.Printf("Arguments: %q\n", config.FlagSet.Args())
	}
}
