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

### � Method 3: Build Kernel 6.16 (IN PROGRESS)
Download and build linux-6.16 kernel where MT7902 driver works natively:
- ✅ Kernel source downloaded (146MB)
- ✅ Extracted and verified
- ✅ MT7902 PCI ID (0x7902) **already present** in mt7925 driver!
- ✅ Fedora 6.17.4 config copied as base
- ✅ MT7925E driver enabled as module (CONFIG_MT7925E=m)
- ⏳ **Currently building** with -j8 (8 parallel jobs)
- ⏳ Estimated completion: 1-3 hours
- Higher success probability - MT7902 is natively supported in kernel 6.16
- Risk: May introduce regressions on newer Fedora 43

## 📁 Repository Structure
```
mt7902_driver/          # Deep porting work (Method 2) - main branch
├── *.c, *.h           # MT7902 driver sources from 6.16
├── Makefile           # Build configuration
└── README.md          # This file

~/kernel-6.16-build/    # Kernel 6.16 build (Method 3) - kernel-6.16-build branch
├── linux-6.16/        # Extracted kernel source
│   ├── .config        # Based on Fedora 6.17.4 config
│   ├── build.log      # Live build output
│   └── drivers/net/wireless/mediatek/mt76/mt7925/
│       └── pci.c      # Contains MT7902 PCI ID (0x7902)
└── linux-6.16.tar.xz  # Original kernel tarball (146MB)
```

**Branch Strategy:**
- `main` - Deep porting work preservation (Method 2)
- `kernel-6.16-build` - Kernel build work (Method 3)

## 🔍 Key Files Modified
- `mt7902.h` - Custom MT7902 struct definitions + compatibility fields
- `mt792x.h` - Generic framework + forward declarations
- `mt792x_core.c` - Core functionality + moved inline functions
- `mcu.c` - MCU communication
- `Makefile` - Compiler flags for compatibility

## 🐛 Current Status
**Method 2 (Deep Porting):** ❌ Blocked by C header ordering issues (167 errors)  
**Method 3 (Kernel 6.16 Build):** ⏳ **ACTIVELY BUILDING** - kernel compilation in progress  
**Bluetooth:** ❌ Not working (tied to WiFi firmware issue)

## ⚡ Latest Update (Nov 2, 2025)
**Discovery:** MT7902 (PCI ID 0x7902) is already supported in kernel 6.16's mt7925 driver!
- No driver porting needed
- Building complete kernel 6.16 with native MT7902 support
- Build started: ~67k tokens used (6.7% of budget)
- Build progress: Compiling modules (drivers, filesystems, network stack)

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
- **Method 1 (MCU Workarounds):** Failed after 6+ bypass attempts
- **Method 2 (Deep Porting):** Blocked at header ordering (200+ → 167 errors)
- **Method 3 (Kernel Build):** In progress - ~1-3 hours to completion
- **Expected:** Working driver within 12-24 hours of focused work
- **Status:** Active development - build running, monitoring progress

