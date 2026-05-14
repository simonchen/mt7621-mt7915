include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-mtwifi
PKG_LICENSE:=GPLv2
PKG_MAINTAINER:=Hua Shao <nossiac@163.com>

LUCI_TITLE:=LuCI support for mt wifi driver
LUCI_PKGARCH:=all
PKG_VERSION:=1
PKG_RELEASE:=8

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-mtwifi
	TITLE:=LuCI Support for mtk wifi
	DEPENDS:=+l1profile
endef

define Package/l1profile
  TITLE:=l1profile init script
endef

define Package/l1profile/install
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/lib/wifi/
	$(INSTALL_DIR) $(1)/etc/wireless/mt7615/
	$(INSTALL_DIR) $(1)/etc_ro/Wireless/RT2860AP/
	$(INSTALL_BIN) ./files/l1profile.dat $(1)/etc/wireless/
	$(INSTALL_BIN) ./files/mt7615.1.2G.dat $(1)/etc/wireless/mt7615/
	$(INSTALL_BIN) ./files/mt7615.1.5G.dat $(1)/etc/wireless/mt7615/
	$(INSTALL_BIN) ./files/mt7615.lua $(1)/lib/wifi
	$(INSTALL_BIN) ./files/firmware.sh $(1)/etc/init.d/
	$(INSTALL_BIN) ./files/apcli.sh $(1)/etc/init.d/
endef

define Build/Prepare
	$(foreach po,$(wildcard ${CURDIR}/files/*.po), \
		po2lmo $(po) $(PKG_BUILD_DIR)/$(patsubst %.po,%.lmo,$(notdir $(po)));)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/luci-app-mtwifi/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/mtkwifi.*.lmo $(1)/usr/lib/lua/luci/i18n/

	[ -d ./luasrc ] && $(CP) ./luasrc/* $(1)/usr/lib/lua/luci/ 2>/dev/null || true
	[ -d ./root ] && $(CP) ./root/* $(1)/ 2>/dev/null || true
endef

#include $(TOPDIR)/feeds/luci/luci.mk
$(eval $(call BuildPackage,luci-app-mtwifi))
$(eval $(call BuildPackage,l1profile))
# call BuildPackage OpenWrt buildroot signature
