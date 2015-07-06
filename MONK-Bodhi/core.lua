local addon, ns = ...
local L = ns[1]
local G = ns[2]

if select(2, UnitClass("player")) ~= "MONK" then return end

local Iconsize = 33 -- 图标大小

local font = GameFontHighlight:GetFont()
local mtg
local texture = "Interface\\Buttons\\WHITE8x8"
local power_max = 0
local alpha = .6
local level = 3

local classicon_colors = { --monk/paladin/preist
	{220/255, 40/255, 0/255},
	{255/255, 110/255, 0/255},
	{255/255, 150/255, 0/130},
	{255/255, 200/255, 0/255},
	{255/255, 255/255, 0/255},
}

local soundfile = "Interface\\AddOns\\MONK-Bodhi\\sound\\"
local SFile = {
	["sound1"] = soundfile.."sound1.OGG",
	["sound2"] = soundfile.."sound2.OGG",
	["sound3"] = soundfile.."sound3.OGG",
	["sound4"] = soundfile.."sound4.OGG",
	["sound5"] = soundfile.."sound5.OGG",
}

local Bodhi = CreateFrame("Frame", "Bodhi", UIParent)
Bodhi:SetPoint("CENTER", UIParent, "CENTER", -50, -120)
Bodhi:SetSize(200,35)

Bodhi:RegisterForDrag("LeftButton")
Bodhi:SetScript("OnDragStart", function(self) self:StartMoving() end)
Bodhi:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
Bodhi:SetClampedToScreen(true)
Bodhi:SetMovable(true)
Bodhi:SetUserPlaced(true)
Bodhi:EnableMouse(true)

local updaterate = 0.1

local name_sz = GetSpellInfo(127722) --  青龙之枕
local name_fst = GetSpellInfo(116680) -- 雷光聚神茶
local name_rm = GetSpellInfo(119611) -- 复苏之雾
local name_smg = GetSpellInfo(122783) -- 散魔功
local name_zdj = GetSpellInfo(120954) -- 壮胆酒
local name_qbh = GetSpellInfo(122278) -- 躯不坏

local eh = "Interface\\ICONS\\ability_monk_expelharm" -- 移花接木
local rm = "Interface\\ICONS\\ability_monk_renewingmists" -- 复苏之雾
local mt = "Interface\\ICONS\\monk_ability_cherrymanatea" -- 法力茶
local fst = "Interface\\ICONS\\ability_monk_thunderfocustea" -- 雷光聚神茶
local ct = "Interface\\ICONS\\ability_monk_quitornado" -- 真气突
local lc = "Interface\\ICONS\\ability_monk_chicocoon" -- 作茧缚命
local rv = "Interface\\ICONS\\spell_monk_revival" -- 还魂术
local dx = "Interface\\ICONS\\spell_holy_dispelmagic" -- 化瘀术
local xu = "Interface\\ICONS\\ability_monk_summontigerstatue" -- 白虎下凡
local jw = "Interface\\ICONS\\ability_monk_rushingjadewind" -- 碧玉疾风
local cw = "Interface\\ICONS\\ability_monk_chiwave" -- 真气波
local zs = "Interface\\ICONS\\ability_monk_forcesphere" -- 禅意珠
local cb = "Interface\\ICONS\\spell_arcane_arcanetorrent" -- 真气爆裂
local yb = "Interface\\ICONS\\ability_monk_healthsphere" -- 引爆真气
local zdj = "Interface\\ICONS\\ability_monk_fortifyingale_new" -- 壮胆酒
local smg = "Interface\\ICONS\\spell_monk_diffusemagic" -- 散魔功
local qbh = "Interface\\ICONS\\ability_monk_dampenharm" -- 躯不坏
---------------------------------------------------------------------------
--[[                       Background and Border                       ]]--
---------------------------------------------------------------------------

local function CreateBorder(parent, r, g, b, a, size, br, bg, bb, ba)
	local sd = CreateFrame("Frame", nil, parent)
	sd:SetFrameLevel(parent:GetFrameLevel()-1)
	sd:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8",
		edgeFile = "Interface\\AddOns\\MONK-Bodhi\\texture\\glow",
		edgeSize = size,
		insets = {
		left = size,
		right = size,
		top = size,
		bottom = size,
		}
	})
	sd:SetPoint("TOPLEFT", parent, -size, size)
	sd:SetPoint("BOTTOMRIGHT", parent, size, -size)
	sd:SetBackdropColor(r, g, b, a)
	sd:SetBackdropBorderColor(br, bg, bb, ba or 1)
	
	parent.sd = sd
