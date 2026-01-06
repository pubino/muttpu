#!/usr/bin/env python3
"""
MuttPU - Mutt Preservation Utility
Interactive tool for managing M365 email via OAuth2
"""

import imaplib
import email
import json
import os
import sys
import subprocess
import time
import argparse
from pathlib import Path
from datetime import datetime
import mailbox

# Color codes for terminal output
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def print_header(text):
    """Print colorized header"""
    print(f"\n{Colors.BOLD}{Colors.CYAN}{'=' * 70}{Colors.ENDC}")
    print(f"{Colors.BOLD}{Colors.CYAN}{text}{Colors.ENDC}")
    print(f"{Colors.BOLD}{Colors.CYAN}{'=' * 70}{Colors.ENDC}\n")

def print_success(text):
    """Print success message"""
    print(f"{Colors.GREEN}✓ {text}{Colors.ENDC}")

def print_error(text):
    """Print error message"""
    print(f"{Colors.RED}✗ {text}{Colors.ENDC}")

def print_warning(text):
    """Print warning message"""
    print(f"{Colors.YELLOW}⚠ {text}{Colors.ENDC}")

def print_info(text):
    """Print info message"""
    print(f"{Colors.BLUE}ℹ {text}{Colors.ENDC}")

# Configuration
TOKEN_FILE = Path.home() / "Downloads/muttpu/token.gpg"
OAUTH2_SCRIPT = "/opt/homebrew/Cellar/neomutt/20260501/share/neomutt/oauth2/mutt_oauth2.py"
IMAP_SERVER = "outlook.office365.com"
EMAIL = "user@example.com"

def test_connectivity():
    """Test network connectivity to Microsoft OAuth endpoints"""
    import urllib.request
    import socket

    try:
        # Test connection with a short timeout
        req = urllib.request.Request("https://login.microsoftonline.com", method="HEAD")
        urllib.request.urlopen(req, timeout=5)
        return True
    except (urllib.error.URLError, socket.timeout, ConnectionRefusedError):
        return False

def get_token():
    """Get OAuth2 access token"""
    result = subprocess.run(
        ["python3", str(OAUTH2_SCRIPT), str(TOKEN_FILE)],
        capture_output=True, text=True
    )
    return result.stdout.strip()

