# mt7621-mt7915
mt7915 DBDC drivers for mt7621 openwrt devices.

This is forked from https://github.com/bricco1981/mt7621-mtk7915

# 改动和修正
 - luci-app-mtwifi 对mt7615.1.2G.dat 和mt7615.1.5G.dat作了变动，
配置默认打开Openwrt_5G/2G ApCliEnable=1
而不是通过apcli.sh和mtkwifi reload关闭再打开。
ifconfig 拉起rax0/apclix0/ra0/apcli0集成在apcli.sh ， 并且拉起前要检测br-lan已就绪，拉起后，
强制将rax0/ra0 加入br-lan本地桥接，虽然，mtkwifi reload也做相同操作，但多加一次更可靠。

- 针对web lua脚本修正
  在扫描无线AP时，会出现断网卡死，原因可能是iwpriv {devname} SiteSurvey阻塞，并且调用iwpriv {devname} get_site_survey
  可能存在死锁冲突导致tcp断连与浏览器AJAX请求，现改成两次AJAX请求，第一次只触发SiteSurvey, 客户端在超时5秒后才调用get_site_survey
  去取AP list结果表。

# 编译mt7915驱动配置注意
1. AP / STA / APSTA不能同时选择，否则，2.4G频道可能会发生tx阻塞，推荐仅勾选AP+STA
2. First / Second Interface 都选MT7915
3. 在路由web中的无线设置(MTK)界面中如果出现5G/2.4G顺序相反问题，试着取消勾选5G default profile for DBDC