end

---------------------------------------------------------------------------
--[[                                APIs                               ]]--
---------------------------------------------------------------------------


local function GetRMInfo(self, elapsed)
	self.t = self.t + elapsed
	if self.t > updaterate then
		local SpreadNum = 0
		local EachPredict = 0
		local TotalPredict = 0
		local EachHeal = 0.68 * GetSpellBonusHealing() + 7795
		local charges = GetSpellCharges(115151)
		if UnitBuff("player", GetSpellInfo(119611), nil, "PLAYER") then
			SpreadNum = SpreadNum + 1
			EachPredict = min(UnitHealthMax("player") - UnitHealth("player"), EachHeal)
			TotalPredict = TotalPredict + EachPredict
		end
		if UnitInParty("player") and UnitInRaid("player") == nil then
			for i = 1,4 do
				if UnitBuff(string.format("party%d",i), GetSpellInfo(119611), nil, "PLAYER") then
					SpreadNum = SpreadNum + 1
					EachPredict = min(UnitHealthMax(string.format("party%d",i)) - UnitHealth(string.format("party%d",i)), EachHeal)
					TotalPredict = TotalPredict + EachPredict
				end
			end
		end
		if UnitInRaid("player") then
			for i = 1,39 do
				if UnitBuff(string.format("raid%d",i), GetSpellInfo(119611), nil, "PLAYER") then
					SpreadNum = SpreadNum + 1
					EachPredict = min(UnitHealthMax(string.format("raid%d",i)) - UnitHealth(string.format("raid%d",i)), EachHeal)
					TotalPredict = TotalPredict + EachPredict
				end
			end
		end
		
		self.count:SetText(charges>0 and charges or "")
		if charges == 0 then
			self.texture:SetDesaturated(true)
		else
			self.texture:SetDesaturated(false)
		end
		
		if G.Locale == "zhCN" then
			self.hp:SetText("|cffA6FFFF"..SpreadNum..L["人"].."|r\n\n"..floor(TotalPredict/10000).."万")
		else
			self.hp:SetText("|cffA6FFFF"..SpreadNum..L["人"].."|r\n\n"..floor(TotalPredict/1000).."k")
		end
		
		if TotalPredict > 100000 then
			self.hp:SetTextColor(1, 0, 0)
		elseif TotalPredict > 75000 then
			self.hp:SetTextColor(1, .5, .2)
		elseif TotalPredict > 50000 then
			self.hp:SetTextColor(.5, 1, .2)
		elseif TotalPredict > 25000 then
			self.hp:SetTextColor(0, 1, 1)
		else
			self.hp:SetTextColor(.5, .5, .5)
		end
		
		self.t = 0
	end
end

local function CreateButton(size, tex, r, g, b, ...)
	local button = CreateFrame("Frame", nil, Bodhi)
	button:SetSize(size, size)
	button:SetFrameLevel(level)
	button:SetPoint(...)
	
	button.texture = button:CreateTexture(nil, "BORDER")
	button.texture:SetAllPoints()
	button.texture:SetTexture(tex)
	button.texture:SetTexCoord(0.1,0.9,0.1,0.9)
	
	button.count = button:CreateFontString(nil, "OVERLAY")
	button.count:SetFont(font, 15, "OUTLINE")
	button.count:SetPoint("BOTTOMRIGHT")
	button.count:SetTextColor(0, 1, 1)

	button.cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
	button.cooldown:SetAllPoints(button)
	button.cooldown:SetFrameLevel(level)
	
	button.cooldown.text = button:CreateFontString(nil, "OVERLAY")
	button.cooldown.text:SetFont(font, 15, "OUTLINE")
	button.cooldown.text:SetPoint("BOTTOM", button.cooldown, "TOP", 0, -10)
	button.cooldown.text:SetTextColor(r, g, b)
	
	CreateBorder(button, 0, 0, 0, 0, 3, 0, 0, 0)
	return button
end

