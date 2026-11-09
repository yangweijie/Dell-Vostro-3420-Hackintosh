/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20250404 (32-bit version)
 * Copyright (c) 2000 - 2025 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of C:/Users/Administrator/WorkBuddy/2026-11-07-14-24-56/runs/hackintosh-lan/staging/rapidefi-original/EFI/OC/ACPI/SSDT-BATC.aml
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x0000061D (1565)
 *     Revision         0x02
 *     Checksum         0x30
 *     OEM ID           "RAPID"
 *     OEM Table ID     "BATC"
 *     OEM Revision     0x00000000 (0)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20250404 (539296772)
 */
DefinitionBlock ("", "SSDT", 2, "RAPID", "BATC", 0x00000000)
{
    External (_SB_.BAT0, DeviceObj)
    External (_SB_.BAT0._BIF, MethodObj)    // 0 Arguments
    External (_SB_.BAT0._BST, MethodObj)    // 0 Arguments
    External (_SB_.BAT0._HID, IntObj)
    External (_SB_.BAT0._STA, MethodObj)    // 0 Arguments
    External (_SB_.BAT1, DeviceObj)
    External (_SB_.BAT1._BIF, MethodObj)    // 0 Arguments
    External (_SB_.BAT1._BST, MethodObj)    // 0 Arguments
    External (_SB_.BAT1._HID, IntObj)
    External (_SB_.BAT1._STA, MethodObj)    // 0 Arguments
    External (_SB_.PC00.LPCB.ECDV, DeviceObj)
    External (_SB_.XBAT, MethodObj)    // 2 Arguments
    External (_SB_.XTEV, MethodObj)    // 2 Arguments
    External (APRE, IntObj)
    External (ECG5, MethodObj)    // 0 Arguments

    Scope (\_SB)
    {
        Device (BATC)
        {
            Name (_HID, EisaId ("PNP0C0A") /* Control Method Battery */)  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Method (_INI, 0, NotSerialized)  // _INI: Initialize
            {
                If (_OSI ("Darwin"))
                {
                    If (CondRefOf (^^BAT0._HID))
                    {
                        ^^BAT0._HID = Zero
                    }

                    If (CondRefOf (^^BAT1._HID))
                    {
                        ^^BAT1._HID = Zero
                    }
                }
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin"))
                {
                    Local0 = Zero
                    Local0 |= ^^BAT0._STA ()
                    Local0 |= ^^BAT1._STA ()
                    Return (Local0)
                }

                Return (Zero)
            }

            Name (B0CO, Zero)
            Name (B1CO, Zero)
            Name (B0DV, Zero)
            Name (B1DV, Zero)
            Method (_BIF, 0, NotSerialized)  // _BIF: Battery Information
            {
                Local0 = ^^BAT0._BIF ()
                Local2 = ^^BAT0._STA ()
                If ((0x1F == Local2))
                {
                    Local4 = DerefOf (Local0 [One])
                    If ((!Local4 || (Ones == Local4)))
                    {
                        Local2 = Zero
                    }

                    Local4 = DerefOf (Local0 [0x02])
                    If ((!Local4 || (Ones == Local4)))
                    {
                        Local2 = Zero
                    }

                    Local4 = DerefOf (Local0 [0x04])
                    If ((!Local4 || (Ones == Local4)))
                    {
                        Local2 = Zero
                    }
                }

                Local1 = ^^BAT1._BIF ()
                Local3 = ^^BAT1._STA ()
                If ((0x1F == Local3))
                {
                    Local4 = DerefOf (Local1 [One])
                    If ((!Local4 || (Ones == Local4)))
                    {
                        Local3 = Zero
                    }

                    Local4 = DerefOf (Local1 [0x02])
                    If ((!Local4 || (Ones == Local4)))
                    {
                        Local3 = Zero
                    }

                    Local4 = DerefOf (Local1 [0x04])
                    If ((!Local4 || (Ones == Local4)))
                    {
                        Local3 = Zero
                    }
                }

                If (((0x1F != Local2) && (0x1F == Local3)))
                {
                    Local0 = Local1
                    Local2 = Local3
                    Local3 = Zero
                }

                If (((0x1F == Local2) && (0x1F == Local3)))
                {
                    Local4 = DerefOf (Local0 [One])
                    Local5 = DerefOf (Local1 [One])
                    If (((0xFFFFFFFF != Local4) && (0xFFFFFFFF != Local5)))
                    {
                        Local0 [One] = (Local4 + Local5)
                    }

                    Local4 = DerefOf (Local0 [0x02])
                    Local5 = DerefOf (Local1 [0x02])
                    If (((0xFFFFFFFF != Local4) && (0xFFFFFFFF != Local5)))
                    {
                        Local0 [0x02] = (Local4 + Local5)
                    }

                    Local4 = DerefOf (Local0 [0x04])
                    Local5 = DerefOf (Local1 [0x04])
                    If (((0xFFFFFFFF != Local4) && (0xFFFFFFFF != Local5)))
                    {
                        Local0 [0x04] = ((Local4 + Local5) / 0x02)
                    }

                    Local0 [0x05] = (DerefOf (Local0 [0x05]) + DerefOf (
                        Local1 [0x05]))
                    Local0 [0x06] = (DerefOf (Local0 [0x06]) + DerefOf (
                        Local1 [0x06]))
                    Local4 = DerefOf (Local0 [0x07])
                    Local5 = DerefOf (Local1 [0x07])
                    If (((0xFFFFFFFF != Local4) && (0xFFFFFFFF != Local5)))
                    {
                        Local0 [0x07] = (Local4 + Local5)
                    }

                    Local4 = DerefOf (Local0 [0x08])
                    Local5 = DerefOf (Local1 [0x08])
                    If (((0xFFFFFFFF != Local4) && (0xFFFFFFFF != Local5)))
                    {
                        Local0 [0x08] = (Local4 + Local5)
                    }

                    Local0 [0x09] = Concatenate (Concatenate (DerefOf (Local0 [0x09]), 
                        " / "), DerefOf (Local1 [0x09]))
                    Local0 [0x0A] = Concatenate (Concatenate (DerefOf (Local0 [0x0A]), 
                        " / "), DerefOf (Local1 [0x0A]))
                    Local0 [0x0B] = Concatenate (Concatenate (DerefOf (Local0 [0x0B]), 
                        " / "), DerefOf (Local1 [0x0B]))
                    Local0 [0x0C] = Concatenate (Concatenate (DerefOf (Local0 [0x0C]), 
                        " / "), DerefOf (Local1 [0x0C]))
                }

                Return (Local0)
            }

            Method (_BST, 0, NotSerialized)  // _BST: Battery Status
            {
                Local0 = ^^BAT0._BST ()
                Local2 = ^^BAT0._STA ()
                If ((0x1F == Local2))
                {
                    Local4 = DerefOf (Local0 [0x02])
                    If ((!Local4 || (Ones == Local4)))
                    {
                        Local2 = Zero
                    }
                }

                Local1 = ^^BAT1._BST ()
                Local3 = ^^BAT1._STA ()
                If ((0x1F == Local3))
                {
                    Local4 = DerefOf (Local1 [0x02])
                    If ((!Local4 || (Ones == Local4)))
                    {
                        Local3 = Zero
                    }
                }

                If (((0x1F != Local2) && (0x1F == Local3)))
                {
                    Local0 = Local1
                    Local2 = Local3
                    Local3 = Zero
                }

                If (((0x1F == Local2) && (0x1F == Local3)))
                {
                    Local4 = DerefOf (Local0 [Zero])
                    Local5 = DerefOf (Local1 [Zero])
                    If ((Local4 != Local5))
                    {
                        If (((Local4 == 0x02) || (Local5 == 0x02)))
                        {
                            Local0 [Zero] = 0x02
                        }
                        ElseIf (((Local4 == One) || (Local5 == One)))
                        {
                            Local0 [Zero] = One
                        }
                        ElseIf (((Local4 == 0x03) || (Local5 == 0x03)))
                        {
                            Local0 [Zero] = 0x03
                        }
                        ElseIf (((Local4 == 0x04) || (Local5 == 0x04)))
                        {
                            Local0 [Zero] = 0x04
                        }
                        ElseIf (((Local4 == 0x05) || (Local5 == 0x05)))
                        {
                            Local0 [Zero] = 0x05
                        }
                    }

                    Local0 [One] = (DerefOf (Local0 [One]) + DerefOf (
                        Local1 [One]))
                    Local0 [0x02] = (DerefOf (Local0 [0x02]) + DerefOf (
                        Local1 [0x02]))
                    Local0 [0x03] = ((DerefOf (Local0 [0x03]) + DerefOf (
                        Local1 [0x03])) / 0x02)
                }

                Return (Local0)
            }
        }

        Method (BTEV, 2, NotSerialized)
        {
            If (_OSI ("Darwin"))
            {
                If ((Arg0 == One))
                {
                    If ((Arg1 == Zero))
                    {
                        Notify (BATC, 0x81) // Information Change
                    }

                    If ((Arg1 == One))
                    {
                        Notify (BATC, 0x81) // Information Change
                    }
                }

                If ((Arg0 == 0x02))
                {
                    If ((Arg1 == Zero))
                    {
                        Notify (BATC, 0x80) // Status Change
                        Notify (BATC, 0x81) // Information Change
                    }

                    If ((Arg1 == One))
                    {
                        Notify (BATC, 0x80) // Status Change
                        Notify (BATC, 0x81) // Information Change
                    }
                }

                If ((Arg0 == 0x03))
                {
                    If ((Arg1 == Zero))
                    {
                        Notify (BATC, 0x80) // Status Change
                    }

                    If ((Arg1 == One))
                    {
                        Notify (BATC, 0x80) // Status Change
                    }
                }

                If ((Arg0 == 0x04))
                {
                    Notify (BATC, 0x80) // Status Change
                }
            }
            Else
            {
                XTEV (Arg0, Arg1)
            }
        }

        Method (CBAT, 2, NotSerialized)
        {
            If (_OSI ("Darwin"))
            {
                Notify (BATC, 0x81) // Information Change
                Local0 = \ECG5 ()
                \APRE = (Local0 & 0x2B)
            }
            Else
            {
                XBAT (Arg0, Arg1)
            }
        }
    }
}

