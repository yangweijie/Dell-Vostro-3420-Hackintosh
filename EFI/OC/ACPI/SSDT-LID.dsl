/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20250404 (32-bit version)
 * Copyright (c) 2000 - 2025 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of C:/Users/Administrator/WorkBuddy/2026-11-07-14-24-56/runs/hackintosh-lan/staging/rapidefi-original/EFI/OC/ACPI/SSDT-LID.aml
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x0000013E (318)
 *     Revision         0x02
 *     Checksum         0x89
 *     OEM ID           "RAPID"
 *     OEM Table ID     "LID"
 *     OEM Revision     0x00000000 (0)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20250404 (539296772)
 */
DefinitionBlock ("", "SSDT", 2, "RAPID", "LID", 0x00000000)
{
    External (_SB_.LID0, DeviceObj)
    External (_SB_.LID0.XLID, MethodObj)    // 0 Arguments

    Scope (_SB)
    {
        Device (RAPD)
        {
            Name (_ADR, Zero)  // _ADR: Address
            Name (FNOK, Zero)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (PLID, 1, NotSerialized)
            {
                If (_OSI ("Darwin"))
                {
                    If ((Arg0 == 0x03))
                    {
                        \_SB.RAPD.FNOK = One
                    }
                    Else
                    {
                        \_SB.RAPD.FNOK = Zero
                    }
                }
            }

            Method (WLID, 1, NotSerialized)
            {
                If (_OSI ("Darwin"))
                {
                    \_SB.RAPD.FNOK = Zero
                }
            }
        }
    }

    Scope (\_SB.LID0)
    {
        Method (_LID, 0, NotSerialized)  // _LID: Lid Status
        {
            If (_OSI ("Darwin"))
            {
                If ((\_SB.RAPD.FNOK == One))
                {
                    Return (Zero)
                }
                Else
                {
                    Return (\_SB.LID0.XLID ())
                }
            }
            Else
            {
                Return (\_SB.LID0.XLID ())
            }
        }
    }
}