local function CreatePopupIcon(size, tex, r, g, b, ...)
	local icon = CreateFrame("Frame", nil, Bodhi)
	icon:SetSize(size, size)
	icon:SetPoint(...)
	icon:SetAlpha(.4)
	
	icon.texture = icon:CreateTexture(nil, "BORDER")
	icon.texture:SetAllPoints()
	icon.texture:SetTexture(tex)
	icon.texture:SetTexCoord(0.1,0.9,0.1,0.9)

	icon.count = icon:CreateFontString(nil, "OVERLAY")
	icon.count:SetFont(font, 20, "OUTLINE")
	icon.count:SetPoint("BOTTOMRIGHT")
	icon.count:SetTextColor(0, 1, 1)
	
	icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
	icon.cooldown:SetAllPoints(icon)
	
	icon.cooldown.text = icon:CreateFontString(nil, "OVERLAY")
	icon.cooldown.text:SetFont(font, 20, "OUTLINE")
	icon.cooldown.text:SetPoint("BOTTOM", icon.cooldown, "TOP", 0, -15)
	icon.cooldown.text:SetTextColor(r, g, b)
	
	CreateBorder(icon, 0, 0, 0, 0, 3, 0, 0, 0)
	return icon
end

local function GetSpellCD(spell_id)
	local cd
	local startTime, duration = GetSpellCooldown(spell_id)
    startTime = startTime or 0
    duration = duration or 0
	cd = cd or 0
	
    if duration > 1.51 and (startTime+duration-GetTime()) > 0 then
		cd = startTime+duration-GetTime()
	end
	
	return cd
end


local createStatusbar = function(parent, name, tex, layer, height, width, r, g, b, alpha)
    local bar = CreateFrame("StatusBar", name)
    bar:SetParent(parent)
    if height then
        bar:SetHeight(height)
    end
    if width then
        bar:SetWidth(width)
    end
    bar:SetStatusBarTexture(tex, layer)
    bar:SetStatusBarColor(r, g, b, alpha)

    return bar
end

local flash_frame = CreateFrame("Frame", "Bodhi_Flash", UIParent)
flash_frame:SetFrameStrata("FULLSCREEN_DIALOG")
flash_frame:SetAllPoints(UIParent)
flash_frame:Hide()

flash_frame.tex = flash_frame:CreateTexture(nil, "BACKGROUND")
flash_frame.tex:SetAllPoints(flash_frame)
flash_frame.tex:SetTexture("Interface\\FullScreenTextures\\OutOfControl")
flash_frame.tex:SetBlendMode("ADD")

local flash_updater = CreateFrame("Frame", "Bodhi_Flash_updater", UIParent)
flash_updater.timer = 0
flash_updater:Hide()
flash_updater:SetScript("OnUpdate", function(self, elapsed)
	self.timer = self.timer - elapsed
	if self.timer > 2.8 and self.timer <= 4 then
		flash_frame:SetAlpha((self.timer-2.8)/1.2)
	elseif self.timer <= 0 then
		flash_frame:Hide()
		self:Hide()
	end
end)

---------------------------------------------------------------------------
--[[                            真气 能量                              ]]--
---------------------------------------------------------------------------
local barwidth = (Iconsize+3)*8-3
local bars = CreateFrame("Frame", "SimpleChi", Bodhi)
bars:SetPoint("TOPLEFT", Bodhi, "TOPLEFT", 0, 0)
bars:SetSize(barwidth, 16)

for i = 1, 5 do
	bars[i] = createStatusbar(bars, "SimpleChi"..i, texture, nil, 6, (barwidth+3)/4-3, 1, 1, 1, 1)
	bars[i]:SetStatusBarColor(unpack(classicon_colors[i]))
	
    if i == 1 then
        bars[i]:SetPoint("TOPLEFT", bars, "TOPLEFT")
    else
        bars[i]:SetPoint("LEFT", bars[i-1], "RIGHT", 3, 0)
    end

    bars[i].bd = CreateBorder(bars[i], .15, .15, .15, 0, 3, 0, 0, 0)
end

local manabar = createStatusbar(bars, "Bodhi manabar", texture, nil, 9, barwidth, 0, .4, .92, 1)
manabar:SetPoint("BOTTOMLEFT", bars, "BOTTOMLEFT", 0, -2)
manabar.bd = CreateBorder(manabar, .15, .15, .15, .8, 3, 0, 0, 0)
manabar:SetMinMaxValues(0, 1)

