# Win32 ASM Date Parser & Timer GUI (Vulnerability Case Study)

This project is a native 32-bit Windows application written entirely in **x86 Assembly (MASM32)**. It directly interacts with the Win32 API to create a Graphical User Interface (GUI), handle system timers, and perform manual string parsing.

Currently, this project serves as a **Security & Vulnerability Case Study**, demonstrating how unsafe manual memory management and string operations in low-level languages can lead to memory corruption vulnerabilities.

## 🛠️ Key Technical Features
* **Pure x86 Assembly:** Built using Microsoft Macro Assembler (MASM32).
* **Win32 API Integration:** Direct calls to Windows API for GUI creation, dialog boxes, and message loop handling.
* **Manual String Parsing:** Custom pointer arithmetic to parse user-input dates (identifying '.' delimiters) without relying on high-level libraries.
* **Hardware/System Timers:** Implementation of Windows timers to manage real-time events.

## ⚠️ Security Analysis: Buffer Overflow (Vulnerable by Design)
This application intentionally retains an **Out-of-Bounds Write / Buffer Overflow** vulnerability for educational purposes. 

User input is collected from a text dialog and stored in a fixed-size buffer:
```assembly
userDate db 20 dup(0)
