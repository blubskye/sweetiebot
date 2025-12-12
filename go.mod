module github.com/blackhole12/sweetiebot

go 1.25

require (
	github.com/go-sql-driver/mysql v1.8.1
)

// Note: This project uses a forked version of discordgo from github.com/blackhole12/discordgo
// The fork may need to be manually installed or replaced with a more modern discordgo fork.
// If you encounter issues, you may need to use:
//   go mod edit -replace github.com/blackhole12/discordgo=github.com/bwmarrin/discordgo@latest
// However, this may require code changes due to API differences.
