#!/usr/bin/env lua

--[[
  Associated Stations MTK Wi-Fi

  Supported driver versions:
  5.1.0.0 - MT7615
  4.1.2.0 - MT7603
  3.0.5.0 - MT7612

  https://github.com/Azexios/openwrt-r3p-mtk
]]

local mtkwifis = {}

local old_mode = 0

function mtkwifis.read_pipe(pipe)
	local fp = io.popen(pipe)
	local txt =  fp:read("*a")
	fp:close()
	return txt
end

function mtkwifis.exists(path)
	local fp = io.open(path, "rb")
	if fp then fp:close() end
	return fp ~= nil
end

if old_mode == 1 then
	os.execute("dmesg -c > /dev/null && iwpriv ra0 show stainfo 2>/dev/null; iwpriv rax0 show stainfo 2>/dev/null")
end

function mtkwifis.refresh_sta_table()
    local log_stream = mtkwifis.read_pipe("iwpriv ra0 show stainfo 2>/dev/null && iwpriv rax0 show stainfo 2>/dev/null") or ""
    local sta_table = {}
    local active_mac = nil
    local data_index = 0

    local dhcp_cache = {}
    local dhcp_txt = mtkwifis.read_pipe("cat /tmp/dhcp.leases 2>/dev/null") or ""
    for line in dhcp_txt:gmatch("[^\n]+") do
        local mac, ip, host = line:match("%d+%s+(%S+)%s+(%S+)%s+(%S+)")
        if mac and ip then
            dhcp_cache[mac:lower()] = {
                ip = ip,
                host = (host and host ~= "*") and host or "-"
            }
        end
    end

    for line in log_stream:gmatch("[^\n]+") do
        line = line:gsub("^%s*(.-)%s*$", "%1")

        local found_mac = line:match("([A-Z0-9]%S+:[A-Z0-9]%S+:[A-Z0-9]%S+:[A-Z0-9]%S+:[A-Z0-9]%S+:[A-Z0-9]%S+)")
        
        if found_mac then
            active_mac = found_mac:upper()
            data_index = 0
            local dhcp_info = dhcp_cache[active_mac:lower()] or { ip = "-", host = "-" }
             sta_table[active_mac] = {
                ip   = dhcp_info.ip,
                host = dhcp_info.host
            }
        elseif active_mac then
            data_index = data_index + 1

            if data_index >= 1 and data_index <= 6 then
                local pure_num = line:match("%-?%d+$")
                local num_val = pure_num and tonumber(pure_num) or 0
                
                if data_index == 1 then sta_table[active_mac].aid = num_val
                elseif data_index == 2 then sta_table[active_mac].wcid = num_val
                elseif data_index == 3 then sta_table[active_mac].func_idx = num_val
                elseif data_index == 4 then sta_table[active_mac].ps_mode = num_val
                elseif data_index == 5 then sta_table[active_mac].wmm_cap = num_val
                elseif data_index == 6 then sta_table[active_mac].mmps_mode = num_val
                end

            elseif data_index == 7 then
                sta_table[active_mac].rssi = line:match("[%d%-%/]+") or "?"

            elseif data_index == 8 then
                sta_table[active_mac].phymode = line:match("[%w%_%/]+") or "?"

            elseif data_index == 9 then
                sta_table[active_mac].bw = line:match("[%d%a%/]+") or "?"

            elseif data_index == 10 then
                sta_table[active_mac].mcs = line:match("[%w%-%/]+") or "?"

            elseif data_index == 11 then
                local sgi_left, sgi_right = line:match("(%d)/(%d)")
                sgi_left = sgi_left or "0"
                sgi_right = sgi_right or "0"

                local left_str = (sgi_left == "1") and "Short" or "Long"
                local right_str = (sgi_right == "1") and "Short" or "Long"

                sta_table[active_mac].sgi = left_str .. "/" .. right_str
            elseif data_index == 14 then
                local rate_left, rate_right = line:match("(%d+)/(%d+)")
                if rate_left and rate_right then
                    sta_table[active_mac].rate = rate_left .. "/" .. rate_right .. " Mbit/s"
                else
                    local single_rate = line:match("%d+")
                    sta_table[active_mac].rate = single_rate and (single_rate .. " Mbit/s") or "-"
                end
                active_mac = nil  
            end
        end
    end
    return sta_table
end