local manapreditionbar = createStatusbar(manabar, "Bodhi manapreditionbar", texture, nil, 6, barwidth, 0, .2, .4, 1)
manapreditionbar:SetPoint('TOP')
manapreditionbar:SetPoint('BOTTOM')
manapreditionbar:SetPoint('LEFT', manabar:GetStatusBarTexture(), 'RIGHT')
manapreditionbar:SetMinMaxValues(0, 1)

local function Update()
	local power = UnitPower("player", 12)
	for i = 1, 5 do
		if i <= power then
			bars[i]:SetAlpha(1)
		elseif i == power+1 and GetSpellCD(115072) == 0 then
			bars[i]:SetAlpha(.3)
		else
			bars[i]:SetAlpha(0)
		end
	end
	
	if power_max ~= UnitPowerMax("player", 12) then
		for i = 1, 5 do
			bars[i]:SetWidth((barwidth+3)/UnitPowerMax("player", 12)-3)
		end
	end
	
	manabar:SetValue(UnitPower("player")/UnitPowerMax("player"))
	local mpd = min(1-UnitPower("player")/UnitPowerMax("player"), GetSpellCount(123761)*0.03)
	manapreditionbar:SetValue(mpd)
end

bars:SetScript("OnEvent", function(self, event, arg1, arg2)
	if event == "PLAYER_ENTERING_WORLD" then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
		Update()
	elseif arg1 == "player" then
		Update()
	end
end)

bars:RegisterEvent("UNIT_POWER_FREQUENT")
bars:RegisterEvent("PLAYER_ENTERING_WORLD")

---------------------------------------------------------------------------
--[[                             复苏之雾                              ]]--
---------------------------------------------------------------------------
Bodhi.renew = CreateButton(Iconsize, rm, 1, 0, 0, "TOPLEFT", bars, "BOTTOMLEFT", 0, -7)

Bodhi.renew.hp = Bodhi.renew:CreateFontString(nil, "OVERLAY")
Bodhi.renew.hp:SetFont(font, 18, "OUTLINE")
Bodhi.renew.hp:SetPoint("BOTTOMRIGHT", Bodhi.renew, "BOTTOMLEFT", 0, 2)

Bodhi.renew.t = 0
Bodhi.renew:SetScript("OnUpdate", function(self, elapsed)
	GetRMInfo(self, elapsed)
end)

local ocd = 1

Bodhi.UpdateRenewMist = function()
	local charge, maxcharge, start, duration = GetSpellCharges(115151)
	if charge == 3 then
		ActionButton_ShowOverlayGlow(Bodhi.renew.sd)
		if ocd == 1 then
			ocd = 0
			PlaySoundFile(SFile["sound5"], "Master")
		end
		Bodhi.renew.cooldown:SetCooldown(0, 0)
	elseif charge then
		ocd = 1
		ActionButton_HideOverlayGlow(Bodhi.renew.sd)		
		Bodhi.renew.cooldown:SetCooldown(start, duration)	
	end
end

---------------------------------------------------------------------------
--[[   雷光聚神茶 真气突 作茧缚命 还魂术 装弹机 散魔功 躯不坏 驱散     ]]--
---------------------------------------------------------------------------

local function OnCooldown(self, spell_id, showcharge, showcount)
	
	if showcharge then
		local currentCharges, maxCharges, start, duration = GetSpellCharges(spell_id)
		if currentCharges then
			if currentCharges>0 then
				self.texture:SetDesaturated(false)
			else
				self.texture:SetDesaturated(true)
			end		
			if currentCharges < maxCharges then
				self.cooldown:SetCooldown(start, duration)
			end		
			if currentCharges > 0 then
				self.count:SetText(currentCharges)
				self:SetAlpha(1)
			else
				self.count:SetText("")
				self:SetAlpha(alpha)
			end
		end
	elseif showcount then
		local count = GetSpellCount(spell_id)
		if count then
			if GetSpellCD(spell_id) == 0 and count>0 then
				self.texture:SetDesaturated(false)
			else
				self.texture:SetDesaturated(true)
			end
			local start, duration = GetSpellCooldown(spell_id)
			self.cooldown:SetCooldown(start, duration)			
			if count > 0 then
				self.count:SetText(count)
				self:SetAlpha(1)
			else
				self.count:SetText("")
				self:SetAlpha(alpha)
			end
		end
	else
		if GetSpellCD(spell_id) == 0 then
			self.texture:SetDesaturated(false)
			self:SetAlpha(1)
		else
			self.texture:SetDesaturated(true)
			self:SetAlpha(alpha)
			local start, duration = GetSpellCooldown(spell_id)
			self.cooldown:SetCooldown(start, duration)			
		end
	end
