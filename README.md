# 🗑️ DeleteEdge.bat - Forcefully Remove Microsoft Edge

This batch script attempts to **completely remove Microsoft Edge** from Windows systems. It performs multiple actions to ensure Microsoft Edge is deleted and stays deleted:

### 🔧 What It Does
- Runs with **Administrator privileges**
- Uninstalls Microsoft Edge using:
  - `Remove-AppxPackage` (for UWP versions)
  - `winget` (for classic installs, if available)
- Deletes all related folders:
  - `C:\Program Files\Microsoft\Edge`
  - `C:\Program Files (x86)\Microsoft\Edge`
  - User AppData locations
- Removes related registry keys (both 32-bit and 64-bit views)
- Creates a **PowerShell recovery script** that runs at system startup:
  - Rechecks if Edge is still installed
  - Attempts removal again if it is
- **Restarts your system** automatically to finish cleanup

---

> ⚠️ **WARNING**
> 
> This script is extremely aggressive and is designed for advanced users, system administrators, or privacy-focused individuals who understand the implications.
>
> **Removing Microsoft Edge can break some Windows features**, including:
> - Windows Help & Feedback
> - Widgets / News & Interests
> - Some login screens or embedded web content
>
> ⚠️ Use at your own risk. You are responsible for any system instability or loss of functionality.

---

### 💡 Requirements
- Windows 10 or 11
- Administrator access
- Optional: `winget` installed

---

### 📂 How to Use
1. Download `DeleteEdge.bat`
2. Right-click > **Run as Administrator**
3. Wait for cleanup to finish and the system to reboot

---

### ✅ License
[MIT](LICENSE)
