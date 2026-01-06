#!/bin/bash
# MuttPU Installation Script
# Usage: curl -sSL https://raw.githubusercontent.com/pubino/muttpu/main/install.sh | bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo ""
    echo -e "${BOLD}${CYAN}========================================${NC}"
    echo -e "${BOLD}${CYAN}$1${NC}"
    echo -e "${BOLD}${CYAN}========================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_header "MuttPU Installation"

# Check for macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS"
    print_info "You can still manually install MuttPU on other systems"
    exit 1
fi

print_success "Running on macOS"

# Check for Homebrew
print_info "Checking for Homebrew..."
if command -v brew &> /dev/null; then
    print_success "Homebrew is installed ($(brew --version | head -n1))"
else
    print_warning "Homebrew is not installed"
    echo ""
    echo -e "${BOLD}Homebrew is required to install dependencies.${NC}"
    echo ""

    # Check if user has sudo access
    HAS_SUDO=false
    if sudo -n true 2>/dev/null; then
        HAS_SUDO=true
    else
        # Try to get sudo access
        echo -e "${YELLOW}Checking for administrator privileges...${NC}"
        if sudo -v 2>/dev/null; then
            HAS_SUDO=true
        fi
    fi

    if [ "$HAS_SUDO" = false ]; then
        print_warning "No sudo access detected"
        echo ""
        echo -e "${BOLD}Standard Homebrew installation requires administrator access.${NC}"
        echo ""
        echo -e "${YELLOW}Options:${NC}"
        echo -e "  ${CYAN}1.${NC} Install to home directory (no sudo required)"
        echo -e "  ${CYAN}2.${NC} Cancel and get sudo access"
        echo ""
        read -p "Choose option [1/2]: " -n 1 -r
        echo

        if [[ $REPLY == "1" ]]; then
            print_info "Installing Homebrew to ~/homebrew (user-local installation)..."
            echo ""
            echo -e "${CYAN}This will install Homebrew without requiring administrator access.${NC}"
            echo -e "${CYAN}Installation directory: ~/homebrew${NC}"
            echo ""

            # Create homebrew directory
            mkdir -p ~/homebrew

            # Download and extract Homebrew
            cd ~/homebrew
            curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip-components 1

            # Add to PATH
            BREW_PATH="$HOME/homebrew/bin"
            export PATH="$BREW_PATH:$PATH"

            # Add to shell profile
            SHELL_PROFILE=""
            if [ -f "$HOME/.zshrc" ]; then
                SHELL_PROFILE="$HOME/.zshrc"
            elif [ -f "$HOME/.bash_profile" ]; then
                SHELL_PROFILE="$HOME/.bash_profile"
            elif [ -f "$HOME/.bashrc" ]; then
                SHELL_PROFILE="$HOME/.bashrc"
            fi

            if [ -n "$SHELL_PROFILE" ]; then
                if ! grep -q "homebrew/bin" "$SHELL_PROFILE"; then
                    echo "" >> "$SHELL_PROFILE"
                    echo "# Homebrew (user-local installation)" >> "$SHELL_PROFILE"
                    echo 'export PATH="$HOME/homebrew/bin:$PATH"' >> "$SHELL_PROFILE"
                    print_success "Added Homebrew to $SHELL_PROFILE"
                fi
            fi

            print_success "Homebrew installed to ~/homebrew"
            print_info "You may need to restart your shell or run: source $SHELL_PROFILE"
        else
            print_error "Installation cancelled. Please obtain administrator access and try again."
            exit 1
        fi
    else
        read -p "Would you like to install Homebrew now? [Y/n] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            print_info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

            # Add Homebrew to PATH for Apple Silicon
            if [[ $(uname -m) == "arm64" ]]; then
                echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
                eval "$(/opt/homebrew/bin/brew shellenv)"
            fi

            print_success "Homebrew installed"
        else
            print_error "Installation cancelled. Homebrew is required."
            exit 1
        fi
    fi
fi

# Check for NeoMutt
print_info "Checking for NeoMutt..."
if command -v neomutt &> /dev/null; then
    print_success "NeoMutt is installed ($(neomutt -v | head -n1))"
else
    print_warning "NeoMutt is not installed"
    echo ""
    read -p "Would you like to install NeoMutt? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        print_info "Installing NeoMutt..."
        brew install neomutt
        print_success "NeoMutt installed"
    else
        print_error "NeoMutt is required for OAuth2 authentication"
        exit 1
    fi
fi

# Check for GPG
print_info "Checking for GPG..."
if command -v gpg &> /dev/null; then
    print_success "GPG is installed ($(gpg --version | head -n1))"
else
    print_warning "GPG is not installed"
    echo ""
    read -p "Would you like to install GPG? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        print_info "Installing GPG..."
        brew install gnupg
        print_success "GPG installed"
    else
        print_error "GPG is required for token encryption"
        exit 1
    fi
fi

# Check if GPG key exists
print_info "Checking for GPG key..."
if gpg --list-secret-keys 2>&1 | grep -q "sec"; then
    print_success "GPG key found"
else
    print_warning "No GPG key found"
    echo ""
    echo -e "${BOLD}A GPG key is required to encrypt OAuth2 tokens.${NC}"
    echo ""
    read -p "Would you like to generate a GPG key now? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        print_info "Generating GPG key..."
        echo ""
        echo -e "${CYAN}Please follow the prompts to create your GPG key.${NC}"
        echo -e "${CYAN}You can use default values for most options.${NC}"
        echo ""
        gpg --full-generate-key
        print_success "GPG key generated"
    else
        print_warning "You'll need to generate a GPG key before using MuttPU"
        print_info "Run: gpg --full-generate-key"
    fi
fi

# Clone or update repository
INSTALL_DIR="$HOME/Downloads/muttpu"
print_info "Setting up MuttPU in $INSTALL_DIR..."

if [ -d "$INSTALL_DIR" ]; then
    print_warning "MuttPU directory already exists"
    echo ""
    read -p "Would you like to update it? [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        print_info "Updating MuttPU..."
        cd "$INSTALL_DIR"
        git pull
        print_success "MuttPU updated"
    fi
else
    print_info "Cloning MuttPU repository..."
    mkdir -p "$HOME/Downloads"
    git clone https://github.com/pubino/muttpu.git "$INSTALL_DIR"
    print_success "MuttPU cloned to $INSTALL_DIR"
fi

# Make script executable
chmod +x "$INSTALL_DIR/muttpu.py"

# Installation complete
echo ""
print_header "Installation Complete!"

echo -e "${GREEN}✓${NC} All dependencies installed"
echo -e "${GREEN}✓${NC} MuttPU ready to use"
echo ""
echo -e "${BOLD}Next Steps:${NC}"
echo ""
echo -e "  ${CYAN}1.${NC} Navigate to MuttPU directory:"
echo -e "     ${BOLD}cd $INSTALL_DIR${NC}"
echo ""
echo -e "  ${CYAN}2.${NC} Setup OAuth2 authentication:"
echo -e "     ${BOLD}./muttpu.py setup${NC}"
echo ""
echo -e "  ${CYAN}3.${NC} List your mailboxes:"
echo -e "     ${BOLD}./muttpu.py list${NC}"
echo ""
echo -e "  ${CYAN}4.${NC} Export emails:"
echo -e "     ${BOLD}./muttpu.py export \"INBOX\" ~/backup --format mbox${NC}"
echo ""
echo -e "${BLUE}ℹ${NC} For more information, see: ${CYAN}$INSTALL_DIR/README.md${NC}"
echo ""