end

local function PopupSpell(self, spell_id)
	if IsSpellKnown(spell_id) and GetSpellCD(spell_id) == 0 then
		self:Show()
	else
		self:Hide()		
	end
end

local function PopupTalentSpell(self, tier, index, spell_id)
	if select(4, GetTalentInfo(tier, index, GetActiveSpecGroup())) and GetSpellCD(spell_id) == 0 then
		self:Show()
	else
		self:Hide()		
	end
end

Bodhi.mt_p = CreatePopupIcon(Iconsize+15, mt, 1, 1, 1, "BOTTOMRIGHT", manabar, "TOP", -5, 30)-- 法力茶

Bodhi.cw_p = CreatePopupIcon(Iconsize+15, cw, 1, 1, 1, "RIGHT", Bodhi.mt_p, "LEFT", -10, 0)-- 真气波
Bodhi.zs_p = CreatePopupIcon(Iconsize+15, zs, 1, 1, 1, "RIGHT", Bodhi.mt_p, "LEFT", -10, 0)-- 禅意珠
Bodhi.cb_p = CreatePopupIcon(Iconsize+15, cb, 1, 1, 1, "RIGHT", Bodhi.mt_p, "LEFT", -10, 0)-- 真气爆裂

local function TotalOrb(event, ...)  
    local battleMessage = select(2, ...);
    local spellId  =  select(12, ...);
    local spellCaster = select(4, ...);
    local multiStrike = select(19, ...);
    local timeStamp = select(1, ...);

    if gosCount == nil then    -- 初始化疗伤珠各变量
        gosCount = 0
    end
    if ceCount == nil then -- 初始真气破珠各变量
        ceCount = 0
    end
    if nowTimeis == nil then
        nowTimeis = "0";
    end
    if orbTotal == nil then
        orbTotal = 0
    end
    
    if spellCaster == UnitGUID("player") and multiStrike ~= true then
        if battleMessage == "SPELL_CAST_SUCCESS" then
            
            -- 119031 召唤一个疗伤珠
            if spellId == 119031 then
                gosCount = gosCount + 1-- 135920 疗伤珠30秒后的自爆/手动爆珠后珠子的治疗(不区分疗伤珠还是真气破珠)
            elseif spellId == 135920 then
                gosCount = gosCount - 1
                -- 173438 真气波珠15秒后的自爆    
            elseif spellId == 173438 then
                ceCount = ceCount - 1
                -- 157682 到 157689 真气破生成的真气破珠子
            elseif spellId >= 157682 and spellId <= 157689  then
                ceCount = ceCount + 1
				-- 115460 手动爆珠技能使用
            elseif spellId == 115460 then
                gosCount = 0
                ceCount = 0
            end
            
        elseif battleMessage == "SPELL_HEAL" then

            -- 124041 疗伤珠给踩到的人治疗
            if spellId == 124041 and timeStamp ~= nowTimeis then
                nowTimeis = timeStamp
                gosCount = gosCount - 1
            
            -- 173439 真气破珠给踩到的人治疗
            elseif spellId == 173439 then
                ceCount = ceCount - 1
            end
        end
        
        -- 处理可能的异常,这个异常是因为真气珠现在可以同时被多个人吃到，等暴雪修复后可能就不会出现这样的问题
        if ceCount < 0 then
            ceCount = 0
        elseif gosCount < 0 then
            gosCount = 0
        end
    end
    
    orbTotal = ceCount + gosCount
  
    return orbTotal
end

local function UpdateOrbnum(icon, event, ...)
	local orbnum = TotalOrb(event, ...)
	if orbnum>0 then
		icon.count:SetText(orbnum)
	else
		icon.count:SetText("")
	end
end

Bodhi.yb = CreateButton(Iconsize, yb, 1, 1, 0, "LEFT", Bodhi.renew, "RIGHT", 3, 0) -- 引爆真气

