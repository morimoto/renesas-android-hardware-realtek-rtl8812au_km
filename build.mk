src = $(WORKDIR)

# Include generated .config file
-include $(src)/.config

_OS_INTFS_FILES := \
	os_dep/osdep_service.o \
	os_dep/linux/os_intfs.o \
	os_dep/linux/usb_intf.o \
	os_dep/linux/usb_ops_linux.o \
	os_dep/linux/ioctl_linux.o \
	os_dep/linux/xmit_linux.o \
	os_dep/linux/mlme_linux.o \
	os_dep/linux/recv_linux.o \
	os_dep/linux/ioctl_cfg80211.o \
	os_dep/linux/wifi_regd.o \
	os_dep/linux/rtw_android.o \
	os_dep/linux/rtw_proc.o \
	os_dep/linux/rtw_rhashtable.o

ifeq ($(CONFIG_MP_INCLUDED), y)
	_OS_INTFS_FILES += os_dep/linux/ioctl_mp.o
endif

_HAL_INTFS_FILES := \
	hal/hal_intf.o \
	hal/hal_com.o \
	hal/hal_com_phycfg.o \
	hal/hal_phy.o \
	hal/hal_dm.o \
	hal/hal_dm_acs.o \
	hal/hal_btcoex_wifionly.o \
	hal/hal_btcoex.o \
	hal/hal_mp.o \
	hal/hal_mcc.o \
	hal/hal_hci/hal_usb.o \
	hal/led/hal_led.o \
	hal/led/hal_usb_led.o

EXTRA_CFLAGS += -I$(src)/platform
EXTRA_CFLAGS += -I$(src)/hal/btc

_PLATFORM_FILES := platform/platform_ops.o

ifeq ($(CONFIG_BT_COEXIST), y)
	EXTRA_CFLAGS += -I$(src)/hal/btc
	_OUTSRC_FILES += \
		hal/btc/HalBtc8192e1Ant.o \
		hal/btc/HalBtc8192e2Ant.o \
		hal/btc/HalBtc8723b1Ant.o \
		hal/btc/HalBtc8723b2Ant.o \
		hal/btc/HalBtc8812a1Ant.o \
		hal/btc/HalBtc8812a2Ant.o \
		hal/btc/HalBtc8821a1Ant.o \
		hal/btc/HalBtc8821a2Ant.o \
		hal/btc/HalBtc8821aCsr2Ant.o \
		hal/btc/HalBtc8703b1Ant.o \
		hal/btc/halbtc8723d1ant.o \
		hal/btc/halbtc8723d2ant.o \
		hal/btc/HalBtc8822b1Ant.o \
		hal/btc/halbtc8821c1ant.o \
		hal/btc/halbtc8821c2ant.o
endif

########### HAL_RTL8812A_RTL8821A #################################
ifneq ($(CONFIG_RTL8812A)_$(CONFIG_RTL8821A), n_n)
	RTL871X = rtl8812a
	MODULE_NAME = 8812au

	_HAL_INTFS_FILES += \
		hal/HalPwrSeqCmd.o \
		hal/$(RTL871X)/Hal8812PwrSeq.o \
		hal/$(RTL871X)/Hal8821APwrSeq.o\
		hal/$(RTL871X)/$(RTL871X)_xmit.o\
		hal/$(RTL871X)/$(RTL871X)_sreset.o

	_HAL_INTFS_FILES += \
		hal/$(RTL871X)/$(RTL871X)_hal_init.o \
		hal/$(RTL871X)/$(RTL871X)_phycfg.o \
		hal/$(RTL871X)/$(RTL871X)_rf6052.o \
		hal/$(RTL871X)/$(RTL871X)_dm.o \
		hal/$(RTL871X)/$(RTL871X)_rxdesc.o \
		hal/$(RTL871X)/$(RTL871X)_cmd.o \
		hal/$(RTL871X)/usb/usb_halinit.o \
		hal/$(RTL871X)/usb/rtl$(MODULE_NAME)_led.o \
		hal/$(RTL871X)/usb/rtl$(MODULE_NAME)_xmit.o \
		hal/$(RTL871X)/usb/rtl$(MODULE_NAME)_recv.o

	_HAL_INTFS_FILES += \
		hal/$(RTL871X)/usb/usb_ops_linux.o


	ifeq ($(CONFIG_RTL8812A), y)
		_HAL_INTFS_FILES += hal/efuse/$(RTL871X)/HalEfuseMask8812A_USB.o
	endif

	ifeq ($(CONFIG_RTL8821A), y)
		_HAL_INTFS_FILES += hal/efuse/$(RTL871X)/HalEfuseMask8821A_USB.o
	endif

	ifeq ($(CONFIG_RTL8812A), y)
		EXTRA_CFLAGS += -DCONFIG_RTL8812A -DDRV_NAME=\"8812au\"
		_HAL_INTFS_FILES += hal/rtl8812a/hal8812a_fw.o
	endif

	ifeq ($(CONFIG_RTL8821A), y)
		ifeq ($(CONFIG_RTL8812A), n)
			RTL871X = rtl8821a
			ifeq ($(CONFIG_USB_HCI), y)
				ifeq ($(CONFIG_BT_COEXIST), y)
					MODULE_NAME := 8821au
				else
					MODULE_NAME := 8811au
				endif
			endif
		endif

		EXTRA_CFLAGS += -DCONFIG_RTL8821A
		_HAL_INTFS_FILES += hal/rtl8812a/hal8821a_fw.o
	endif
