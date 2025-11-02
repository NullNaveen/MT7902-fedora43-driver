# MT7902 WiFi 6E Driver for Fedora 43 / Kernel 6.17+

## 🎯 Project Goal
Get MediaTek MT7902 WiFi 6E chip working on Fedora 43 (kernel 6.17.4) through driver porting and kernel customization.

## 🔧 Hardware
- **Device:** MediaTek MT7902 WiFi 6E RZ616 (PCI ID: 14c3:7902)
- **System:** ASUS laptop, Fedora 43, kernel 6.17.4-300.fc43.x86_64
- **Issue:** No upstream driver support for MT7902 in kernel 6.17+

## 📋 Methods Attempted

### ✅ Method 1: MCU Workarounds (FAILED)
Modified mt7921e driver with MT7902 PCI ID and added MCU communication bypasses:
- ✅ PCI device detection working
- ✅ Firmware patch loading successful  
- ❌ RAM firmware upload fails
- ❌ WiFi interface not functional

**Blockers:** Deep MCU protocol differences between MT7921 and MT7902

### 🔄 Method 2: Deep Porting (IN PROGRESS)
Porting MT7902-specific driver from kernel 6.16 to kernel 6.17 framework:
- ✅ Driver source extracted from linux-6.16
- ✅ Custom struct definitions preserved (mt7902_dev, mt7902_phy, mt7902_vif)
- ✅ Mass type replacements completed (~30 files)
- ✅ Added ~40 compatibility struct fields
- ✅ Error reduction: 200+ → 50 → 167 (fluctuating)
- ❌ **Current Blocker:** Header ordering - inline functions in `mt792x.h` access incomplete struct types

**Technical Challenge:** 
```
mt792x.h (generic framework) → includes inline functions
    ↓ needs to access
mt7902_dev/phy/vif structs → defined later in mt7902.h
    ↓ creates
"invalid use of undefined type" hard errors
```

**Solutions Being Explored:**
1. Header reorganization to define structs before inline functions
2. Convert inline functions to non-inline (move to .c files)
3. Compatibility layer avoiding struct member access in headers

### 🚧 Method 3: Build Kernel 6.16 (NEXT)
Download and build linux-6.16 kernel where MT7902 driver works natively:
- Higher success probability
- 4-6 hour estimated build time
- Risk: May introduce regressions on newer Fedora 43

## 📁 Repository Structure
```
mt7902_driver/          # Deep porting work (Method 2)
├── *.c, *.h           # MT7902 driver sources from 6.16
├── Makefile           # Build configuration
└── README.md          # This file

kernel-build/           # Kernel 6.16 build (Method 3) - separate branch
```

## 🔍 Key Files Modified
- `mt7902.h` - Custom MT7902 struct definitions + compatibility fields
- `mt792x.h` - Generic framework + forward declarations
- `mt792x_core.c` - Core functionality + moved inline functions
- `mcu.c` - MCU communication
- `Makefile` - Compiler flags for compatibility

## 🐛 Current Status
**Compilation:** ❌ Failing with struct definition ordering issues  
**Runtime:** ⏸️ Not yet tested  
**Bluetooth:** ❌ Not working (same firmware issue)

## 📊 Error Progression
- Initial: ~200+ compilation errors
- After struct additions: 43 errors
- After mass replacements: 27 errors  
- After inline function fixes: 9 errors
- After field additions: 167 errors (new files touched)

## 🎓 What I Learned
1. Kernel driver architecture and struct compatibility
2. C header ordering and inline function limitations
3. MediaTek MT76x driver framework internals
4. Kernel module compilation and dependency resolution
5. MCU firmware loading protocols
6. The importance of matching kernel ABI versions

## 🤝 Contributing
If you have experience with:
- MediaTek MT76x driver internals
- Kernel 6.17+ API changes
- Header reorganization strategies
- MT7902 chip documentation

Please open an issue or PR! Any help is appreciated.

## 📝 Resources
- [Linux MT76 driver repository](https://github.com/torvalds/linux/tree/master/drivers/net/wireless/mediatek/mt76)
- [MT7902 community discussions](https://github.com/OnlineLearningTutorials/mt7902_temp)
- [Kernel compilation guide](https://docs.fedoraproject.org/en-US/quick-docs/kernel/)

## ⚠️ Disclaimer
This is experimental development work. Use at your own risk. Always have a backup kernel to boot from.

## 📜 License
Based on Linux kernel drivers - GPLv2

## 🏁 Timeline
- **Started:** November 2, 2025
- **Expected:** Working driver within 12-24 hours of focused work
- **Status:** Active development

---
*"Don't stop until it works."* 🚀
