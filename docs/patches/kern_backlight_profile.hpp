// Generic 16-bit PWM curve from WhateverGreen (BSD-3-Clause).
// PNLF UID 16 is the classic WhateverGreen 16-bit PWM device; UID 19 is the
// later custom-profile device. Both select a software brightness table, not
// a panel identity. AppleIntelPanel looks up F<uid>Txxxx in ApplePanels.
#pragma once
#include <stdint.h>
namespace XeBacklightProfile {
constexpr uint8_t curve[] = {
 0x00,0x11,0x00,0x00,0x02,0x8F,0x03,0x53,0x04,0x5A,0x05,0xA1,
 0x07,0xAE,0x0A,0x3D,0x0E,0x14,0x13,0x74,0x1A,0x5E,0x24,0x18,
 0x31,0xA9,0x44,0x59,0x5E,0x76,0x83,0x11,0xB6,0xC7,0xFF,0x7B
};
inline bool eligible(unsigned uid,unsigned minimum,unsigned maximum,bool internal) {
 return internal && (uid==16 || uid==19) && minimum==0 && maximum==65535;
}
}