Bodhi.fst = CreateButton(Iconsize, fst, 1, 1, 0, "LEFT", Bodhi.yb, "RIGHT", 3, 0) -- 雷光聚神茶

Bodhi.ct = CreateButton(Iconsize, ct, 1, 1, 1, "LEFT", Bodhi.fst, "RIGHT", 3, 0) -- 真气突
Bodhi.xu = CreateButton(Iconsize, xu, 1, 1, 1, "LEFT", Bodhi.fst, "RIGHT", 3, 0) -- 白虎下凡
Bodhi.jw = CreateButton(Iconsize, jw, 1, 1, 1, "LEFT", Bodhi.fst, "RIGHT", 3, 0) -- 碧玉疾风

Bodhi.lc = CreateButton(Iconsize, lc, 1, 1, 1, "LEFT", Bodhi.ct, "RIGHT", 3, 0) -- 作茧缚命
Bodhi.rv = CreateButton(Iconsize, rv, 1, 1, 1, "LEFT", Bodhi.lc, "RIGHT", 3, 0) -- 还魂术

Bodhi.zdj = CreateButton(Iconsize, zdj, 1, 1, 1, "LEFT", Bodhi.rv, "RIGHT", 3, 0) -- 壮胆酒
Bodhi.smg = CreateButton(Iconsize, smg, 1, 1, 1, "LEFT", Bodhi.zdj, "RIGHT", 3, 0) -- 散魔功
Bodhi.qbh = CreateButton(Iconsize, qbh, 1, 1, 1, "LEFT", Bodhi.zdj, "RIGHT", 3, 0) -- 躯不坏

Bodhi.dx = CreateButton(Iconsize, dx, 1, 1, 0, "LEFT", Bodhi.smg, "RIGHT", 3, 0) -- 驱散

---------------------------------------------------------------------------
--[[                           青龙之枕 活力之雾                       ]]--
---------------------------------------------------------------------------
local function ShowAura(self, name, showstack, showred)
	if UnitBuff("player", name) then
		local _,_,_,count,_,duration,expires = UnitBuff("player", name)
		self.cooldown:SetCooldown(expires-duration, duration)
		self.texture:SetDesaturated(false)
		if showstack then
			self.count:SetText(count)
		end
		if showred then
			self.texture:SetVertexColor(1, 1, 1)
		end
	else
		self.cooldown:Hide()
		self.cooldown.text:SetText("")
		self.texture:SetDesaturated(true)
		if showstack then
			self.count:SetText("")
		end
		if showred then
			self.texture:SetVertexColor(1, .2, 0)
		end
	end
end

local function PopupAura(self, name, showstack, flash)
	if UnitBuff("player", name) then
		local _,_,_,count,_,duration,expires = UnitBuff("player", name)
		self.cooldown:SetCooldown(expires-duration, duration)
		self:Show()
		if showstack then
			self.count:SetText(count)
		end
		if flash and not flash_updater:IsShown() then
			flash_updater.timer = 4
			flash_updater:Show()
			flash_frame:Show()
		end
	else
		self.cooldown:Hide()
		self.cooldown.text:SetText("")
		self:Hide()
		if showstack then
			self.count:SetText("")
		end
	end
end

--Bodhi.sz = CreateButton(Iconsize, sz, 1, 1, 1, "LEFT", Bodhi.renew, "RIGHT", 3, 0)

Bodhi.zdjbuff = CreatePopupIcon(Iconsize+15, zdj, 1, 1, 1, "BOTTOMLEFT", manabar, "TOP", 5, 30) -- 壮胆酒
Bodhi.smgbuff = CreatePopupIcon(Iconsize+15, smg, 1, 1, 1, "LEFT", Bodhi.zdjbuff, "RIGHT", 10, 0) -- 散魔功
Bodhi.qbhbuff = CreatePopupIcon(Iconsize+15, qbh, 1, 1, 1, "LEFT", Bodhi.zdjbuff, "RIGHT", 10, 0) -- 躯不坏
---------------------------------------------------------------------------
--[[                           Update                                ]]--
---------------------------------------------------------------------------

Bodhi.UpdateBuff = function()
	--ShowAura(Bodhi.sz, name_sz, false, true)
	
	PopupAura(Bodhi.zdjbuff, name_zdj)
	PopupAura(Bodhi.smgbuff, name_smg)
	PopupAura(Bodhi.qbhbuff, name_qbh, true)
