local addon, ns = ...
local L = ns[1]
local G = ns[2]

if select(2, UnitClass("player")) ~= "MONK" then return end

local Iconsize = 33 -- 图标大小

local font = GameFontHighlight:GetFont()
local texture = "Interface\\Buttons\\WHITE8x8"
local alpha = .6
local level = 3

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

local spell = {
	rm = {id = 115151}, -- 复苏之雾
	sq = {id = 205406}, -- 神器
	fst = {id = 116680}, -- 雷光
	js = {id = 115313}, -- 青龙雕像
	cj = {id = 198664}, -- 仙鹤下凡
	jw = {id = 196725}, -- 碧玉疾风
	lc = {id = 116849}, -- 作茧缚命
	rv = {id = 115310}, -- 还魂术
	smg = {id = 122783}, -- 散魔功
	qbh = {id = 122278}, -- 躯不坏
	dx = {id = 115450}, -- 驱散
}

for k, v in pairs(spell) do
	local name, rank, icon  = GetSpellInfo(spell[k].id)
	spell[k].name = name
	spell[k].icon = icon
end

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
local function ShortValue(val)
	if G.Locale == "zhCN" then
		if (val >= 1e7) then
			return ("%.1fkw"):format(val / 1e7)
		elseif (val >= 1e4) then
			return ("%.1fw"):format(val / 1e4)
		else
			return ("%d"):format(val)
		end
	else
		if (val >= 1e6) then
			return ("%.1fm"):format(val / 1e6)
		elseif (val >= 1e3) then
			return ("%.1fk"):format(val / 1e3)
		else
			return ("%d"):format(val)
		end
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

local function GetAuraRemain(aura_name)
	local aura = aura or 0
	local expires = select(7, UnitBuff("player", aura_name))
    if expires then
        aura = expires - GetTime()
    end
	return aura
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
local manabar = createStatusbar(Bodhi, "Bodhi manabar", texture, nil, 9, 200, 0, .4, .92, 1)
manabar:SetPoint("TOPLEFT", Bodhi, "TOPLEFT", -5, -5)
manabar.bd = CreateBorder(manabar, .15, .15, .15, .8, 3, 0, 0, 0)
manabar:SetMinMaxValues(0, 1)

manabar:SetScript("OnEvent", function(self, event, arg1, arg2)
	if event == "PLAYER_ENTERING_WORLD" then
		self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	end
	manabar:SetValue(UnitPower("player")/UnitPowerMax("player"))
end)

manabar:RegisterEvent("UNIT_POWER_FREQUENT")
manabar:RegisterEvent("PLAYER_ENTERING_WORLD")
---------------------------------------------------------------------------
--[[   复苏之雾 雷光聚神茶 真气突 作茧缚命 还魂术 装弹机 散魔功 躯不坏 驱散     ]]--
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

Bodhi.rm = CreateButton(Iconsize, spell.rm.icon, 1, 0, 0, "TOPLEFT", manabar, "BOTTOMLEFT", 0, -7) -- 复苏之雾
Bodhi.sq = CreateButton(Iconsize, spell.sq.icon, 1, 1, 0, "LEFT", Bodhi.rm, "RIGHT", 3, 0) -- 神器

Bodhi.fst = CreateButton(Iconsize, spell.fst.icon, 1, 1, 0, "LEFT", Bodhi.sq, "RIGHT", 3, 0) -- 雷光聚神茶

Bodhi.js = CreateButton(Iconsize, spell.js.icon, 1, 1, 1, "LEFT", Bodhi.fst, "RIGHT", 3, 0) -- 青龙雕像
Bodhi.cj = CreateButton(Iconsize, spell.cj.icon, 1, 1, 1, "LEFT", Bodhi.fst, "RIGHT", 3, 0) -- 仙鹤下凡
Bodhi.jw = CreateButton(Iconsize, spell.jw.icon, 1, 1, 1, "LEFT", Bodhi.fst, "RIGHT", 3, 0) -- 碧玉疾风

Bodhi.lc = CreateButton(Iconsize, spell.lc.icon, 1, 1, 1, "LEFT", Bodhi.js, "RIGHT", 3, 0) -- 作茧缚命
Bodhi.rv = CreateButton(Iconsize, spell.rv.icon, 1, 1, 1, "LEFT", Bodhi.lc, "RIGHT", 3, 0) -- 还魂术

Bodhi.smg = CreateButton(Iconsize, spell.smg.icon, 1, 1, 1, "LEFT", Bodhi.rv, "RIGHT", 3, 0) -- 散魔功
Bodhi.qbh = CreateButton(Iconsize, spell.qbh.icon, 1, 1, 1, "LEFT", Bodhi.rv, "RIGHT", 3, 0) -- 躯不坏

