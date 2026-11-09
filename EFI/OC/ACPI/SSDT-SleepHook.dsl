/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20250404 (32-bit version)
 * Copyright (c) 2000 - 2025 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of C:/Users/Administrator/WorkBuddy/2026-11-07-14-24-56/runs/hackintosh-lan/staging/rapidefi-original/EFI/OC/ACPI/SSDT-SleepHook.aml
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x000000D5 (213)
 *     Revision         0x02
 *     Checksum         0x29
 *     OEM ID           "RAPID"
 *     OEM Table ID     "SLPHOOK"
 *     OEM Revision     0x00000000 (0)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20250404 (539296772)
 */
DefinitionBlock ("", "SSDT", 2, "RAPID", "SLPHOOK", 0x00000000)
{
    External (_SB_.RAPD.PLID, MethodObj)    // 1 Arguments
    External (_SB_.RAPD.WLID, MethodObj)    // 1 Arguments
    External (WSCN, MethodObj)    // 1 Arguments
    External (ZPTS, MethodObj)    // 1 Arguments
    External (ZWAK, MethodObj)    // 1 Arguments

    Method (_PTS, 1, NotSerialized)  // _PTS: Prepare To Sleep
    {
        If (CondRefOf (\_SB.RAPD.PLID))
        {
            \_SB.RAPD.PLID (Arg0)
        }

        ZPTS (Arg0)
    }

    Method (_WAK, 1, Serialized)  // _WAK: Wake
    {
        If (CondRefOf (\_SB.RAPD.WLID))
        {
            \_SB.RAPD.WLID (Arg0)
        }

        If (CondRefOf (\WSCN))
        {
            \WSCN (Arg0)
        }

        Return (ZWAK (Arg0))
    }
}