def setup_oauth2():
    """Setup OAuth2 authentication"""
    print_header("OAuth2 Setup for M365")

    # Check for existing token
    if TOKEN_FILE.exists():
        print_warning("Existing OAuth2 token found!")
        print()

        # Try to get token info
        try:
            token = get_token()
            if token:
                print_success("Token file exists and appears valid")

                # Test if it works
                print_info("Testing existing credentials...")
                test_imap = connect_imap(quiet=True)
                if test_imap:
                    test_imap.logout()
                    print_success("Existing credentials work!")
                    print()
                    print(f"{Colors.BOLD}Options:{Colors.ENDC}")
                    print(f"  {Colors.CYAN}1.{Colors.ENDC} Keep existing credentials (recommended)")
                    print(f"  {Colors.CYAN}2.{Colors.ENDC} Re-authorize (get new token)")
                    print(f"  {Colors.CYAN}3.{Colors.ENDC} Delete and start fresh")
                    print()

                    choice = input(f"{Colors.BOLD}Choose option [1-3]:{Colors.ENDC} ").strip()

                    if choice == "1" or choice == "":
                        print_success("Keeping existing credentials")
                        return True
                    elif choice == "2":
                        print_info("Re-authorizing with existing token file...")
                        # Continue to re-auth
                    elif choice == "3":
                        print_warning("Deleting existing token...")
                        TOKEN_FILE.unlink()
                        print_success("Token deleted")
                    else:
                        print_error("Invalid option. Exiting.")
                        return False
                else:
                    print_warning("Existing credentials failed to authenticate")
                    print()
                    print(f"{Colors.BOLD}Options:{Colors.ENDC}")
                    print(f"  {Colors.CYAN}1.{Colors.ENDC} Try to refresh token")
                    print(f"  {Colors.CYAN}2.{Colors.ENDC} Delete and create new token")
                    print()

                    choice = input(f"{Colors.BOLD}Choose option [1-2]:{Colors.ENDC} ").strip()

                    if choice == "1" or choice == "":
                        print_info("Attempting to refresh token...")
                        # Continue to re-auth
                    elif choice == "2":
                        print_warning("Deleting existing token...")
                        TOKEN_FILE.unlink()
                        print_success("Token deleted")
                    else:
                        print_error("Invalid option. Exiting.")
                        return False
            else:
                print_error("Token file exists but appears corrupted")
                print()
                choice = input(f"{Colors.BOLD}Delete and recreate? [Y/n]:{Colors.ENDC} ").strip().lower()
                if choice == "" or choice == "y":
                    TOKEN_FILE.unlink()
                    print_success("Token deleted")
                else:
                    print_info("Exiting without changes")
                    return False
        except Exception as e:
            print_error(f"Error reading token: {e}")
            print()
            choice = input(f"{Colors.BOLD}Delete and recreate? [Y/n]:{Colors.ENDC} ").strip().lower()
            if choice == "" or choice == "y":
                TOKEN_FILE.unlink()
                print_success("Token deleted")
            else:
                print_info("Exiting without changes")
                return False

        print()

    # Test network connectivity
    print_info("Checking network connectivity to Microsoft OAuth servers...")
    if not test_connectivity():
        print()
        print_error("Cannot reach Microsoft OAuth servers!")
        print()
        print_warning("Troubleshooting steps:")
        print(f"  {Colors.YELLOW}1.{Colors.ENDC} Check your internet connection")
        print(f"  {Colors.YELLOW}2.{Colors.ENDC} If on corporate network, try connecting to VPN")
        print(f"  {Colors.YELLOW}3.{Colors.ENDC} Test connectivity: {Colors.CYAN}curl https://login.microsoftonline.com{Colors.ENDC}")
        print(f"  {Colors.YELLOW}4.{Colors.ENDC} Check firewall/proxy settings")
        print()
        print_info("Once connected, run: ./muttpu.py setup")
        return False

    print_success("Network connectivity OK")
    print()
    print_info("This will set up OAuth2 authentication using Thunderbird's credentials.")
    print_info("You'll need to visit a URL and authorize the application.")
    print()

    # Thunderbird's registered OAuth2 credentials
    CLIENT_ID = "9e5f94bc-e8a4-4e73-b8be-63364c29d753"

    cmd = [
        "python3", str(OAUTH2_SCRIPT),
        "--verbose",
        "--authorize",
        "--authflow", "devicecode",
        "--provider", "microsoft",
        "--client-id", CLIENT_ID,
        "--client-secret", "",
        "--email", EMAIL,
        "--encryption-pipe", "gpg --encrypt --default-recipient-self",
        str(TOKEN_FILE)
    ]

    try:
        import re
        import webbrowser

        # Run process and stream output line-by-line
        process = subprocess.Popen(
            cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1
        )

        url = None
        code = None
        browser_opened = False

        # Read output line by line
        for line in process.stdout:
            # Print line immediately so user sees progress
            print(line, end='')

            # Extract URL
            if 'https://' in line and 'microsoft.com' in line:
                url_match = re.search(r'(https://[^\s]+)', line)
                if url_match:
                    url = url_match.group(1)

            # Extract device code
            if 'code' in line.lower():
                code_match = re.search(r'\b([A-Z0-9-]{9,})\b', line)
                if code_match and not code:
                    code = code_match.group(1)

            # Open browser once we have both URL and code
            if url and code and not browser_opened:
                print()
                print_info(f"Device code: {Colors.BOLD}{code}{Colors.ENDC}")
                print_info(f"Opening browser to: {url}")

                try:
                    # Try with code parameter first
                    if '?' not in url:
                        webbrowser.open(f"{url}?otc={code}")
                    else:
                        webbrowser.open(url)
                    print_success("Browser opened - please authorize in the browser window")
                    print()
                except Exception as e:
                    print_warning(f"Could not open browser: {e}")
                    print_info(f"Please visit: {url}")
                    print()

                browser_opened = True

        # Wait for process to complete
        return_code = process.wait()

        if return_code == 0:
            print()
            print_success("OAuth2 setup completed successfully!")
            print_info(f"Token saved to: {TOKEN_FILE}")
            return True
        else:
            print()
            print_error("OAuth2 setup failed")
            return False

    except Exception as e:
        print()
        print_error(f"OAuth2 setup failed: {e}")
        print()
        print_warning("Common issues:")
        print(f"  {Colors.YELLOW}•{Colors.ENDC} Network connectivity - ensure VPN is connected")
        print(f"  {Colors.YELLOW}•{Colors.ENDC} GPG not configured - run: {Colors.CYAN}gpg --gen-key{Colors.ENDC}")
        print(f"  {Colors.YELLOW}•{Colors.ENDC} Authorization not completed in browser")
        return False