endif

########### HAL_RTL8814A #################################
ifeq ($(CONFIG_RTL8814A), y)
	## ADD NEW VHT MP HW TX MODE ##
	EXTRA_CFLAGS += -DCONFIG_MP_VHT_HW_TX_MODE
	CONFIG_MP_VHT_HW_TX_MODE = y
	##########################################
	RTL871X = rtl8814a
	MODULE_NAME = 8814au


	EXTRA_CFLAGS += -DCONFIG_RTL8814A

	_HAL_INTFS_FILES +=  hal/HalPwrSeqCmd.o \
			hal/$(RTL871X)/Hal8814PwrSeq.o \
			hal/$(RTL871X)/$(RTL871X)_xmit.o\
			hal/$(RTL871X)/$(RTL871X)_sreset.o

	_HAL_INTFS_FILES += hal/$(RTL871X)/$(RTL871X)_hal_init.o \
			hal/$(RTL871X)/$(RTL871X)_phycfg.o \
			hal/$(RTL871X)/$(RTL871X)_rf6052.o \
			hal/$(RTL871X)/$(RTL871X)_dm.o \
			hal/$(RTL871X)/$(RTL871X)_rxdesc.o \
			hal/$(RTL871X)/$(RTL871X)_cmd.o
			hal/$(RTL871X)/hal8814a_fw.o


	_HAL_INTFS_FILES += hal/$(RTL871X)/usb/usb_halinit.o \
			hal/$(RTL871X)/usb/rtl$(MODULE_NAME)_led.o \
			hal/$(RTL871X)/usb/rtl$(MODULE_NAME)_xmit.o \
			hal/$(RTL871X)/usb/rtl$(MODULE_NAME)_recv.o

	HAL_INTFS_FILES += hal/$(RTL871X)/usb/usb_ops_linux.o
	_HAL_INTFS_FILES +=hal/efuse/$(RTL871X)/HalEfuseMask8814A_USB.o

	_OUTSRC_FILES += hal/phydm/$(RTL871X)/halhwimg8814a_bb.o\
			hal/phydm/$(RTL871X)/halhwimg8814a_mac.o\
			hal/phydm/$(RTL871X)/halhwimg8814a_rf.o\
			hal/phydm/$(RTL871X)/halhwimg8814a_fw.o\
			hal/phydm/$(RTL871X)/phydm_iqk_8814a.o\
			hal/phydm/$(RTL871X)/phydm_regconfig8814a.o\
			hal/phydm/$(RTL871X)/halphyrf_8814a_ce.o\
			hal/phydm/$(RTL871X)/phydm_rtl8814a.o\
			hal/phydm/txbf/haltxbf8814a.o
endif
########### END OF PATH  #################################

##### Extra flags setup ######
EXTRA_LDFLAGS += --strip-debug

EXTRA_CFLAGS += -I$(src)/include
EXTRA_CFLAGS += -I$(src)/hal/phydm