end

Bodhi.Cooldowns = function()
	OnCooldown(Bodhi.fst, 116680)
	OnCooldown(Bodhi.lc, 116849)
	OnCooldown(Bodhi.rv, 115310)
	OnCooldown(Bodhi.ct, 115008, true)
	OnCooldown(Bodhi.xu, 123904)
	OnCooldown(Bodhi.zdj, 115203)
	OnCooldown(Bodhi.smg, 122783)	
	OnCooldown(Bodhi.qbh, 122278)
	OnCooldown(Bodhi.jw, 116847)
	OnCooldown(Bodhi.yb, 115460)
		
	PopupTalentSpell(Bodhi.cw_p, 2, 1, 115098)
	PopupTalentSpell(Bodhi.zs_p, 2, 2, 124081)
	PopupTalentSpell(Bodhi.cb_p, 2, 3, 123986)

	if mtg then
		if GetSpellCD(123761) == 0 and GetSpellCount(123761) > 1 then
			Bodhi.mt_p:Show()
		else
			Bodhi.mt_p:Hide()		
		end
	else
		Bodhi.mt_p:Hide()
	end

	if GetSpellCD(115450) == 0 then
		Bodhi.dx:Hide()
	else
		Bodhi.dx:Show()
		local start, duration = GetSpellCooldown(115450)
		Bodhi.dx.cooldown:SetCooldown(start, duration)			
	end
end

---------------------------------------------------------------------------
--[[                           Textures                                ]]--
---------------------------------------------------------------------------
Bodhi.texframe = CreateFrame("Frame", "Bodhi_textures", Bodhi)
Bodhi.texframe:SetPoint("CENTER", UIParent, "CENTER")
Bodhi.texframe:SetSize(80,80)

local function CreateTex(path, r, g, b, layer, size, blend, ...)
	local frame = CreateFrame("Frame", nil, Bodhi.texframe)
	frame:SetPoint(...)
	frame:SetSize(size, size)
	
	frame.tex = frame:CreateTexture(nil, layer)
	frame.tex:SetAllPoints(frame)
	frame.tex:SetTexture(path)
	frame.tex:SetVertexColor(r, g, b, .8)
	
	if blend then
		frame.tex:SetBlendMode("ADD")
	end

	return frame
end

Bodhi.texframe.point1 = CreateTex("Interface\\Addons\\MONK-Bodhi\\texture\\point", 1, 1, 0, "OVERLAY", 15, false, "LEFT", manabar, "LEFT", 5, 0) -- 第一个活力酒
Bodhi.texframe.point1:SetScript("OnEvent", function(self,event)
	if select(4, GetTalentInfo(3,3,GetActiveSpecGroup())) and GetSpellCharges(115399)>0 then
		self:Show()
	else
		self:Hide()
	end
	
	if event == "PLAYER_ENTERING_WORLD" then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end
end)

Bodhi.texframe.point1:RegisterEvent("ACTIONBAR_UPDATE_STATE")
Bodhi.texframe.point1:RegisterEvent("PLAYER_ENTERING_WORLD")

Bodhi.texframe.point2 = CreateTex("Interface\\Addons\\MONK-Bodhi\\texture\\point", 1, 1, 0, "OVERLAY", 15, false, "LEFT", Bodhi.texframe.point1, "RIGHT", 0, 0) -- 第二个活力酒
Bodhi.texframe.point2:SetScript("OnEvent", function(self,event)
	if select(4, GetTalentInfo(3,3,GetActiveSpecGroup())) and GetSpellCharges(115399)>1 then
		self:Show()
	else
		self:Hide()
	end
	
	if event == "PLAYER_ENTERING_WORLD" then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end
end)

