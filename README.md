# Intel Celeron N3450 (Apollo Lake) TDP Unlock

A lightweight script to override the factory 6W sustained power clamp (PL1) on Intel Celeron N3450 processors. This forces the CPU to maintain its all-core boost frequency (~2.10–2.20 GHz) indefinitely under continuous load instead of thermal/power throttling down to 1.10 GHz after 28 seconds.

Tested and verified on the **Lenovo ThinkPad 11e** running Windows 11.

---

## How It Works

* **Factory Behavior:** The N3450 allows a short boost window (PL2 ~15W) for 28 seconds, then clamps down to a strict **6W** limit (PL1), forcing all four cores down to **1.10–1.40 GHz**.
* **Unlocked Behavior:** Writing directly to Model-Specific Register `0x610` (`MSR_PKG_POWER_LIMIT`) and clearing the secondary MMIO register raises the ceiling to **10W**, giving the cores enough electrical headroom to sustain ~2.10 GHz.

---

## Prerequisites

1. **RWEverything Portable (x64)**:
   * Download and extract `RwPortableX64` to a permanent folder (e.g., `C:\Tools\RwPortableX64\`).
2. **Disable Microsoft Vulnerable Driver Blocklist**:
   * Windows 11 blocks RWEverything’s direct hardware access driver (`RwDrv.sys`) by default.
   * Open **Windows Security** → **Device Security** → **Core isolation details**.
   * Toggle **Microsoft Vulnerable Driver Blocklist** to **Off** and restart.
3. **Thermal Headroom**:
   * A fresh application of high-performance thermal paste (e.g., Arctic MX-4/MX-6/MX-7) or a copper shim mod is strongly advised to keep sustained temperatures under 80°C.

---

## File: `unlock_tdp.bat`

Save the following code as `unlock_tdp.bat` directly inside your `RwPortableX64` directory (in the same folder as `Rw.exe`):

```cmd
@echo off
:: Ensure working directory is the script location
cd /d "%~dp0"

:: Write 10W limit to MSR 0x610 (Use 0x00DD8F00 for 15W)
Rw.exe /Min /Nologo /Stdout /Command="WRMSR 0x610 0x0 0x00DD8A00 0"

:: Clear secondary MMIO power limit clamp at 0xFED170A8
Rw.exe /Min /Nologo /Stdout /Command="W16 0xFED170A8 0000"
```

Warning: Always keep the 0x hex prefix on register addresses. Omitting 0x causes RWEverything to interpret the input as decimal (querying unmapped MSR 0x262), which triggers an immediate kernel General Protection Fault (#GP) and reboots the machine.

Automatic Startup Configuration (Windows Task Scheduler)

Because CPU registers are volatile, they reset back to the factory 6W clamp on every shutdown, reboot, or wake-from-sleep event. Follow these steps to automate the script:
1. Create the Task

    Press Win + R, type taskschd.msc, and press Enter.

    Click Create Task in the right-hand panel (do not select Create Basic Task).

2. General Tab

    Name: N3450_TDP_Unlock

    Check Run with highest privileges (Mandatory: Ring-0 register writes require elevated administrative rights).

    Configure for: Windows 10 / Windows 11.

3. Triggers Tab

Add two separate triggers so the script fires on boot and after waking from sleep:

    Trigger 1 (System Boot):

        Click New → Set Begin the task to At log on (or At startup).

        Click OK.

    Trigger 2 (Wake from Sleep):

        Click New → Set Begin the task to On an event.

        Set Log to System.

        Set Source to Power-Troubleshooter.

        Set Event ID to 1.

        Click OK.

4. Actions Tab

    Click New → Action: Start a program.

    Program/script: Browse to your unlock_tdp.bat file.

    Start in (optional): Enter the folder path where Rw.exe lives (e.g., C:\Tools\RwPortableX64).

    Click OK.

5. Conditions Tab

    Uncheck Start the task only if the computer is on AC power (allows the unlock to apply when running on battery).

    Uncheck Stop if the computer switches to battery power.

    Click OK to save the task.

## Verification Methods
1. Direct Register Read-Back

Open Command Prompt as Administrator inside your RWEverything directory and run:
DOS 

Rw.exe /Min /Stdout /Command="RDMSR 0x610"

    Expected Output:
    Plaintext

    Read MSR 0x610: High 32bit(EDX) = 0x00000000, Low 32bit(EAX) = 0x00DD8A00

    Status Checks:

        Low 32bit(EAX) = 0x00DD8A00: Confirms the 10W target register is written and active.

        High 32bit(EDX) = 0x00000000: Confirms Bit 63 (Lock Bit) is 0. The BIOS did not lock the register at boot.

2. Sustained 60-Second All-Core Stress Test

    Open portable CPU-Z and open Task Manager (Ctrl + Shift + Esc) to the Performance → CPU tab.

    In CPU-Z, go to the Bench tab and click Stress CPU.

    Let the benchmark run past 45–60 seconds while watching the clock speed:

        Stock Behavior (Failed/Locked): Clocks drop hard to 1.10–1.40 GHz at the 28-second mark.

        Unlocked Behavior (Success): Clocks stay locked at 2.10–2.20 GHz continuously.

3. Live Package Wattage (HWiNFO64)

    Open HWiNFO64 in Sensors-only mode.

    Scroll to the CPU section and observe the CPU Package Power sensor while running the CPU-Z stress test:

        Stock Behavior: Bursts to ~12–15W, then falls and locks flat at 6.00W.

        Unlocked Behavior: Sustains between 9.00W and 10.50W throughout the entire test.

## Thermal Safety Guidelines

Operating the N3450 at 10W draws more power through the motherboard VRMs and cooling assembly. Use a lightweight monitoring tool like Core Temp (configured with a 2000–3000ms polling rate) to verify sustained temperatures under full load remain below 80°C. The processor will trigger hardware-level thermal throttling (PROCHOT) if temperatures reach 85°C–90°C.
