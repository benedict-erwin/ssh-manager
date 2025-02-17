# Term.sh - Simple SSH Manager
```text
████████╗███████╗██████╗ ███╗   ███╗   ███████╗██╗  ██╗
╚══██╔══╝██╔════╝██╔══██╗████╗ ████║   ██╔════╝██║  ██║
   ██║   █████╗  ██████╔╝██╔████╔██║   ███████╗███████║
   ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║   ╚════██║██╔══██║
   ██║   ███████╗██║  ██║██║ ╚═╝ ██║██╗███████║██║  ██║
   Just another simple SSH Manager
```

**Term.sh** is a powerful, user-friendly SSH connection manager built with Bash scripting. It securely stores and manages SSH hosts with military-grade encryption (AES-256-CBC), supporting both password and SSH key-based authentication. Designed for sysadmins and developers who frequently work with remote servers, it combines security with workflow efficiency.

## Key Features
🔒 **Secure Storage**  

- Encrypts credentials/keys using OpenSSL AES-256-CBC  
- PBKDF2 key derivation with salt for encryption keys  
- Configuration stored in `~/.config/term-sshman/`  

🖥️ **Host Management**  

- Add/Edit/Delete hosts with alias support  
- Tagging and labeling for organization  
- Startup command injection for personalized workflows  

🎨 **Interactive UI**  

- FZF-powered fuzzy search for hosts  
- Color-coded terminal output (`printc` function)  
- ASCII art headers and table-based help menu  

⚙️ **Validation & Safety**  

- IP/Domain validation regex  
- Port number sanity checks  
- Dependency verification (`sshpass`, `jq`, `fzf`)  

🔗 **Connection Types**  

- Password-based authentication  
- SSH key authentication (.pem files)  
- Custom port support  

🚀 **CI/CD Ready**  

- Dependency installation guidance  
- Configuration file bootstrapping  
- MIT license for easy integration  

## Dependency
- `jq` (JSON processing)  
- `fzf` (fuzzy search)  
- `openssl` (encryption)  
- `sshpass` (password auth) 

## Example Usage

```bash
# Add new host (interactive)
./term.sh --add key

# Connect to host "prod-server"
./term.sh --connect prod-server

# List all hosts (FZF interface)
./term.sh --list
```

## Installation

```bash
git clone https://github.com/benedict-erwin/ssh-manager.git
cd term.sh
chmod +x term.sh

# Install dependencies (Debian/Ubuntu)
sudo apt install jq fzf openssl sshpass
```

## Why Choose Term.sh?

1. **Zero Runtime Overhead**: Pure Bash implementation  
2. **Portable**: Single-file architecture  
3. **Auditable**: <200 line core logic  
4. **Extensible**: Easy JSON schema modification  

## Roadmap
- [ ] Connection Templates  
- [ ] SSH Jump Host Support   
- [ ] Connection Statistics
- [ ] Automated Backup Rotation 
- [ ] DNS-over-HTTPS Lookup 

## Contribution

We highly appreciate contributions from the community. If you have suggestions, bug reports, or want to add new features, please open an **issue** or **pull request**.

## License

This project is licensed under the [MIT License](LICENSE).

---

With **Term.sh**, managing SSH connections becomes easier and more organized. Try it now and experience the convenience!