def configure_neomutt():
    """Interactive NeoMutt configuration generator"""
    print_header("NeoMutt Configuration Generator")

    print_info("This will create a neomuttrc file for using NeoMutt with OAuth2.")
    print()

    # Get user input
    print(f"{Colors.BOLD}Email Configuration:{Colors.ENDC}\n")

    email = input(f"Email address [{Colors.CYAN}{EMAIL}{Colors.ENDC}]: ").strip()
    if not email:
        email = EMAIL

    imap_server = input(f"IMAP server [{Colors.CYAN}{IMAP_SERVER}{Colors.ENDC}]: ").strip()
    if not imap_server:
        imap_server = IMAP_SERVER

    print()
    smtp_enabled = input(f"Configure SMTP for sending email? [{Colors.CYAN}y/N{Colors.ENDC}]: ").strip().lower()

    smtp_server = ""
    smtp_port = "587"
    if smtp_enabled == "y":
        smtp_server = input(f"SMTP server [{Colors.CYAN}smtp.office365.com{Colors.ENDC}]: ").strip()
        if not smtp_server:
            smtp_server = "smtp.office365.com"
        smtp_port = input(f"SMTP port [{Colors.CYAN}587{Colors.ENDC}]: ").strip()
        if not smtp_port:
            smtp_port = "587"

    print()
    token_file = input(f"OAuth2 token file [{Colors.CYAN}{TOKEN_FILE}{Colors.ENDC}]: ").strip()
    if not token_file:
        token_file = str(TOKEN_FILE)

    oauth2_script = input(f"OAuth2 script [{Colors.CYAN}{OAUTH2_SCRIPT}{Colors.ENDC}]: ").strip()
    if not oauth2_script:
        oauth2_script = str(OAUTH2_SCRIPT)

    print()
    output_file = input(f"Output file [{Colors.CYAN}./neomuttrc{Colors.ENDC}]: ").strip()
    if not output_file:
        output_file = "./neomuttrc"

    # Generate config
    print()
    print_info("Generating NeoMutt configuration...")

    config = f'''# NeoMutt Configuration - Generated by MuttPU
# Email: {email}

# Basic settings
set from = "{email}"
set realname = "{email.split('@')[0]}"

# IMAP settings
set imap_user = "{email}"
set folder = "imaps://{imap_server}/"
set spoolfile = "+INBOX"
set record = "+Sent Items"
set postponed = "+Drafts"
set trash = "+Deleted Items"

# OAuth2 authentication
set imap_authenticators = "xoauth2"
set imap_oauth_refresh_command = "python3 {oauth2_script} {token_file}"

# Keep IMAP connection alive
set imap_keepalive = 300
set mail_check = 120
'''

    if smtp_enabled == "y":
        config += f'''
# SMTP settings
set smtp_url = "smtp://{email}@{smtp_server}:{smtp_port}"
set smtp_authenticators = "xoauth2"
set smtp_oauth_refresh_command = "python3 {oauth2_script} {token_file}"
'''

    config += '''
# Mailbox settings
set mbox_type = Maildir
set timeout = 3
set mail_check_stats

# Interface settings
set sort = threads
set sort_aux = reverse-last-date-received
set pager_index_lines = 10
set pager_context = 3
set menu_scroll
set markers = no

# Cache settings
set header_cache = "~/.cache/neomutt/headers"
set message_cachedir = "~/.cache/neomutt/bodies"

# SSL settings
set ssl_starttls = yes
set ssl_force_tls = yes

# Viewing HTML emails
auto_view text/html
alternative_order text/plain text/enriched text/html

# Key bindings
bind index g noop
bind index gg first-entry
bind index G last-entry
bind pager gg top
bind pager G bottom

# Colors (basic)
color index yellow default ~N
color index blue default ~P
color index red default ~D
'''

    # Write config file
    try:
        with open(output_file, 'w') as f:
            f.write(config)

        print_success(f"Configuration written to: {output_file}")
        print()
        print_info("Next steps:")
        print(f"  {Colors.YELLOW}1.{Colors.ENDC} Review and edit {output_file} as needed")
        print(f"  {Colors.YELLOW}2.{Colors.ENDC} Run: {Colors.CYAN}./muttpu.py setup{Colors.ENDC} (if not already done)")
        print(f"  {Colors.YELLOW}3.{Colors.ENDC} Launch NeoMutt: {Colors.CYAN}neomutt -F {output_file}{Colors.ENDC}")
        print()
        print_warning(f"Note: Make sure {token_file} exists before using NeoMutt")

        return True
    except Exception as e:
        print_error(f"Failed to write configuration: {e}")
        return False

