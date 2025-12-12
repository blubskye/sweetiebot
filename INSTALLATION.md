These instructions are for **self-hosting only**.

---

## Prerequisites

### 1. Install Go

Install [Go 1.25 or later](https://golang.org/dl/). Verify your installation:

```bash
go version
```

If Go isn't found, restart your terminal or computer and try again.

### 2. Install MariaDB

Install [MariaDB 10.5 or later](https://downloads.mariadb.org/) (required for utf8mb4 support and modern features).

**Important:** Package managers may ship outdated versions. Verify your version:

```bash
mariadb --version
```

---

## Database Setup

### 3. Import the Database Schema

You need to import two SQL files into MariaDB. Choose one of the methods below:

#### Option A: Command Line (Recommended)

```bash
# Log into MariaDB as root (you'll be prompted for password)
mariadb -u root -p

# Create the database and exit
CREATE DATABASE sweetiebot CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
EXIT;

# Import the schema (run from the sweetiebot directory)
mariadb -u root -p sweetiebot < sweetiebot.sql

# Import timezone data
mariadb -u root -p sweetiebot < sweetiebot_tz.sql
```

#### Option B: One-liner Import

```bash
# Import both files in sequence
mariadb -u root -p -e "CREATE DATABASE IF NOT EXISTS sweetiebot CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;" && \
mariadb -u root -p sweetiebot < sweetiebot.sql && \
mariadb -u root -p sweetiebot < sweetiebot_tz.sql
```

#### Option C: Using a GUI (HeidiSQL, DBeaver, etc.)

1. Connect to your MariaDB server
2. Create a new database called `sweetiebot` with charset `utf8mb4`
3. Select the `sweetiebot` database
4. Run/import `sweetiebot.sql`
5. Run/import `sweetiebot_tz.sql`

#### Verifying the Import

```bash
mariadb -u root -p -e "USE sweetiebot; SHOW TABLES;"
```

You should see approximately 16 tables including `users`, `members`, `chatlog`, etc.

---

## Building Sweetie Bot

### 4. Clone and Build

```bash
# Clone the repository
git clone https://github.com/blackhole12/sweetiebot.git
cd sweetiebot

# Install the forked discordgo dependency
# This project uses a custom fork of discordgo
go get github.com/blackhole12/discordgo@develop

# Build the bot
cd main
go build
```

This creates the executable (`main` on Linux/Mac, `main.exe` on Windows).

**Note about discordgo:** This bot uses a forked version of [discordgo](https://github.com/blackhole12/discordgo) from the original author. If you encounter dependency issues, you may need to manually clone and install the fork:

```bash
# Alternative: manually install the discordgo fork
cd $GOPATH/src/github.com/blackhole12
git clone https://github.com/blackhole12/discordgo.git
cd discordgo
git checkout develop
```

---

## Configuration Files

All configuration files go in the `sweetiebot/main` directory. Create these files:

### 5. Database Connection (`db.auth`)

Create a file called `db.auth` containing your database connection string:

**TCP connection (most common):**
```
root:YOUR_PASSWORD@tcp(127.0.0.1:3306)/sweetiebot?parseTime=true&collation=utf8mb4_general_ci
```

**Unix socket connection:**
```
root:YOUR_PASSWORD@unix(/var/run/mysqld/mysqld.sock)/sweetiebot?parseTime=true&collation=utf8mb4_general_ci
```

Replace `YOUR_PASSWORD` with your actual MariaDB root password (or use a dedicated database user).

### 6. Discord Bot Token (`token`)

1. Go to the [Discord Developer Portal](https://discord.com/developers/applications)
2. Create a new application (or select existing one)
3. Go to the "Bot" section and click "Add Bot"
4. Copy the bot token
5. Create a file called `token` (no file extension) and paste the token

Example token format (replace with your actual token):
```
YOUR_BOT_TOKEN_HERE
```

### 7. Main Guild ID (`mainguild`)

Create a file called `mainguild` (no file extension) containing your Discord server ID.

**How to get your server ID:**
1. Open Discord and go to User Settings → Advanced
2. Enable "Developer Mode"
3. Right-click your server icon → "Copy Server ID"
4. Paste the ID into the `mainguild` file

Example:
```
123456789012345678
```

### 8. Bot Owner ID (`owner`)

Create a file called `owner` (no file extension) containing your Discord user ID.

**How to get your user ID:**
1. Enable Developer Mode (see step 7)
2. Right-click your own username → "Copy User ID"
3. Paste the ID into the `owner` file

Example:
```
987654321098765432
```

This grants you owner-level access to restricted commands like `!update`, `!announce`, and `!dumptables`.

---

## Adding the Bot to Your Server

### 9. Generate an Invite Link

Replace `YOUR_BOT_CLIENT_ID` with your bot's Application ID (found in the Discord Developer Portal under "General Information"):

```
https://discord.com/oauth2/authorize?client_id=YOUR_BOT_CLIENT_ID&scope=bot&permissions=535948390
```

Open this URL in your browser and select your server to add the bot.

---

## Running the Bot

### 10. Start Sweetie Bot

```bash
cd sweetiebot/main
./main        # Linux/Mac
main.exe      # Windows
```

The bot should connect and send you a PM with setup instructions. Run `!setup` in your server (only the server owner or users with the Administrator permission can do this).

---

## Troubleshooting

- **Database connection errors**: Verify your MariaDB is running and credentials in `db.auth` are correct
- **Bot not responding**: Check the bot has proper permissions and the token is valid
- **"mainguild cannot be found"**: Ensure the `mainguild` file exists and contains only the server ID
- **Import errors**: Make sure you're running MariaDB 10.5+ and the `sweetiebot` database exists before importing