Bodhi.texframe.point2:RegisterEvent("ACTIONBAR_UPDATE_STATE")
Bodhi.texframe.point2:RegisterEvent("PLAYER_ENTERING_WORLD")
---------------------------------------------------------------------------
--[[                               Command                             ]]--
---------------------------------------------------------------------------
local function slashCmdFunction(msg)
	msg = string.lower(msg)
	local args = {}
	for word in string.gmatch(msg, "[^%s]+") do
		table.insert(args, word)
	end
	
	if (args[1] == "show") then
		if Bodhi:IsShown() then
			Bodhi:Hide()
		else
			Bodhi:Show()
		end
	elseif (args[1] == "scale") then
		local scale = tonumber(args[2])
		if (scale and scale >= 0.8 and scale <= 2) then
			Bodhi_DB.scale = scale
			Bodhi:SetScale(Bodhi_DB.scale)
		else
			print("|cff02F78EBodhi|r:"..L["必须是0.8~2之间的数字"])
		end
	else
		print("|cff02F78EBodhi|r: /bd scale x "..L["-调整大小(x是0.8~2之间的数字)"])
		print("|cff02F78EBodhi|r: /bd show "..L["-显示/隐藏插件"])
	end
end

SlashCmdList["Bodhi"] = slashCmdFunction
SLASH_Bodhi1 = "/bd"
SLASH_Bodhi2 = "/bodhi"
---------------------------------------------------------------------------
--[[                                 Init                              ]]--
---------------------------------------------------------------------------
local default_Settings = {
	scale = 1, -- 框体比例
}

local function LoadVariables()
	for a, b in pairs(default_Settings) do
		if Bodhi_DB[a] == nil then
			Bodhi_DB[a] = b
		end
	end
end

Bodhi:HookScript("OnEvent", function(self,event, ...)
	if event == "PLAYER_LOGIN" then
		self:RegisterEvent("ACTIONBAR_UPDATE_STATE")
		self:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
		self:RegisterEvent("SPELL_UPDATE_CHARGES")
		self:RegisterEvent("UNIT_AURA")
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		
		if Bodhi_DB == nil then
			Bodhi_DB = {}
		end
		LoadVariables()
		
		Bodhi:SetScale(Bodhi_DB.scale)
	end
	
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		UpdateOrbnum(Bodhi.yb, event, ...) -- 疗伤珠
	end
	
	if event == "PLAYER_TALENT_UPDATE" then
		if GetSpecialization() == 2 then
			self:Show()
			self:RegisterEvent("PET_BATTLE_OPENING_START")
			self:RegisterEvent("PET_BATTLE_OVER")
		else
			self:Hide()
			self:UnregisterEvent("PET_BATTLE_OPENING_START")
			self:UnregisterEvent("PET_BATTLE_OVER")
		end
		
		if select(4, GetTalentInfo(5,3,GetActiveSpecGroup())) then -- 散魔功
			Bodhi.smg:Show()
		else
			Bodhi.smg:Hide()
		end
		
		if select(4, GetTalentInfo(5,2,GetActiveSpecGroup())) then -- 躯不坏
			Bodhi.qbh:Show()
		else
			Bodhi.qbh:Hide()
		end
		
		if select(4, GetTalentInfo(6,3,GetActiveSpecGroup())) then -- 真气突
			Bodhi.ct:Show()
		else
			Bodhi.ct:Hide()
		end
		
		if select(4, GetTalentInfo(6,2,GetActiveSpecGroup())) then -- 白虎下方
			Bodhi.xu:Show()
		else
			Bodhi.xu:Hide()
		end
		
		if select(4, GetTalentInfo(6,1,GetActiveSpecGroup())) then -- 碧玉疾风
			Bodhi.jw:Show()
		else
			Bodhi.jw:Hide()
		end
		
		mtg = false
		for i = 1, GetNumGlyphSockets() do
			local glyphID = select(4, GetGlyphSocketInfo(i))
			if glyphID == 123763 then
				mtg = true
			end
		end
		
		self.Cooldowns()
		self.UpdateBuff()
	end
	

	if event == "ACTIONBAR_UPDATE_STATE" or event == "ACTIONBAR_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_CHARGES" then
		self.Cooldowns()
		self.UpdateRenewMist()
	end
	
	if event == "UNIT_AURA" then
		self.UpdateBuff()
		if UnitBuff("player", name_fst) then
			ActionButton_ShowOverlayGlow(Bodhi.fst.sd)
		else
			ActionButton_HideOverlayGlow(Bodhi.fst.sd)
		end
	end
	
	if event == "PET_BATTLE_OPENING_START" then
		self:Hide()
	end

	if event == "PET_BATTLE_OVER" then
		self:Show()
	end
end)

Bodhi:RegisterEvent("PLAYER_TALENT_UPDATE")
Bodhi:RegisterEvent("PLAYER_LOGIN")