def connect_imap(quiet=False):
    """Connect to IMAP server with OAuth2

    Args:
        quiet: If True, suppress error messages (useful for testing credentials)
    """
    import socket

    try:
        token = get_token()
        if not token:
            if not quiet:
                print_error("Failed to get OAuth2 token")
                print_warning("Token may have expired. Try running: ./muttpu.py setup")
            return None

        auth_string = f'user={EMAIL}\x01auth=Bearer {token}\x01\x01'

        imap = imaplib.IMAP4_SSL(IMAP_SERVER)
        imap.authenticate("XOAUTH2", lambda x: auth_string.encode())
        return imap
    except socket.gaierror:
        if not quiet:
            print_error(f"Cannot resolve hostname: {IMAP_SERVER}")
            print_warning("Check your internet connection or DNS settings")
        return None
    except socket.timeout:
        if not quiet:
            print_error(f"Connection to {IMAP_SERVER} timed out")
            print_warning("Check your internet connection or try connecting to VPN")
        return None
    except ConnectionRefusedError:
        if not quiet:
            print_error(f"Connection refused by {IMAP_SERVER}")
            print_warning("Server may be down or network blocked. Try connecting to VPN")
        return None
    except imaplib.IMAP4.error as e:
        if not quiet:
            error_msg = str(e).lower()
            if "authenticate" in error_msg or "authentication" in error_msg:
                print_error("Authentication failed")
                print_warning("Token may have expired. Try running: ./muttpu.py setup")
            else:
                print_error(f"IMAP error: {e}")
        return None
    except Exception as e:
        if not quiet:
            print_error(f"Failed to connect: {e}")
            print_warning("If the problem persists, try: ./muttpu.py setup")
        return None

def list_mailboxes():
    """List all available mailboxes"""
    import re

    print_header("Your Mailboxes")

    print_info(f"Connecting to {IMAP_SERVER}...")
    imap = connect_imap()
    if not imap:
        return

    status, mailboxes = imap.list()
    if status == "OK":
        mailbox_names = []
        for mailbox in mailboxes:
            decoded = mailbox.decode('utf-8')

            # IMAP LIST format: (flags) "delimiter" mailbox_name
            # or: (flags) "delimiter" "mailbox name with spaces"
            # Pattern: everything after the delimiter
            match = re.match(r'\([^)]*\)\s+"[^"]*"\s+(.+)$', decoded)

            if match:
                name = match.group(1)
                # Remove quotes if present
                if name.startswith('"') and name.endswith('"'):
                    name = name[1:-1]

                # Skip hidden folders
                if name and not name.startswith('.'):
                    mailbox_names.append(name)

        # Sort and display
        mailbox_names.sort()
        for idx, name in enumerate(mailbox_names, 1):
            print(f"{Colors.BOLD}{idx:3d}.{Colors.ENDC} {Colors.CYAN}{name}{Colors.ENDC}")

    # Get INBOX count
    print()
    status, data = imap.select("INBOX", readonly=True)
    if status == "OK":
        count = data[0].decode()
        print_info(f"INBOX: {count} messages")

    imap.logout()

def count_messages(mailbox_name):
    """Count messages in a mailbox"""
    print_header(f"Message Count: {mailbox_name}")

    imap = connect_imap()
    if not imap:
        return 0

    try:
        status, data = imap.select(f'"{mailbox_name}"', readonly=True)
        if status == "OK":
            count = int(data[0].decode())
            print_success(f"{mailbox_name}: {count:,} messages")
            imap.logout()
            return count
        else:
            print_error(f"Failed to select mailbox: {mailbox_name}")
            imap.logout()
            return 0
    except Exception as e:
        print_error(f"Error: {e}")
        imap.logout()
        return 0

