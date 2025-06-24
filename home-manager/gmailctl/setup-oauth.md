# Gmail OAuth Setup for gmailctl

Follow these steps to set up OAuth authentication for gmailctl. You only need to do this once - the same credentials.json can be used for both accounts.

## 1. Go to Google Cloud Console
Visit: https://console.developers.google.com

## 2. Create or Select a Project
- If you don't have a project, create a new one
- Name it something like "gmailctl" or "personal-gmail-filters"

## 3. Enable Gmail API
- Go to "Enable APIs and services"
- Search for "Gmail API"
- Click on it and press "Enable"

## 4. Configure OAuth Consent Screen
- Go to "OAuth consent screen" in the left sidebar
- Choose User Type:
  - **Internal**: If you have a Google Workspace account
  - **External**: For personal Gmail accounts
- Fill in the required fields:
  - App name: "gmailctl"
  - User support email: Your email
  - Developer contact: Your email
- Click "Add or Remove Scopes" and add these exact scopes:
  - `https://www.googleapis.com/auth/gmail.labels`
  - `https://www.googleapis.com/auth/gmail.settings.basic`
- Save and continue

## 5. Create OAuth Credentials
- Go to "Credentials" in the left sidebar
- Click "Create Credentials" → "OAuth client ID"
- Application type: "Desktop app"
- Name: "gmailctl"
- Click "Create"

## 6. Download Credentials
- Click the download button (⬇) next to your new OAuth client
- Save the file as `credentials.json`
- Move it to: `~/.gmailctl/credentials.json`

## 7. Complete Setup
Run: `gmailctl init`

This will open a browser for authentication. Grant the requested permissions.

## Next Steps
Once authenticated, you can:
- `gmailctl diff` - See what changes would be made
- `gmailctl apply` - Apply the filter configuration
- `gmailctl export` - Export your current Gmail filters