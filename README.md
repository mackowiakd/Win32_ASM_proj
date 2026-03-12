# Win32 ASM Dashboard & Vulnerability Case Study

This repository contains a native 32-bit Windows application written entirely in **x86 Assembly (MASM32)**. It serves as both a functional system dashboard and a security educational tool.

## 🚀 Key Features
* **Pure x86 Assembly GUI:** Built using the Win32 API without high-level frameworks.
* **Real-time System Timer:** Displays local time on the window title bar using `SetTimer`.
* **Process Management:** Integrates external tools by spawning child processes.
* **Manual String Parsing:** Custom pointer arithmetic to parse user-input dates, identifying '.' delimiters.

## 🛠️ Interoperability: Process Management
The application features a "Calculator" module that demonstrates **OS-level process management**.
* **Mechanism:** Uses the `CreateProcess` function to launch an external executable.
* **Integration:** Spawns a custom-built **Win32 API Calculator** (written in pure C) as a child process.
* **Resource Management:** Implements proper handle closing (`CloseHandle`) to prevent resource leaks after process creation.

> **Note:** The integrated Calculator app is sourced from my other repository: [win_api](https://github.com/mackowiakd/win_api).

## ⚠️ Security Analysis: Buffer Overflow (Vulnerable by Design)
This project is a **Vulnerability Case Study**. It intentionally retains an **Out-of-Bounds Write / Buffer Overflow** vulnerability for educational purposes. 

User input is stored in a fixed-size buffer:
```assembly
userDate db 20 dup(0)
```

## How to Run
Ensure main.exe and Calculator.exe (from the win_api repo) are in the same directory.

Run main.exe.

Click the Calculator button to spawn the C-based sub-process.