def search_by_date(mailbox, year=None, limit=20):
    """Search mailbox by date range"""
    print_header(f"Search: {mailbox}" + (f" (Year {year})" if year else ""))

    imap = connect_imap()
    if not imap:
        return

    imap.select(f'"{mailbox}"', readonly=True)

    # Search criteria
    if year:
        start_date = f"01-Jan-{year}"
        end_date = f"31-Dec-{year}"
        search_criteria = f'SENTSINCE {start_date} SENTBEFORE {end_date}'
        print_info(f"Searching for messages from {year}...")
    else:
        search_criteria = 'ALL'
        print_info("Getting all messages...")

    status, data = imap.uid('search', None, search_criteria)
    uids = data[0].decode().split()

    print_success(f"Found {len(uids)} messages")

    if not uids:
        imap.logout()
        return

    # Sample messages to show date distribution
    print(f"\n{Colors.BOLD}Showing first {min(limit, len(uids))} messages:{Colors.ENDC}\n")
    print(f"{Colors.BOLD}{'UID':<10} {'Date':<20} {'Subject'}{Colors.ENDC}")
    print("-" * 80)

    for uid in uids[:limit]:
        try:
            status, data = imap.uid('fetch', uid, '(BODY[HEADER.FIELDS (DATE SUBJECT)])')
            if status == "OK":
                headers = data[0][1].decode('utf-8', errors='ignore')
                msg = email.message_from_string(headers)
                date_str = msg.get('Date', 'Unknown')
                subject = msg.get('Subject', 'No subject')[:50]

                try:
                    date_obj = email.utils.parsedate_to_datetime(date_str)
                    date_display = date_obj.strftime('%Y-%m-%d %H:%M')
                except:
                    date_display = date_str[:16]

                print(f"{uid:<10} {date_display:<20} {subject}")
        except Exception as e:
            print(f"{uid:<10} {Colors.RED}Error: {e}{Colors.ENDC}")

    if len(uids) > limit:
        print(f"\n{Colors.YELLOW}... and {len(uids) - limit} more messages{Colors.ENDC}")

    imap.logout()

    print()
    print_info(f"To export these messages, use:")
    print(f"  {Colors.BOLD}./muttpu.py export \"{mailbox}\" ~/backup" +
          (f" --year {year}" if year else "") + f"{Colors.ENDC}")

