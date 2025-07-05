# bpkg - Bash Package Grabber

**bpkg** is a lightweight Bash-based package fetcher and script manager.  
Inspired by tools like [bget](https://github.com/jahwi/bget), `bpkg` helps you download and manage shell scripts or utilities straight from Git repositories or pastebin.

---

## 🚀 Features

- ⚡ **Fast & Simple** – No Python, no Go, just pure Bash.
- 🌐 **Fetch from Anywhere** – Supports Git repositories, raw files, and direct URLs.
- 📦 **Script Management** – Install and organize your scripts in a consistent structure.
- 🔐 **Optional Integrity Checks** – Verify downloads with hash validation.

---

## 📥 Installation

Clone the repository:

```bash
git clone https://github.com/zakunix/bpkg.git
cd bpkg
chmod +x bpkg.sh
# Below step is not necessary, you can just run bpkg.sh and it will work just fine.
sudo mv bpkg /usr/local/bin/
