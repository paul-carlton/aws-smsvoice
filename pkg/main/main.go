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
	"os"

	"github.com/paul-carlton/goutils/pkg/logging"
	"sigs.k8s.io/controller-runtime/pkg/log/zap"
)

func main() {
	var (
		versionFlag bool
	)

	flag.BoolVar(&versionFlag, "version", false,
		"Show version info and exit")

	flag.Parse()

	logger := logging.NewLogger("aws-smsvoice", &zap.Options{})

	logger.Info("stating")

	if versionFlag {
		os.Exit(0)
	}
}