class MailboxExporter:
    """Export mailbox to eml or mbox format"""

    def __init__(self, mailbox_name, output_dir, format="eml", batch_size=100,
                 limit=None, skip=None, range_spec=None, year=None, fresh=False):
        self.mailbox_name = mailbox_name
        self.output_dir = Path(output_dir)
        self.format = format.lower()
        self.batch_size = batch_size
        self.limit = limit
        self.skip = skip
        self.range_spec = range_spec
        self.year = year
        self.fresh = fresh

        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.state_file = self.output_dir / ".export_state.json"
        self.state = self._load_state()
        self.imap = None

    def _load_state(self):
        """Load export state from file"""
        if not self.fresh and self.state_file.exists():
            with open(self.state_file, 'r') as f:
                return json.load(f)
        return {
            "mailbox": self.mailbox_name,
            "format": self.format,
            "exported_uids": [],
            "total_exported": 0,
            "last_updated": None
        }

    def _save_state(self):
        """Save export state to file"""
        self.state["last_updated"] = datetime.now().isoformat()
        with open(self.state_file, 'w') as f:
            json.dump(self.state, f, indent=2)

    def _sanitize_filename(self, text, max_length=50):
        """Sanitize text for use in filename"""
        safe = "".join(c if c.isalnum() or c in (' ', '-', '_') else '_' for c in text)
        return safe[:max_length].strip()

    def export(self):
        """Run the export"""
        print_header(f"Export: {self.mailbox_name}")

        # Connect to IMAP
        print_info("Connecting to IMAP server...")
        token = get_token()
        auth_string = f'user={EMAIL}\x01auth=Bearer {token}\x01\x01'

        self.imap = imaplib.IMAP4_SSL(IMAP_SERVER)
        self.imap.authenticate("XOAUTH2", lambda x: auth_string.encode())

        status, data = self.imap.select(f'"{self.mailbox_name}"', readonly=True)
        if status != "OK":
            print_error(f"Failed to select mailbox: {self.mailbox_name}")
            return

        total_in_mailbox = int(data[0].decode())
        print_success(f"Connected to {self.mailbox_name} ({total_in_mailbox:,} total messages)")

        # Get UIDs to export
        uids = self._get_uids_to_export()

        if not uids:
            print_warning("No messages to export")
            self.imap.logout()
            return

        print_info(f"Will export {len(uids):,} messages")

        # Check resume
        already_exported = set(self.state.get("exported_uids", []))
        uids_to_export = [uid for uid in uids if uid not in already_exported]

        if len(already_exported) > 0:
            print_warning(f"Resuming: {len(already_exported):,} already exported, {len(uids_to_export):,} remaining")

        if not uids_to_export:
            print_success("All messages already exported!")
            self.imap.logout()
            return

        # Setup output format
        if self.format == "mbox":
            mbox_path = self.output_dir / f"{self._sanitize_filename(self.mailbox_name)}.mbox"
            mbox = mailbox.mbox(str(mbox_path))

        # Export messages
        errors = []
        for idx, uid in enumerate(uids_to_export, 1):
            try:
                # Fetch message
                status, data = self.imap.uid('fetch', uid, '(RFC822)')
                if status != "OK":
                    errors.append((uid, "fetch failed"))
                    continue

                raw_email = data[0][1]
                msg = email.message_from_bytes(raw_email)

                # Save based on format
                if self.format == "eml":
                    self._save_eml(uid, msg)
                else:  # mbox
                    mbox.add(msg)

                # Update state
                self.state["exported_uids"].append(uid)
                self.state["total_exported"] += 1

                # Progress indicator
                pct = (idx / len(uids_to_export)) * 100
                if idx % 10 == 0:
                    print(f"  {Colors.CYAN}[{idx}/{len(uids_to_export)}] {pct:.1f}%{Colors.ENDC} - Exported UID {uid}")

                # Checkpoint save
                if idx % self.batch_size == 0:
                    self._save_state()
                    if self.format == "mbox":
                        mbox.flush()
                    print(f"  {Colors.GREEN}💾 Checkpoint saved ({idx} messages){Colors.ENDC}")

            except Exception as e:
                errors.append((uid, str(e)))

        # Final save
        self._save_state()
        if self.format == "mbox":
            mbox.close()

        # Summary
        print()
        print_success(f"Export complete: {self.state['total_exported']:,} messages")
        print_info(f"Output: {self.output_dir}")

        if errors:
            print_warning(f"Errors: {len(errors)}")
            for uid, err in errors[:5]:
                print(f"  {Colors.RED}- UID {uid}: {err}{Colors.ENDC}")

        self.imap.logout()

    def _get_uids_to_export(self):
        """Get list of UIDs to export based on filters"""
        if self.year:
            # Year-based search
            start_date = f"01-Jan-{self.year}"
            end_date = f"31-Dec-{self.year}"
            search_criteria = f'SENTSINCE {start_date} SENTBEFORE {end_date}'
            status, data = self.imap.uid('search', None, search_criteria)
        else:
            # Get all UIDs
            status, data = self.imap.uid('search', None, 'ALL')

        uids = data[0].decode().split()

        # Apply range/skip/limit
        if self.range_spec:
            start, end = map(int, self.range_spec.split(':'))
            uids = uids[start-1:end]
        else:
            if self.skip:
                uids = uids[self.skip:]
            if self.limit:
                uids = uids[:self.limit]

        return uids

    def _save_eml(self, uid, msg):
        """Save message as EML file"""
        # Get date and subject for filename
        date_str = msg.get('Date', '')
        subject = msg.get('Subject', 'no-subject')

        try:
            date_obj = email.utils.parsedate_to_datetime(date_str)
            date_prefix = date_obj.strftime('%Y%m%d_%H%M%S')
        except:
            date_prefix = datetime.now().strftime('%Y%m%d_%H%M%S')

        safe_subject = self._sanitize_filename(subject)
        filename = f"{date_prefix}_{uid}_{safe_subject}.eml"
        filepath = self.output_dir / filename

        with open(filepath, 'wb') as f:
            f.write(msg.as_bytes())