Bodhi.dx = CreateButton(Iconsize, spell.dx.icon, 1, 1, 0, "LEFT", Bodhi.smg, "RIGHT", 3, 0) -- 驱散

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

--Bodhi.sz = CreateButton(Iconsize, sz, 1, 1, 1, "LEFT", Bodhi.rm, "RIGHT", 3, 0)

Bodhi.smgbuff = CreatePopupIcon(Iconsize+15, spell.smg.icon, 1, 1, 1, "LEFT", Bodhi.zdjbuff, "RIGHT", 10, 0) -- 散魔功
Bodhi.qbhbuff = CreatePopupIcon(Iconsize+15, spell.qbh.icon, 1, 1, 1, "LEFT", Bodhi.zdjbuff, "RIGHT", 10, 0) -- 躯不坏
---------------------------------------------------------------------------
--[[                           Update                                ]]--
---------------------------------------------------------------------------

Bodhi.UpdateBuff = function()
	--ShowAura(Bodhi.sz, name_sz, false, true)
	
	PopupAura(Bodhi.smgbuff, spell.smg.name)
	PopupAura(Bodhi.qbhbuff, spell.qbh.name, true)
end

Bodhi.Cooldowns = function()
	OnCooldown(Bodhi.rm, spell.rm.id)
	OnCooldown(Bodhi.sq, spell.sq.id, false, true)
	OnCooldown(Bodhi.fst, spell.fst.id)
	
	OnCooldown(Bodhi.js, spell.js.id)
	OnCooldown(Bodhi.cj, spell.cj.id)
	OnCooldown(Bodhi.jw, spell.jw.id)
	
	OnCooldown(Bodhi.lc, spell.lc.id)
	OnCooldown(Bodhi.rv, spell.rv.id)

	OnCooldown(Bodhi.smg, spell.smg.id)	
	OnCooldown(Bodhi.qbh, spell.qbh.id)

	if GetSpellCD(115450) == 0 then
		Bodhi.dx:Hide()
	else
		Bodhi.dx:Show()
		local start, duration = GetSpellCooldown(115450)
		Bodhi.dx.cooldown:SetCooldown(start, duration)			
	end
end
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
		
		if select(4, GetTalentInfo(5,2,GetActiveSpecGroup())) then -- 散魔功
			Bodhi.smg:Show()
		else
			Bodhi.smg:Hide()
		end
		
		if select(4, GetTalentInfo(5,3,GetActiveSpecGroup())) then -- 躯不坏
			Bodhi.qbh:Show()
		else
			Bodhi.qbh:Hide()
		end
		
		if select(4, GetTalentInfo(6,3,GetActiveSpecGroup())) then -- 青龙雕像
			Bodhi.js:Show()
		else
			Bodhi.js:Hide()
		end
		
		if select(4, GetTalentInfo(6,2,GetActiveSpecGroup())) then -- 仙鹤下凡
			Bodhi.cj:Show()
		else
			Bodhi.cj:Hide()
		end
		
		if select(4, GetTalentInfo(6,1,GetActiveSpecGroup())) then -- 碧玉疾风
			Bodhi.jw:Show()
		else
			Bodhi.jw:Hide()
		end
		
		if select(4, GetTalentInfo(5,2,GetActiveSpecGroup())) or select(4, GetTalentInfo(5,3,GetActiveSpecGroup())) then
			manabar:SetWidth((Iconsize+3)*7-3)
		else
			manabar:SetWidth((Iconsize+3)*6-3)
		end
		
		self.Cooldowns()
		self.UpdateBuff()
	end
	

	if event == "ACTIONBAR_UPDATE_STATE" or event == "ACTIONBAR_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_CHARGES" then
		self.Cooldowns()
	end
	
	if event == "UNIT_AURA" then
		self.UpdateBuff()
		if UnitBuff("player", spell.fst.name) then
			if select(4, GetTalentInfo(7,2,GetActiveSpecGroup())) then
				local count = select(4, UnitBuff("player", spell.fst.name))
				Bodhi.fst.count:SetText(count)
			end
			ActionButton_ShowOverlayGlow(Bodhi.fst.sd)
		else
			ActionButton_HideOverlayGlow(Bodhi.fst.sd)
			if select(4, GetTalentInfo(7,2,GetActiveSpecGroup())) then
				local count = select(4, UnitBuff("player", spell.fst.name))
				Bodhi.fst.count:SetText("")
			end
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