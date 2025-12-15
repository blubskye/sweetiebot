package main

import (
	"log"
	"net/http"
	_ "net/http/pprof" // Go 1.25 optimization: Enable pprof for profiling and PGO
	"os"
	"strings"

	"github.com/blackhole12/sweetiebot/sweetiebot"
)

func main() {
	// Start pprof server for profiling and PGO profile collection
	// Access at http://localhost:6060/debug/pprof/
	// Collect CPU profile: curl -o default.pgo "http://localhost:6060/debug/pprof/profile?seconds=120"
	go func() {
		log.Println("pprof server starting on :6060")
		if err := http.ListenAndServe("localhost:6060", nil); err != nil {
			log.Printf("pprof server error: %v", err)
		}
	}()

	token, _ := os.ReadFile("token")
	bot := sweetiebot.New(strings.TrimSpace(string(token)))
	if bot != nil {
		bot.Connect()
	}
}