function mtkwifis.refresh_sta_table_OBSOLETED()

	-- local log_stream = mtkwifis.read_pipe("dmesg 2>/dev/null") or ""
	local log_stream = mtkwifis.read_pipe("iwpriv ra0 show stainfo 2>/dev/null && iwpriv rax0 show stainfo 2>/dev/null") or ""
	local sta_table = {}
	local active_mac = nil
        local data_index = 0

	for line in log_stream:gmatch("[^\n]+") do
		local found_mac = line:match("([A-Z0-9]%S+:[A-Z0-9]%S+:[A-Z0-9]%S+:[A-Z0-9]%S+:[A-Z0-9]%S+:[A-Z0-9]%S+)")
		
		if found_mac then
			-- 💥 状态机触发：抓到了新的 MAC 地址，立刻激活追踪，重置格子计数器
			active_mac = found_mac
			data_index = 0
			sta_table[active_mac] = {}
		elseif active_mac then
			local pure_num = line:match("%-?%d+$") or line:match("%-?%d+%s*$")
			
			if pure_num then
				data_index = data_index + 1
				local num_val = tonumber(pure_num)
				
				-- 严格按照你给出的 6 行物理 printk 相对垂直顺序，直接定点精准收割！
				if data_index == 1 then
					sta_table[active_mac].aid = num_val       -- 第1行数字 -> Aid
				elseif data_index == 2 then
					sta_table[active_mac].wcid = num_val      -- 第2行数字 -> wcid (你的 AX211 座位号！)
				elseif data_index == 3 then
					sta_table[active_mac].func_idx = num_val  -- 第3行数字 -> func_tb_idx
				elseif data_index == 4 then
					sta_table[active_mac].ps_mode = num_val   -- 第4行数字 -> PsMode
				elseif data_index == 5 then
					sta_table[active_mac].wmm_cap = num_val   -- 第5行数字 -> WMM Cap
				elseif data_index == 6 then
					sta_table[active_mac].mmps_mode = num_val -- 第6行数字 -> MmpsMode (致命的降档省电标志！)
					active_mac = nil -- 💥 6个核心数据全部精准安全收割，平滑关闭当前网卡追踪器
				end
			end
		end
	end

	return sta_table
end

if old_mode == 1 then
if not mtkwifis.exists("/etc/wireless/mt7603/") then -- MT7615
	MAC = mtkwifis.read_pipe("dmesg | grep -oE '([A-Z0-9]{2}:){5}..' 2>/dev/null") or "?"
	RSSI = mtkwifis.read_pipe("dmesg | grep -oE '[^] I]([-0-9 ]{1,}\\/){3}[-0-9]{1,}' 2>/dev/null") or "?"
	BW = mtkwifis.read_pipe("dmesg | grep -oE '([0-9]{2,3}M)\\/[0-9]{2,3}M' 2>/dev/null" ) or "?"
	MCS = mtkwifis.read_pipe("dmesg | sed -nE '/([0-9]{2,3}M)\\/[0-9]{2,3}M/{n;p;}' | awk '{print $NF}' 2>/dev/null" ) or "?" -- BW>MCS
	SGI = mtkwifis.read_pipe("dmesg | sed -nE '/([0-9]{2,3}M)\\/[0-9]{2,3}M/{n;n;p;}' | awk '{print $NF}' | sed 's/0/Long/g;s/1/Short/g' 2>/dev/null" ) or "?" -- BW>SGI
	Rate = mtkwifis.read_pipe("dmesg | awk '/0%/ {print a}{a=$NF \" Mbit/s\"}' 2>/dev/null" ) or "?"

	for _,mac in ipairs(string.split(mtkwifis.read_pipe("dmesg | grep -oE '([A-Z0-9]{2}:){5}..'"), "\n"))
	do
		os.execute("cat /tmp/dhcp.leases | grep -i '"..mac.."' | awk '{print $3\" \"$4}' | grep '.*' >> /tmp/mtk/host || echo - - >> /tmp/mtk/host")
	end

	Host = mtkwifis.read_pipe("awk '{print $2}' /tmp/mtk/host 2>/dev/null") or "?"
	IP = mtkwifis.read_pipe("awk '{print $1}' /tmp/mtk/host 2>/dev/null") or "?"
	os.execute("rm -rf /tmp/mtk/host")
elseif mtkwifis.exists("/etc/wireless/mt7603/") and mtkwifis.exists("/etc/wireless/mt7612/") then -- MT7603+MT7612
	MAC = mtkwifis.read_pipe("dmesg | grep -oE '([A-Z0-9]{2}:){5}..' 2>/dev/null") or "?"
	RSSI = mtkwifis.read_pipe("dmesg | grep -B 14 '100%' | sed '1!G;h;$!d' | sed -nE '/[0-9]{2,3}M/{n;n;p;}' | sed 's/    /\\//g' | awk '{print $NF}' | cut -d '/' -f1-2 | sed '1!G;h;$!d' 2>/dev/null") or "?" -- BW>RSSI
	BW = mtkwifis.read_pipe("dmesg | grep -B 14 '100%' | grep -oE '[0-9]{2,3}M' 2>/dev/null" ) or "?"
	MCS = mtkwifis.read_pipe("dmesg | grep -B 14 '100%' | sed -nE '/[0-9]{2,3}M/{n;p;}' | awk '{print $NF}' 2>/dev/null" ) or "?" -- BW>MCS
	SGI = mtkwifis.read_pipe("dmesg | grep -B 14 '100%' | sed -nE '/[0-9]{2,3}M/{n;n;p;}' | awk '{print $NF}' | sed 's/0/Long/g;s/1/Short/g' 2>/dev/null" ) or "?" -- BW>SGI
	Rate = mtkwifis.read_pipe("dmesg | grep -B 14 '100%' | sed -nE '/[0-9]{2,3}M/{n;n;n;n;n;p;}' | awk '{print $NF \" Mbit/s\"}' 2>/dev/null" ) or "?"

	for _,mac in ipairs(string.split(mtkwifis.read_pipe("dmesg | grep -oE '([A-Z0-9]{2}:){5}..'"), "\n"))
	do
		os.execute("cat /tmp/dhcp.leases | grep -i '"..mac.."' | awk '{print $3\" \"$4}' | grep '.*' >> /tmp/mtk/host || echo - - >> /tmp/mtk/host")
	end

	Host = mtkwifis.read_pipe("awk '{print $2}' /tmp/mtk/host 2>/dev/null") or "?"
	IP = mtkwifis.read_pipe("awk '{print $1}' /tmp/mtk/host 2>/dev/null") or "?"
	os.execute("rm -rf /tmp/mtk/host")
