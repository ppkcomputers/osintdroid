# OSINTDROID

![OSINTDROID Screenshot](pic.png)

**OSINTDROID** is an interactive Bash-based Open Source Intelligence (OSINT) and forensic extraction tool designed for Android devices. Utilizing the Android Debug Bridge (ADB), OSINTDROID provides security researchers, digital forensics examiners, and penetration testers with an automated menu to query critical artifacts directly from a connected Android device—including registered accounts, contact lists, call history, and SMS messages.

---

## Table of Contents
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation & Setup](#installation--setup)
- [How It Works](#how-it-works)
- [ADB Commands Breakdown](#adb-commands-breakdown)
  - [Prerequisite & Device Initialization Commands](#prerequisite--device-initialization-commands)
  - [Option 1: List Registered Emails](#option-1-list-registered-emails)
  - [Option 2: List Phone Contacts](#option-2-list-phone-contacts)
  - [Option 3: Call Logs](#option-3-call-logs)
  - [Option 4: SMS Log](#option-4-sms-log)
- [Usage](#usage)
- [License](#license)

---

## Features

- **Automated ADB Server Initialization:** Automatically checks for and starts the local ADB daemon process.
- **Device Authorization Check:** Identifies whether an authorized Android device is plugged in via USB and ready for debugging.
- **Device Hardware & System Information:** Queries global settings and system properties to dynamically display the connected device's name and model.
- **Interactive TUI Menu:** Keypress-driven interactive console allowing rapid extraction of key device artifacts.
- **Structured Data Formatting:** Uses Linux utilities like `column`, `awk`, and `fmt` to wrap, align, and clean raw content provider query outputs into human-readable tables.

---

## Prerequisites

Before running OSINTDROID, ensure you have the following installed and configured on your host system:

1. **Android Debug Bridge (`adb`):** Must be installed and available in your system `$PATH`.
   - **Arch Linux:** `sudo pacman -S android-tools`
   - **Debian/Ubuntu:** `sudo apt install android-tools-adb`
   - **Fedora:** `sudo dnf install android-tools`
2. **Standard Core Utilities:** `awk`, `grep`, `sort`, `column`, `fmt`.
3. **Target Android Device:**
   - **Developer Options** enabled.
   - **USB Debugging** enabled.
   - Host system authorized via the RSA prompt on the Android device screen.

---

## Installation & Setup

1. Clone or download this repository to your host machine:
   ```bash
   git clone [https://github.com/your-username/osintdroid.git](https://github.com/your-username/osintdroid.git)
   cd osintdroid