EXTRA_CFLAGS += $(USER_EXTRA_CFLAGS) -O3
EXTRA_CFLAGS += -Wall -Wextra
EXTRA_CFLAGS += -Wno-unused-variable -Wno-unused-value -Wno-unused-label
EXTRA_CFLAGS += -Wno-unused-parameter -Wno-unused-function -Wno-unused
EXTRA_CFLAGS += -Wno-date-time -Wno-misleading-indentation -Wno-uninitialized
EXTRA_CFLAGS += -Wno-parentheses-equality -Wno-unknown-warning-option

# Relax some warnings from '-Wextra' so we won't get flooded with warnings
EXTRA_CFLAGS += -Wno-sign-compare
EXTRA_CFLAGS += -Wno-missing-field-initializers
EXTRA_CFLAGS += -Wno-type-limits
EXTRA_CFLAGS += -Wno-header-guard

GCC_VER_49 := $(shell echo `$(CC) -dumpversion | cut -f1-2 -d.` \>= 4.9 | bc )
ifeq ($(GCC_VER_49),1)
	EXTRA_CFLAGS += -Wno-date-time	# Fix compile error && warning on gcc 4.9 and later
endif

EXTRA_CFLAGS += -DCONFIG_LITTLE_ENDIAN -DDM_ODM_SUPPORT_TYPE=0x04

##### DEBUG CONFIGURATION #####
ifeq ($(DEBUG), 1)
	EXTRA_CFLAGS += -DDBG=1 -DCONFIG_RTW_DEBUG -DCONFIG_DBG_COUNTER -DRTW_LOG_LEVEL=4
	EXTRA_CFLAGS += -DCONFIG_RADIOTAP_WITH_RXDESC
else ifeq ($(DEBUG), 2)
	EXTRA_CFLAGS += -DDBG=1 -DCONFIG_RTW_DEBUG -DCONFIG_DBG_COUNTER -DRTW_LOG_LEVEL=5
	EXTRA_CFLAGS += -DCONFIG_DEBUG_RTL871X
	EXTRA_CFLAGS += -DCONFIG_RADIOTAP_WITH_RXDESC
else
	EXTRA_CFLAGS += -DDBG=0
endif

ifeq ($(CONFIG_TXPWR_BY_RATE), n)
	EXTRA_CFLAGS += -DCONFIG_TXPWR_BY_RATE=0
else ifeq ($(CONFIG_TXPWR_BY_RATE), y)
	EXTRA_CFLAGS += -DCONFIG_TXPWR_BY_RATE=1
endif

ifeq ($(CONFIG_TXPWR_BY_RATE_EN), n)
	EXTRA_CFLAGS += -DCONFIG_TXPWR_BY_RATE_EN=0
else ifeq ($(CONFIG_TXPWR_BY_RATE_EN), y)
	EXTRA_CFLAGS += -DCONFIG_TXPWR_BY_RATE_EN=1
else ifeq ($(CONFIG_TXPWR_BY_RATE_EN), auto)
	EXTRA_CFLAGS += -DCONFIG_TXPWR_BY_RATE_EN=2
endif

ifeq ($(CONFIG_TXPWR_LIMIT), n)
	EXTRA_CFLAGS += -DCONFIG_TXPWR_LIMIT=0
else ifeq ($(CONFIG_TXPWR_LIMIT), y)
	EXTRA_CFLAGS += -DCONFIG_TXPWR_LIMIT=1
endif

ifeq ($(CONFIG_TXPWR_LIMIT_EN), n)
	EXTRA_CFLAGS += -DCONFIG_TXPWR_LIMIT_EN=0
else ifeq ($(CONFIG_TXPWR_LIMIT_EN), y)
	EXTRA_CFLAGS += -DCONFIG_TXPWR_LIMIT_EN=1
else ifeq ($(CONFIG_TXPWR_LIMIT_EN), auto)
	EXTRA_CFLAGS += -DCONFIG_TXPWR_LIMIT_EN=2
endif

ifeq ($(CONFIG_MP_INCLUDED), y)
	EXTRA_CFLAGS += -DCONFIG_MP_INCLUDED
endif

