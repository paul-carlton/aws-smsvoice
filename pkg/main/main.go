/*

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package main

import (
	"flag"
	"fmt"
	"os"
	"time"

	// +kubebuilder:scaffold:imports

	"github.com/paul-carlton/goutils/logging"
)

const (
	zero  = 0
	one   = 1
	two   = 2
	sixty = 60
)

// LogLevels struct is used by logger setup.
type LogLevels struct {
	Info    bool
	Debug   bool
	Trace   bool
	Highest int
}

// CheckLogLevels checks the log level, logging the level enabled.
func CheckLogLevels(log logr.Logger) LogLevels {
	lvl := LogLevels{
		Info:  log.V(zero).Enabled(),
		Debug: log.V(one).Enabled(),
		Trace: log.V(two).Enabled(),
	}

	for i := 0; i < 100; i++ {
		if !log.V(i).Enabled() {
			log.V(i).Info("log-level enabled", "level", i)
			lvl.Highest = i - 1

			break
		}
	}

	return lvl
}

// NewLogger returns a logger configured the timestamps format is ISO8601.
func NewLogger(logOpts *zap.Options) logr.Logger {
	encCfg := uzap.NewProductionEncoderConfig()
	encCfg.EncodeTime = zapcore.ISO8601TimeEncoder
	encoder := zap.Encoder(zapcore.NewJSONEncoder(encCfg))

	return zap.New(zap.UseFlagOptions(logOpts), encoder).WithName("firecall").WithValues("version", version.Version)
}

func main() { //nolint:funlen // ok
	var (
		metricsAddr             string
		healthAddr              string
		enableLeaderElection    bool
		leaderElectionNamespace string
		logLevel                string
		concurrent              int
		syncPeriod              time.Duration
		listenPort              int
		versionFlag             bool
	)

	log.SetLogger(zap.New())

	scheme := runtime.NewScheme()
	_ = corev1.AddToScheme(scheme)           // nolint:errcheck // ok
	_ = firecallv1alpha1.AddToScheme(scheme) // nolint:errcheck // ok
	_ = extv1.AddToScheme(scheme)            // nolint:errcheck // ok
	_ = rbacv1.AddToScheme(scheme)           // nolint:errcheck // ok

	// +kubebuilder:scaffold:scheme
	flag.StringVar(&metricsAddr, "metrics-addr", ":8080", "The address the metric endpoint binds to.")
	flag.StringVar(
		&leaderElectionNamespace,
		"leader-election-namespace",
		"",
		"Namespace that the controller performs leader election in. defaults to namespace it is running in.",
	)

	flag.BoolVar(&versionFlag, "version", false,
		"Show version info and exit")
	flag.BoolVar(&enableLeaderElection, "enable-leader-election", false,
		"Enable leader election for controller manager. "+
			"Enabling this will ensure there is only one active controller manager.")
	flag.IntVar(&concurrent, "concurrent", 4, "The number of concurrent reconciles per controller.")
	flag.StringVar(&logLevel, "log-level", "info", "Set logging level. Can be debug, info or error.")
	flag.StringVar(&healthAddr, "health-addr", ":9440", "The address the health endpoint binds to.")
	flag.IntVar(&listenPort, "port", 9443, "the port the controller listens on for webhook requests.")

	flag.DurationVar(
		&syncPeriod,
		"sync-period",
		time.Second*sixty,
		"period between reprocessing of all ExecPasss.",
	)

	logOpts := zap.Options{}
	logOpts.BindFlags(flag.CommandLine)

	flag.Parse()

	logger := NewLogger(&logOpts)

	setupLog := logger.WithName("initialization")
	setupLog.Info("command-line flags", "osArgs", os.Args[:1])

	loggerType := fmt.Sprintf("%T", logger)
	lvl := CheckLogLevels(logger)
	setupLog.Info("logger configured", "loggerType", loggerType, "logLevels", lvl)

	setupLog.Info("AWS smsvoice client", "git-commit", version.GitCommit, "build-user", version.BuildUser, "build-time", version.BuildTime)

	if versionFlag {
		os.Exit(0)
	}
}