else -- MT7603+MT7615
	MAC = mtkwifis.read_pipe("dmesg | grep -B 23 ' 0%' | grep -oE '([A-Z0-9]{2}:){5}..' 2>/dev/null") or "?"
	MAC2 = mtkwifis.read_pipe("dmesg | grep -B 21 '100%' | grep -oE '([A-Z0-9]{2}:){5}..' 2>/dev/null") or "?"
	RSSI = mtkwifis.read_pipe("dmesg | grep -oE '[^] I]([-0-9 ]{1,}\\/){3}[-0-9]{1,}' 2>/dev/null") or "?"
	RSSI2 = mtkwifis.read_pipe("dmesg | grep -B 14 '100%' | grep -oE '[^] ]([-0-9 ]{1,}\\/)[-0-9 ]{1,}' 2>/dev/null") or "?"
	BW = mtkwifis.read_pipe("dmesg | grep -oE '([0-9]{2,3}M)\\/[0-9]{2,3}M' 2>/dev/null" ) or "?"
	BW2 = mtkwifis.read_pipe("dmesg | grep -B 14 '100%' | grep -oE '[0-9]{2,3}M' 2>/dev/null" ) or "?"
	MCS = mtkwifis.read_pipe("dmesg | sed -nE '/([0-9]{2,3}M)\\/[0-9]{2,3}M/{n;p;}' | awk '{print $NF}' 2>/dev/null" ) or "?" -- BW>MCS
	MCS2 = mtkwifis.read_pipe("dmesg | grep -B 14 '100%' | sed -nE '/[0-9]{2,3}M/{n;p;}' | awk '{print $NF}' 2>/dev/null" ) or "?" -- BW2>MCS2
	SGI = mtkwifis.read_pipe("dmesg | sed -nE '/([0-9]{2,3}M)\\/[0-9]{2,3}M/{n;n;p;}' | awk '{print $NF}' | sed 's/0/Long/g;s/1/Short/g' 2>/dev/null" ) or "?" -- BW>SGI
	SGI2 = mtkwifis.read_pipe("dmesg | grep -B 14 '100%' | sed -nE '/[0-9]{2,3}M/{n;n;p;}' | awk '{print $NF}' | sed 's/0/Long/g;s/1/Short/g' 2>/dev/null" ) or "?" -- BW2>SGI2
	Rate = mtkwifis.read_pipe("dmesg | awk '/ 0%/ {print a}{a=$NF \" Mbit/s\"}' 2>/dev/null" ) or "?"
	Rate2 = mtkwifis.read_pipe("dmesg | awk '/100%/ {print a}{a=$NF \" Mbit/s\"}' 2>/dev/null" ) or "?"

	for _,mac in ipairs(string.split(mtkwifis.read_pipe("dmesg | grep -B 23 ' 0%' | grep -oE '([A-Z0-9]{2}:){5}..'"), "\n"))
	do
		os.execute("cat /tmp/dhcp.leases | grep -i '"..mac.."' | awk '{print $3\" \"$4}' | grep '.*' >> /tmp/mtk/host || echo - - >> /tmp/mtk/host")
	end

	for _,mac2 in ipairs(string.split(mtkwifis.read_pipe("dmesg | grep -B 21 '100%' | grep -oE '([A-Z0-9]{2}:){5}..'"), "\n"))
	do
		os.execute("cat /tmp/dhcp.leases | grep -i '"..mac2.."' | awk '{print $3\" \"$4}' | grep '.*' >> /tmp/mtk/host2 || echo - - >> /tmp/mtk/host2")
	end

	Host = mtkwifis.read_pipe("awk '{print $2}' /tmp/mtk/host 2>/dev/null") or "?"
	Host2 = mtkwifis.read_pipe("awk '{print $2}' /tmp/mtk/host2 2>/dev/null") or "?"
	IP = mtkwifis.read_pipe("awk '{print $1}' /tmp/mtk/host 2>/dev/null") or "?"
	IP2 = mtkwifis.read_pipe("awk '{print $1}' /tmp/mtk/host2 2>/dev/null") or "?"
	os.execute("rm -rf /tmp/mtk/host /tmp/mtk/host2")
	
end
end -- old_mode = 1

return mtkwifis
