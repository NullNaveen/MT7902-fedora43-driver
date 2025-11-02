KVER ?= $(shell uname -r)
KDIR ?= /lib/modules/$(KVER)/build

obj-m += mt76.o
mt76-y := mmio.o util.o trace.o dma.o mac80211.o debugfs.o eeprom.o \
	tx.o agg-rx.o mcu.o wed.o scan.o channel.o pci.o

obj-m += mt76-connac-lib.o
mt76-connac-lib-y := mt76_connac_mcu.o mt76_connac_mac.o mt76_connac3_mac.o

obj-m += mt792x-lib.o
mt792x-lib-y := mt792x_core.o mt792x_mac.o mt792x_trace.o \
	mt792x_debugfs.o mt792x_dma.o mt792x_acpi_sar.o

obj-m += mt7902-common.o
mt7902-common-y := mac.o mcu.o main.o init.o debugfs.o

obj-m += mt7902e.o
mt7902e-y := pci.o pci_mac.o pci_mcu.o

ccflags-y := -I$(src) -Wno-implicit-function-declaration -Wno-incompatible-pointer-types -Wno-error -Wno-return-type -fno-strict-aliasing
CFLAGS_trace.o := -I$(src)
CFLAGS_mt792x_trace.o := -I$(src)

all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
