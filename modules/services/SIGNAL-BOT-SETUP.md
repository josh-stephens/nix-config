# Signal Bot Setup

This guide walks through setting up the Signal CLI bot on ultraviolet.

## Prerequisites

1. Google Voice number (or other phone number for the bot)
2. Access to receive SMS verification codes

## Setup Steps

### 1. Configure your phone number

Edit `/home/joshsymonds/nix-config/hosts/ultraviolet/default.nix` and replace the phone number:

```nix
services.signal-cli-bot = {
  enable = true;
  phoneNumber = "+1234567890"; # Replace with your Google Voice number
  registrationComplete = false;
};
```

Alternatively, for better secrets management:
1. Copy `modules/services/signal-cli-bot-secrets.nix.example` to `signal-cli-bot-secrets.nix`
2. Add your phone number there
3. Import it in ultraviolet's config

### 2. Deploy the configuration

```bash
# First, create the phone number file
sudo mkdir -p /etc/signal-bot
echo "+1234567890" | sudo tee /etc/signal-bot/phone-number
sudo chmod 600 /etc/signal-bot/phone-number
sudo chown signal-cli:signal-cli /etc/signal-bot/phone-number

# Then deploy
cd ~/nix-config
git add -A
sudo nixos-rebuild switch --flake ".#ultraviolet"
```

### 3. Register Signal account

After deployment, you'll see instructions in the activation output. Run:

```bash
# Request verification code (use --voice for Google Voice numbers)
sudo -u signal-cli signal-cli -a +1234567890 register --voice

# Enter the code you receive via voice call
sudo -u signal-cli signal-cli -a +1234567890 verify 123456

# Set a profile name for the bot
sudo -u signal-cli signal-cli -a +1234567890 updateProfile --name "Assistant Bot"
```

### 4. Test the connection

```bash
# Send a test message to yourself
sudo -u signal-cli signal-cli -a +1234567890 send -m "Hello from Signal bot!" +1yourphonenumber
```

### 5. Enable the daemon

Once registration is complete, update the configuration:

1. Edit `/home/joshsymonds/nix-config/hosts/ultraviolet/default.nix`
2. Change `registrationComplete = false;` to `registrationComplete = true;`
3. Run `sudo nixos-rebuild switch --flake ".#ultraviolet"`

The Signal daemon will now run automatically and can receive messages.

## Next Steps

- The bot script placeholder is at `systemd.services.signal-assistant-bot`
- Incoming messages are available via the signal-cli daemon
- You can build your assistant logic to:
  - Parse incoming messages
  - Query Gmail/Calendar via APIs
  - Send responses back via signal-cli

## Troubleshooting

Check service status:
```bash
systemctl status signal-cli-receive
systemctl status signal-assistant-bot
journalctl -u signal-cli-receive -f
```

Signal data is stored in: `/var/lib/signal-cli/`