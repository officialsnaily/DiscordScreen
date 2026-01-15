# DiscordScreen

A FiveM resource that allows admins to request player screenshots and sends detailed player info to a Discord webhook.  
**Note:** This script is in its early stages and may change at any time. Features may be added, removed, or optimized as development continues.

---

## Features

- **🛡️ Secure Server-Side Uploads:**
  Webhooks are handled entirely on the server. No client-side exposure.
- **Admin Screenshot Command:**  
  Use `/screen [playerId] [reason]` to request a screenshot from a specific player or all players.
- **Rich Discord Integration:**
  Sends the screenshot as an image attachment along with detailed player info (identifiers, health, armor, location, vehicle, etc.).
- **Direct Binary Upload:**
  Does not rely on Imgur or external APIs that might block FiveM servers.
- **Cooldown System:**  
  Prevents screenshot spam by enforcing a configurable cooldown per player.
- **Vehicle & Player Info:**  
  Captures vehicle details, coordinates, and more for context.

---

## Installation

1. **Download or Clone the Repository**
   ```sh
   git clone https://github.com/officialsnaily/DiscordScreen.git
   ```

2. **Add to Your Server Resources**
   Place the `DiscordScreen` folder in your server's `resources` directory.

3. **Configure the Script**
   - Open `server.lua`.
   - Locate the `DISCORD_WEBHOOK` variable at the top of the file.
   - Replace the placeholder with your actual Discord Webhook URL.
     ```lua
     Config.DISCORD_WEBHOOK = "https://discord.com/api/webhooks/....."
     ```

4. **Adjust settings**
   - Open config.lua to change the embed title or cooldowns. Do not put your webhook here.

5. **Ensure Dependency**
   - This script requires [screenshot-basic](https://github.com/citizenfx/screenshot-basic).  
     Make sure it is installed and started before this resource.

6. **Add to server.cfg**
   ```
   ensure screenshot-basic
   ensure DiscordScreen
   ```

---

## Usage

- **Command:**  
  `/screen [playerId] [reason]`
  - `playerId`: The server ID of the player to screenshot. Use `-1` to screenshot all players.
  - `reason`: (Optional) Reason for the screenshot, included in the Discord embed.

- **Permissions:**  
  The command requires the `command.screen` ace permission.
```
add_ace group.admin command.screen allow
```
---

## Configuration

`config.lua` (General Settings)

```lua
Config = {}

-- Title for the Discord embed
Config.EMBED_TITLE = "Player Screenshot"

-- Cooldown in seconds between screenshots per player
Config.SCREENSHOT_COOLDOWN = 10
```
`server.lua` (Sensitive Data)
```
-- SET YOUR WEBHOOK HERE
local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/..."
```
---

## File Structure

- `fxmanifest.lua` – Resource manifest
- `config.lua` – General configuration (Client Safe)
- `server.lua` – Server-side logic & Webhook configuration
- `server_upload.lua` – [NEW] Node.js helper for binary image uploading
- `client.lua` – Client-side logic (gathering info, capturing raw data)

---

## Roadmap & Notice

> **This script is in active development.**  
> Functionality, structure, and performance may change at any time.  
> Features may be added, removed, or optimized as development continues.  
> Contributions and suggestions are welcome!

---

## License

MIT License

---

## Credits

- [Team Snaily](https://snai.ly/team) & [Anton's Workshop](https://discord.gg/hdjbqaazhg) – Original authors
- [screenshot-basic](https://github.com/citizenfx/screenshot-basic) – Screenshot utility

---

## Contributing

Pull requests and issues are welcome! Please open an issue to discuss any major changes before submitting a PR.





> **Tested:** This script has been tested on our live server with 30+ players.

