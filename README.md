# Intel Celeron N3450 (Apollo Lake) TDP Unlock

Automated script to override the factory 6W sustained power clamp (PL1) on Intel Celeron N3450 (Apollo Lake) processors, allowing sustained all-core boost clocks (~2.10–2.20 GHz) under heavy continuous load without dropping back to the 1.10 GHz base frequency.

Tested and verified on the **Lenovo ThinkPad 11e** running Windows 11.

---

## Background

By default, the Celeron N3450 operates under two primary power limits:
* **PL2 (Short-Burst Limit - ~15W):** Allows all 4 cores to boost to ~2.10 GHz for ~28 seconds.
* **PL1 (Long-Duration Limit - 6W):** Once the 28-second timer expires, the CPU drops power draw to 6W, forcing clock speeds down to **1.10–1.40 GHz** during multi-threaded workloads.

Standard tuning tools (ThrottleStop, Intel XTU) do not support the Atom-derived Goldmont architecture. This script directly writes to Model-Specific Registers (MSR) and Memory-Mapped I/O (MMIO) registers at boot to raise the PL1 clamp to **10W** and disable secondary hardware clamps.

---

## Prerequisites

1. **RWEverything (Portable x64)**:
   * Download `RwPortableX64` and extract it to a known directory (e.g., `C:\Tools\RwPortableX64\`).
2. **Disable Microsoft Vulnerable Driver Blocklist** (Windows 11 / 10):
   * Windows blocks RWEverything's low-level ring-0 kernel driver (`RwDrv.sys`) by default.
   * Go to **Windows Security** → **Device Security** → **Core isolation details**.
   * Toggle **Microsoft Vulnerable Driver Blocklist** to **Off**.
   * Restart the machine.
3. **Thermal Paste Repaste (Recommended)**:
   * Raising sustained power draw from 6W to 10W increases thermal output. 
   * Repasting the CPU die with high-performance compound (e.g., Arctic MX-4 / MX-6 / MX-7) or adding a 0.3mm–0.5mm copper shim is strongly advised to prevent thermal throttling at 85°C–90°C.

---

## Script: `unlock_tdp.bat`

Place this script inside your extracted RWEverything directory (alongside `Rw.exe`):

```cmd
@echo off
:: Navigate to script directory
cd /d "%~dp0"

:: Write 10W limit to MSR 0x610 (Use 0x00DD8F00 for 15W)
Rw.exe /Min /Nologo /Stdout /Command="WRMSR 0x610 0x0 0x00DD8A00 0"

:: Clear secondary MMIO power limit clamp at FED170A8
Rw.exe /Min /Nologo /Stdout /Command="W16 0xFED170A8 0000"
