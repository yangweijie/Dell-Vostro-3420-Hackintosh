/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20250404 (32-bit version)
 * Copyright (c) 2000 - 2025 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of C:/Users/Administrator/WorkBuddy/2026-11-07-14-24-56/runs/hackintosh-lan/staging/rapidefi-original/EFI/OC/ACPI/SSDT-WakeScreen.aml
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x0000005C (92)
 *     Revision         0x02
 *     Checksum         0x42
 *     OEM ID           "RAPID"
 *     OEM Table ID     "WakeS"
 *     OEM Revision     0x00000000 (0)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20250404 (539296772)
 */
DefinitionBlock ("", "SSDT", 2, "RAPID", "WakeS", 0x00000000)
{
    External (_SB_.LID0, DeviceObj)

    Method (WSCN, 1, NotSerialized)
    {
        If (_OSI ("Darwin"))
        {
            If ((Arg0 == 0x03))
            {
                Notify (\_SB.LID0, 0x80) // Status Change
            }
        }
    }
}

