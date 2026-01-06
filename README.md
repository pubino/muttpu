# MuttPU - Mail Preservation Utility

Interactive command line tool for locally archiving M365 email with the help of [NeoMutt](https://neomutt.org).

## Quick Start

### Automated Installation

```bash
curl -sSL https://raw.githubusercontent.com/pubino/muttpu/main/install.sh | bash
```

This will:
- Check for and install Xcode Command Line Tools (if needed)
- Check for and install Homebrew (if needed)
- **No sudo required**: Offers user-local Homebrew installation (`~/homebrew`) if you don't have admin access
- Install NeoMutt and GPG dependencies
- Set up GPG key for token encryption
- Clone MuttPU to `~/Downloads/muttpu`
- Guide you through the setup process

### Manual Installation

```bash
# 1. Install Xcode Command Line Tools (if not already installed)
xcode-select --install

# 2. Install Homebrew (if not already installed)
# Visit https://brew.sh or use:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. Install dependencies
brew install neomutt gpg

# 4. Clone repository
git clone https://github.com/pubino/muttpu.git ~/Downloads/muttpu
cd ~/Downloads/muttpu

# 5. Make executable
chmod +x muttpu.py
```

### Using MuttPU

```bash
# 1. Setup OAuth2 authentication (one-time)
./muttpu.py setup

# 2. List your mailboxes
./muttpu.py list

# 3. Export a mailbox
./muttpu.py export "INBOX" ~/backup --format mbox

# 4. Export by year (e.g., all 2024 emails)
./muttpu.py export "Archive" ~/backup/archive-2024 --year 2024 --format mbox

# Optional: Generate NeoMutt config to use NeoMutt client directly
./muttpu.py configure
```

## Features

- ✅ **OAuth2 Authentication** - Secure, modern authentication (no passwords stored)
- ✅ **Interactive & Colorized** - Terminal output with color-coded messages
- ✅ **Export Formats** - EML (individual files) or MBOX (single file)
- ✅ **Resumable Exports** - Can interrupt and resume exports
- ✅ **Incremental Backups** - Only exports new messages
- ✅ **Year-Based Filtering** - Export messages by sent year
- ✅ **Progress Indicator** - Checkpoints and progress indicators

## Installation

### Prerequisites

- macOS (tested on macOS 26.2)
- Python 3
- NeoMutt and GPG (installed via Homebrew)

### Setup

1. **Install dependencies** (if not already installed):
```bash
brew install neomutt gpg
```

2. **Setup OAuth2** (one-time):
```bash
./muttpu.py setup
```

This will:

- Per NeoMutt, use the Thunderbird app's pre-registered OAuth2 App ID
- Display a URL and device code and ask that you visit the URL in a separate browser
- Prompt you to sign in with your M365 credentials and provide the device code
- Save an encrypted token to your local device

## Commands

### Setup OAuth2
```bash
./muttpu.py setup
```

Sets up OAuth2 authentication with M365. Required before using other commands.

### Configure NeoMutt
```bash
./muttpu.py configure
```

Interactively generates a `neomuttrc` configuration file for using NeoMutt with OAuth2.

**Prompts for:**
- Email address
- IMAP server
- SMTP server (optional, for sending email)
- OAuth2 token file location
- OAuth2 script path
- Output file location

**Example session:**
```
Email address [user@example.com]: your.email@domain.com
IMAP server [outlook.office365.com]:
Configure SMTP for sending email? [y/N]: y
SMTP server [smtp.office365.com]:
SMTP port [587]:
OAuth2 token file [~/Downloads/muttpu/token.gpg]:
Output file [./neomuttrc]:
```

After configuration, launch NeoMutt with:
```bash
neomutt -F neomuttrc
```

### List Mailboxes
```bash
./muttpu.py list
```

Displays all available mailboxes and INBOX message count.

**Example Output:**
```
======================================================================
Your Mailboxes
======================================================================

ℹ Connecting to outlook.office365.com...
  1. INBOX
  2. Archive
  3. Sent Items
  4. Deleted Items
  5. Junk Email
  ...

ℹ INBOX: 234 messages
```

### Count Messages
```bash
./muttpu.py count <mailbox>
```

Counts messages in a specific mailbox.

**Examples:**
```bash
./muttpu.py count "INBOX"
./muttpu.py count "Archive"
./muttpu.py count "Sent Items"
```

### Search Messages
```bash
./muttpu.py search <mailbox> [--year YEAR] [--limit N]
```

Search and preview messages from a mailbox.

**Examples:**
```bash
# Show first 20 messages from Archive
./muttpu.py search "Archive"

# Show messages from 2024
./muttpu.py search "Archive" --year 2024

# Show first 50 messages from 2001
./muttpu.py search "Archive" --year 2001 --limit 50
```

**Example Output:**
```
UID        Date                 Subject
--------------------------------------------------------------------------------
1493456    2001-09-15 10:23    Welcome Email
1493457    2001-09-16 14:45    Meeting Notes
...
```

### Export Mailbox
```bash
./muttpu.py export <mailbox> <output_dir> [OPTIONS]
```

Export mailbox to EML or MBOX format.

**Options:**
- `--format {eml,mbox}` - Export format (default: eml)
- `--batch-size N` - Checkpoint frequency (default: 100)
- `--limit N` - Export only first N messages
- `--skip N` - Skip first N messages
- `--range START:END` - Export specific range (e.g., 1:100)
- `--year YEAR` - Export messages from specific year
- `--fresh` - Start fresh, ignore previous export state

**Examples:**

```bash
# Export INBOX to MBOX format
./muttpu.py export "INBOX" ~/backup/inbox --format mbox

# Export Sent Items to EML format
./muttpu.py export "Sent Items" ~/backup/sent --format eml

# Export Archive messages from 2024
./muttpu.py export "Archive" ~/backup/2024 --year 2024 --format mbox

# Test export with first 10 messages
./muttpu.py export "Archive" ~/test --limit 10 --fresh

# Export specific range
./muttpu.py export "Archive" ~/backup --range 1:1000 --format mbox

# Skip first 1000, export next 500
./muttpu.py export "Archive" ~/backup --skip 1000 --limit 500
```

## Export Formats

### EML Format
- One file per message
- Easy to browse and search
- Compatible with many email clients
- Can selectively restore individual messages

**Best for:**
- Long-term archival
- Selective message access
- Migration to other systems

### MBOX Format
- Single file containing all messages
- Standard Unix mail format
- Compact storage
- Works with Thunderbird, mutt, etc.

**Best for:**
- Backups
- Importing into email clients
- Compact storage

## Resume & Incremental Exports

Exports are automatically resumable and incremental:

1. **Resuming Interrupted Exports**
   ```bash
   # Start export
   ./muttpu.py export "Archive" ~/backup --format mbox
   # (Interrupt with Ctrl+C)

   # Resume - same command
   ./muttpu.py export "Archive" ~/backup --format mbox
   # (Continues from where it left off)
   ```

2. **Incremental Backups**
   ```bash
   # First run - exports all messages
   ./muttpu.py export "INBOX" ~/backup --format mbox

   # Later runs - only exports new messages
   ./muttpu.py export "INBOX" ~/backup --format mbox
   ```

State is tracked in `.export_state.json` in the output directory. Delete this file or use `--fresh` to start over.

## Year-Based Exports

Export messages by sent date instead of arrival order:

```bash
# Find messages from 2001
./muttpu.py search "Archive" --year 2001

# Export all messages from 2001
./muttpu.py export "Archive" ~/backup/2001 --year 2001 --format mbox

# Export all years
for year in 2001 2010 2015 2020 2024 2025; do
    ./muttpu.py export "Archive" ~/backup/archive-$year --year $year --format mbox
done
```

**Why use year-based exports?**
Messages are stored by arrival order (UID), not sent date. Year-based filtering searches by the actual sent date in the message header.

## Use Cases

### 1. Complete Mailbox Backup
```bash
./muttpu.py export "INBOX" ~/backups/inbox --format mbox
./muttpu.py export "Sent Items" ~/backups/sent --format mbox
./muttpu.py export "Archive" ~/backups/archive --format mbox
```

### 2. Archiving Old Emails by Year
```bash
./muttpu.py search "Archive" --year 2020
./muttpu.py export "Archive" ~/archives/2020 --year 2020 --format mbox
```

### 3. Testing Before Full Export
```bash
# Test with 10 messages
./muttpu.py export "Archive" ~/test --limit 10 --fresh

# Check the output
ls ~/test/

# If good, do full export
./muttpu.py export "Archive" ~/backup --format mbox
```

### 4. Chunking Large Mailboxes
```bash
# Export in chunks of 10,000 messages
./muttpu.py export "Archive" ~/backup/chunk1 --range 1:10000 --format mbox
./muttpu.py export "Archive" ~/backup/chunk2 --range 10001:20000 --format mbox
./muttpu.py export "Archive" ~/backup/chunk3 --range 20001:30000 --format mbox
```

### 5. Regular Incremental Backups
```bash
#!/bin/bash
# backup-email.sh - Run this weekly/monthly

./muttpu.py export "INBOX" ~/email-backups/inbox --format mbox
./muttpu.py export "Sent Items" ~/email-backups/sent --format mbox
./muttpu.py export "Archive" ~/email-backups/archive --format mbox
```

## Automation Examples

### Nightly Backup Script
```bash
#!/bin/bash
# backup-all-mailboxes.sh

cd ~/Downloads/muttpu

MAILBOXES=("INBOX" "Sent Items" "Archive" "Deleted Items")
OUTPUT_BASE=~/email-backups

for mailbox in "${MAILBOXES[@]}"; do
    safe_name=$(echo "$mailbox" | tr ' ' '_' | tr '/' '_')
    ./muttpu.py export "$mailbox" "$OUTPUT_BASE/$safe_name" --format mbox
done

echo "Backup complete: $(date)"
```

### Year-Based Archive Export
```bash
#!/bin/bash
# archive-by-year.sh

YEARS=(2001 2010 2015 2020 2024 2025 2026)

for year in "${YEARS[@]}"; do
    echo "Exporting year $year..."
    ./muttpu.py export "Archive" ~/archives/archive-$year \
        --year $year --format mbox
done
```

## How It Works

### OAuth2 Authentication
- Uses Thunderbird's pre-registered OAuth2 credentials
- Tokens are encrypted with GPG and stored in `token.gpg`
- Tokens auto-refresh when needed
- No passwords stored in plaintext

### Export State Tracking
The tool creates `.export_state.json` in the output directory:

```json
{
  "mailbox": "INBOX",
  "format": "mbox",
  "exported_uids": ["1", "2", "3", ...],
  "total_exported": 1250,
  "last_updated": "2026-01-05T19:30:00"
}
```

This enables:
- Resumable exports (survives interruptions)
- Incremental backups (only new messages)
- Progress tracking

## Troubleshooting

### "Token file not found"
Run `./muttpu.py setup` first to authenticate.

### "Failed to select mailbox"
Check mailbox name with `./muttpu.py list`. Names are case-sensitive and may need quotes.

### "Authentication failed"
Token may have expired. Re-run `./muttpu.py setup`.

### Export is slow
- Use `--batch-size` to adjust checkpoint frequency
- MBOX format is faster than EML
- Network speed affects download rate

### Want to start over
Use `--fresh` flag:
```bash
./muttpu.py export "INBOX" ~/backup --fresh
```

Or delete `.export_state.json` in the output directory.

### GPG errors
Make sure GPG is installed and initialized:
```bash
brew install gpg
gpg --gen-key  # If you don't have a key
```

## Security Notes

✅ **Secure:**
- OAuth2 tokens encrypted with GPG
- Tokens stored in `token.gpg`
- Tokens auto-refresh when expired
- No passwords stored in plaintext
- Uses industry-standard OAuth2 device flow

⚠️ **Important:**
- Never share your `token.gpg` file
- Keep GPG key secure
- Token expires after inactivity
- Must re-authenticate if token is revoked

## Technical Details

### File Naming (EML format)
Files are named: `YYYYMMDD_HHMMSS_UID_subject.eml`

Example: `20250105_143022_1234_meeting-notes.eml`
- Date: 2025-01-05
- Time: 14:30:22
- UID: 1234
- Subject: meeting-notes

### Progress Indicators
During export:
```
[100/1500] 6.7% - Exported UID 1234
[200/1500] 13.3% - Exported UID 1235
💾 Checkpoint saved (100 messages)
[300/1500] 20.0% - Exported UID 1236
```

## Comparison with Alpine

| Feature | Alpine | MuttPU |
|---------|--------|--------|
| OAuth2 Setup | Automatic | Manual (one-time) |
| IMAP/POP/SMTP | ✅ Yes | ✅ Yes |
| Scriptable | Limited | ✅ Extensive |
| Command-line | Good | ✅ Excellent |
| Batch Operations | Limited | ✅ Extensive |
| M365 | ✅ Works | ✅ Works |
| Export Functionality | Basic | ✅ Advanced |

## Background

This tool was created to enable NeoMutt to connect to M365 using OAuth2 authentication. While NeoMutt doesn't have built-in OAuth2 credentials like Alpine, it successfully works using Thunderbird's public client credentials.

### Key Advantages
1. ✅ Full IMAP/POP/SMTP access to M365
2. ✅ OAuth2 authentication (modern, secure)
3. ✅ No passwords stored
4. ✅ Tokens auto-refresh
5. ✅ Extensive programmability
6. ✅ Command-line automation
7. ✅ Advanced export capabilities
