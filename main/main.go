package main

import (
	"os"
	"strings"

	"github.com/blackhole12/sweetiebot/sweetiebot"
)

func main() {
	token, _ := os.ReadFile("token")
	bot := sweetiebot.New(strings.TrimSpace(string(token)))
	if bot != nil {
		bot.Connect()
	}
}