ifeq ($(CONFIG_RTW_WIFI_HAL), y)
	EXTRA_CFLAGS += -DCONFIG_RTW_WIFI_HAL
	EXTRA_CFLAGS += -DCONFIG_RTW_CFGVEDNOR_LLSTATS
	EXTRA_CFLAGS += -DCONFIG_RTW_CFGVENDOR_RANDOM_MAC_OUI
	EXTRA_CFLAGS += -DCONFIG_RTW_CFGVEDNOR_RSSIMONITOR
	EXTRA_CFLAGS += -DCONFIG_RTW_CFGVENDOR_WIFI_LOGGER

	ifeq ($(CONFIG_RTW_WIFI_HAL_DEBUG), y)
		EXTRA_CFLAGS += -DCONFIG_RTW_WIFI_HAL_DEBUG
	endif
endif

ifeq ($(CONFIG_ENABLE_DRIVER_WARNINGS), y)
	EXTRA_CFLAGS += -DWARN_ENABLE=1
else
	EXTRA_CFLAGS += -DWARN_ENABLE=0
endif

ifeq ($(CONFIG_USB2_EXTERNAL_POWER), y)
	EXTRA_CFLAGS += -DCONFIG_USE_EXTERNAL_POWER
endif

ifeq ($(CONFIG_USB_HCI), y)
	ifeq ($(CONFIG_USB_AUTOSUSPEND), y)
		EXTRA_CFLAGS += -DCONFIG_USB_AUTOSUSPEND
	endif
endif

ifeq ($(CONFIG_POWER_SAVING), y)
	EXTRA_CFLAGS += -DCONFIG_POWER_SAVING
endif

ifeq ($(CONFIG_HW_PWRP_DETECTION), y)
	EXTRA_CFLAGS += -DCONFIG_HW_PWRP_DETECTION
endif

ifeq ($(CONFIG_BT_COEXIST), y)
	EXTRA_CFLAGS += -DCONFIG_BT_COEXIST
endif

ifeq ($(CONFIG_EFUSE_CONFIG_FILE), y)
	EXTRA_CFLAGS += -DCONFIG_EFUSE_CONFIG_FILE

# EFUSE_MAP_PATH
	USER_EFUSE_MAP_PATH ?=
	ifneq ($(USER_EFUSE_MAP_PATH),)
		EXTRA_CFLAGS += -DEFUSE_MAP_PATH=\"$(USER_EFUSE_MAP_PATH)\"
	else
		EXTRA_CFLAGS += -DEFUSE_MAP_PATH=\"/system/etc/wifi/wifi_efuse_$(MODULE_NAME).map\"
	endif

# WIFI_MAC_PATH
	USER_WIFIMAC_PATH ?=
	ifneq ($(USER_WIFIMAC_PATH),)
		EXTRA_CFLAGS += -DWIFIMAC_PATH=\"$(USER_WIFIMAC_PATH)\"
	else
		EXTRA_CFLAGS += -DWIFIMAC_PATH=\"/data/wifimac.txt\"
	endif
endif

ifeq ($(CONFIG_80211W), y)
	EXTRA_CFLAGS += -DCONFIG_IEEE80211W
endif

ifeq ($(CONFIG_BR_EXT), y)
	BR_NAME = br0
	EXTRA_CFLAGS += -DCONFIG_BR_EXT
	EXTRA_CFLAGS += '-DCONFIG_BR_EXT_BRNAME="'$(BR_NAME)'"'
endif

ifeq ($(CONFIG_ANTENNA_DIVERSITY), y)
	EXTRA_CFLAGS += -DCONFIG_ANTENNA_DIVERSITY
endif

ifeq ($(CONFIG_TDLS), y)
	EXTRA_CFLAGS += -DCONFIG_TDLS
endif

ifeq ($(CONFIG_CONCURRENT_MODE), y)
	EXTRA_CFLAGS += -DCONFIG_CONCURRENT_MODE
endif

ifeq ($(CONFIG_RADIO_WORK), y)
	EXTRA_CFLAGS += -DCONFIG_RADIO_WORK
endif

ifeq ($(CONFIG_IOCTL_CFG80211), y)
	EXTRA_CFLAGS += -DCONFIG_IOCTL_CFG80211
endif

ifeq ($(CONFIG_RTW_USE_CFG80211_STA_EVENT), y)
	EXTRA_CFLAGS += -DRTW_USE_CFG80211_STA_EVENT
