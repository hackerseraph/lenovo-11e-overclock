@echo off
:: Write 10W limit to MSR 0x610 (use 0x00DD8F00 for 15W)
Rw.exe /Min /Nologo /Stdout /Command="WRMSR 0x610 0x0 0x00DD8A00 0"
:: Clear secondary MMIO power limit at FED170A8
Rw.exe /Min /Nologo /Stdout /Command="W16 0xFED170A8 0000"