def interactive_menu():
    """Display interactive menu"""
    print_header("MuttPU - Mutt Preservation Utility")

    print(f"{Colors.BOLD}Available Commands:{Colors.ENDC}\n")
    print(f"  {Colors.CYAN}setup{Colors.ENDC}              - Setup OAuth2 authentication")
    print(f"  {Colors.CYAN}configure{Colors.ENDC}          - Generate NeoMutt configuration file")
    print(f"  {Colors.CYAN}list{Colors.ENDC}               - List all mailboxes")
    print(f"  {Colors.CYAN}count{Colors.ENDC} <mailbox>    - Count messages in mailbox")
    print(f"  {Colors.CYAN}search{Colors.ENDC} <mailbox>   - Search/preview messages")
    print(f"  {Colors.CYAN}export{Colors.ENDC} <mailbox>   - Export mailbox")
    print()
    print(f"{Colors.BOLD}Examples:{Colors.ENDC}\n")
    print(f"  ./muttpu.py setup")
    print(f"  ./muttpu.py configure")
    print(f"  ./muttpu.py list")
    print(f"  ./muttpu.py count \"INBOX\"")
    print(f"  ./muttpu.py search \"Archive\" --year 2024")
    print(f"  ./muttpu.py export \"INBOX\" ~/backup --format mbox")
    print(f"  ./muttpu.py export \"Archive\" ~/backup/archive-2024 --year 2024 --format mbox")
    print()
    print(f"For detailed help: {Colors.CYAN}./muttpu.py --help{Colors.ENDC}")

def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description='MuttPU - Mutt Preservation Utility',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    subparsers = parser.add_subparsers(dest='command', help='Command to run')

    # Setup command
    subparsers.add_parser('setup', help='Setup OAuth2 authentication')

    # Configure command
    subparsers.add_parser('configure', help='Generate NeoMutt configuration file')

    # List command
    subparsers.add_parser('list', help='List all mailboxes')

    # Count command
    count_parser = subparsers.add_parser('count', help='Count messages in mailbox')
    count_parser.add_argument('mailbox', help='Mailbox name')

    # Search command
    search_parser = subparsers.add_parser('search', help='Search/preview messages')
    search_parser.add_argument('mailbox', help='Mailbox name')
    search_parser.add_argument('--year', type=int, help='Filter by year')
    search_parser.add_argument('--limit', type=int, default=20, help='Number of messages to show')

    # Export command
    export_parser = subparsers.add_parser('export', help='Export mailbox')
    export_parser.add_argument('mailbox', help='Mailbox name')
    export_parser.add_argument('output_dir', help='Output directory')
    export_parser.add_argument('--format', choices=['eml', 'mbox'], default='eml', help='Export format')
    export_parser.add_argument('--batch-size', type=int, default=100, help='Checkpoint frequency')
    export_parser.add_argument('--limit', type=int, help='Limit number of messages')
    export_parser.add_argument('--skip', type=int, help='Skip first N messages')
    export_parser.add_argument('--range', help='Export range (e.g., 1:100)')
    export_parser.add_argument('--year', type=int, help='Export messages from specific year')
    export_parser.add_argument('--fresh', action='store_true', help='Start fresh, ignore previous state')

    args = parser.parse_args()

    # No command - show menu
    if not args.command:
        interactive_menu()
        return

    # Check token file exists for all commands except setup and configure
    if args.command not in ['setup', 'configure'] and not TOKEN_FILE.exists():
        print_error("Token file not found!")
        print_info("Please run: ./muttpu.py setup")
        sys.exit(1)

    # Execute command
    if args.command == 'setup':
        setup_oauth2()
    elif args.command == 'configure':
        configure_neomutt()
    elif args.command == 'list':
        list_mailboxes()
    elif args.command == 'count':
        count_messages(args.mailbox)
    elif args.command == 'search':
        search_by_date(args.mailbox, args.year, args.limit)
    elif args.command == 'export':
        exporter = MailboxExporter(
            args.mailbox,
            args.output_dir,
            format=args.format,
            batch_size=args.batch_size,
            limit=args.limit,
            skip=args.skip,
            range_spec=args.range,
            year=args.year,
            fresh=args.fresh
        )
        exporter.export()

if __name__ == "__main__":
    main()