endif

ifeq ($(CONFIG_RTW_IOCTL_SET_COUNTRY), y)
	EXTRA_CFLAGS += -DCONFIG_RTW_IOCTL_SET_COUNTRY
endif


ifneq ($(KERNELRELEASE),)

include $(src)/hal/phydm/phydm.mk

	rtk_core := \
		core/rtw_cmd.o \
		core/rtw_security.o \
		core/rtw_debug.o \
		core/rtw_io.o \
		core/rtw_ioctl_query.o \
		core/rtw_ioctl_set.o \
		core/rtw_ieee80211.o \
		core/rtw_mlme.o \
		core/rtw_mlme_ext.o \
		core/rtw_mi.o \
		core/rtw_wlan_util.o \
		core/rtw_vht.o \
		core/rtw_pwrctrl.o \
		core/rtw_rf.o \
		core/rtw_chplan.o \
		core/rtw_recv.o \
		core/rtw_sta_mgt.o \
		core/rtw_ap.o \
		core/mesh/rtw_mesh.o \
		core/mesh/rtw_mesh_pathtbl.o \
		core/mesh/rtw_mesh_hwmp.o \
		core/rtw_xmit.o \
		core/rtw_p2p.o \
		core/rtw_rson.o \
		core/rtw_tdls.o \
		core/rtw_br_ext.o \
		core/rtw_iol.o \
		core/rtw_sreset.o \
		core/rtw_btcoex_wifionly.o \
		core/rtw_btcoex.o \
		core/rtw_beamforming.o \
		core/rtw_odm.o \
		core/rtw_rm.o \
		core/rtw_rm_fsm.o \
		core/efuse/rtw_efuse.o

	ifeq ($(CONFIG_MP_INCLUDED), y)
		rtk_core += core/rtw_mp.o
	endif

	$(MODULE_NAME)-y += $(rtk_core)
	$(MODULE_NAME)-y += $(_OS_INTFS_FILES)
	$(MODULE_NAME)-y += $(_HAL_INTFS_FILES)
	$(MODULE_NAME)-y += $(_PHYDM_FILES)
	$(MODULE_NAME)-y += $(_BTC_FILES)
	$(MODULE_NAME)-y += $(_PLATFORM_FILES)

	obj-m := $(MODULE_NAME).o

else

modules:
	make -C $(KERNELDIR) KBUILD_OUTPUT=$(KERNELDIR) HOSTCC=$(HOSTCC) HOSTCFLAGS=$(HOSTCFLAGS) \
	ARCH=$(ARCH) CC=$(CC) CLANG_TRIPLE=$(CLANG_TRIPLE) CROSS_COMPILE=$(CROSS_COMPILE) M=$(WORKDIR) modules

.PHONY: modules modclean

modclean:
	$(Q) echo "Cleaning module build artifacts"
	$(Q) cd hal ; rm -fr */*/*/*.mod.c */*/*/*.mod */*/*/*.o */*/*/.*.cmd */*/*/*.ko
	$(Q) cd hal ; rm -fr */*/*.mod.c */*/*.mod */*/*.o */*/.*.cmd */*/*.ko
	$(Q) cd hal ; rm -fr */*.mod.c */*.mod */*.o */.*.cmd */*.ko
	$(Q) cd hal ; rm -fr *.mod.c *.mod *.o .*.cmd *.ko
	$(Q) cd core/efuse ; rm -fr *.mod.c *.mod *.o .*.cmd *.ko
	$(Q) cd core ; rm -fr *.mod.c *.mod *.o .*.cmd *.ko
	$(Q) cd os_dep/linux ; rm -fr *.mod.c *.mod *.o .*.cmd *.ko
	$(Q) cd os_dep ; rm -fr *.mod.c *.mod *.o .*.cmd *.ko
	$(Q) cd platform ; rm -fr *.mod.c *.mod *.o .*.cmd *.ko
	$(Q) rm -fr Module.symvers ; rm -fr Module.markers ; rm -fr modules.order
	$(Q) rm -fr *.mod.c *.mod *.o .*.cmd *.ko *~
	$(Q) rm -fr .tmp_versions
	$(Q) rm -rf .tmpconfig*
	$(Q) rm -rf *.tmp
endif
