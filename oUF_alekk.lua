
local tParty = true
local tCastbar = true
local tRunebar = true

local fontn = "Interface\\AddOns\\oUF_alekk\\fonts\\CalibriBold.ttf"
local fontpixel = "Interface\\AddOns\\oUF_alekk\\fonts\\Calibri.ttf"
local texturebar = "Interface\\AddOns\\oUF_alekk\\textures\\Ruben"
local trunebar = "Interface\\AddOns\\oUF_alekk\\textures\\rothTex"
local textureborder = "Interface\\AddOns\\oUF_alekk\\textures\\Caith.tga"
local bubbleTex = 'Interface\\Addons\\oUF_alekk\\textures\\bubbleTex'
local cbborder = 'Interface\\AddOns\\oUF_alekk\\textures\\border'
local glowTexture = [=[Interface\Addons\aNamePlates\media\glowTex]=]
local mscale = 1

local backdrop = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\AddOns\\oUF_alekk\\textures\\border", edgeSize = 12,
	insets = {left = 0, right = 0, top = 0, bottom = 0},
}

local backdrophp = {
	bgFile = "Interface\\AddOns\\oUF_alekk\\textures\\Ruben",
	insets = {left = 0, right = 0, top = 0, bottom = 0},
}

local colors = {
	green = { r = 0, g = 1, b = 0 },
	gray = { r = 0.5, g = 0.5, b = 0.5 },
	white = { r = 1, g = 1, b = 1},
	unknown = { r = .41, g = .95, b = .2 },
}

local classification = {
	worldboss = '%s |cffffd700Boss|r',
	rareelite = '%s |cffffd700R+|r',
	elite = '%s |cffffd700++|r',
	rare = '%s Rare',
	normal = '%s',
	trivial = '%s',
}

oUF.colors.power.MANA = {.30,.45,.65}
oUF.colors.power.RAGE = {.70,.30,.30}
oUF.colors.power.FOCUS = {.70,.45,.25}
oUF.colors.power.ENERGY = {.65,.65,.35}
oUF.colors.power.RUNIC_POWER = {.45,.45,.75}

oUF.colors.happiness = {
	[1] = {.69,.31,.31},
	[2] = {.65,.65,.30},
	[3] = {.33,.59,.33},
}

oUF.colors.runes = {
		[1] = {0.69, 0.31, 0.31},
		[2] = {0.33, 0.59, 0.33},
		[3] = {0.31, 0.45, 0.63},
		[4] = {0.84, 0.75, 0.05},
}

oUF.colors.tapped = {.55,.57,.61}
oUF.colors.disconnected = {.5,.5,.5}

local setFontString = function(parent, fontStyle, fontHeight)
	local fs = parent:CreateFontString(nil, "OVERLAY")
	fs:SetFont(fontStyle, fontHeight)
	fs:SetShadowColor(0,0,0)
	fs:SetShadowOffset(1, -1)
	fs:SetTextColor(1,1,1)
	fs:SetJustifyH("LEFT")
	return fs
end

local kilo = function(value)
	if value >= 1e6 then
		return ("%.1fm"):format(value / 1e6):gsub("%.?0+([km])$", "%1")
	elseif value >= 1e3 or value <= -1e3 then
		return ("%.1fk"):format(value / 1e3):gsub("%.?0+([km])$", "%1")
	else
		return value
	end
end

-- New tagging system
oUF.Tags["alekk:smarthp"] = function(unit) -- gives Dead Ghost or HP | max HP | percentage HP
	if(UnitIsDead(unit)) then
		return 'Dead'
	elseif(UnitIsGhost(unit)) then
		return 'Ghost'
	else
		return format("%s | %s | %s%%", UnitHealth(unit), UnitHealthMax(unit), (UnitHealth(unit)/UnitHealthMax(unit)*100))
	end
end

oUF.Tags["alekk:tarpp"] = function(unit) -- gives 4.5k | 4.5k
	return UnitIsDeadOrGhost(unit) and "" or format("%s | %s", kilo(UnitPower(unit)), kilo(UnitPowerMax(unit)))
end

local function PostUpdatePower(self, event, unit, bar, min, max)
	local _, pType = UnitPowerType(unit)
	local color = self.colors.power[pType] or {0.7,0.7,0.7} 
	
	bar:SetStatusBarColor(color[1], color[2], color[3]) 
	bar:SetBackdropColor(color[1]/3, color[2]/3, color[3]/3,0.8)

    if max == 0 or UnitIsDead(unit) or UnitIsGhost(unit) or not UnitIsConnected(unit) then  
        bar:SetValue(0) 
        if bar.value then
            bar.value:SetText()
        end
    elseif bar.value then
		if(unit=='player') then  
			bar.value:SetText(min .. ' | ' .. max)
		elseif(unit=="target") then
			bar.value:SetText(kilo(min) .. ' | ' .. kilo(max))
		else
			bar.value:SetText()  
		end
	end
	self:UNIT_NAME_UPDATE(event, unit)
end

local FormatTime = function(s)
	local DAY, HOUR, MINUTE = 86400, 3600, 60
	if s >= DAY then
		return format('%dd', floor(s/DAY + 0.5)), s % DAY
	elseif s >= HOUR then
		return format('%dh', floor(s/HOUR + 0.5)), s % HOUR
	elseif s >= MINUTE then
		if s <= MINUTE*3 then
			return format('%d:%02d', floor(s/60), s % MINUTE), s - floor(s)
		end
		return format('%dm', floor(s/MINUTE + 0.5)), s % MINUTE
	end
	return floor(s + 0.5), s - floor(s)
end

local CreateAuraTimer = function(self,elapsed)
	if self.timeLeft then
		self.elapsed = (self.elapsed or 0) + elapsed
		if self.elapsed >= 0.1 then
			if not self.first then
				self.timeLeft = self.timeLeft - self.elapsed
			else
				self.timeLeft = self.timeLeft - GetTime()
				self.first = false
			end
			if self.timeLeft > 60 then
				local time = FormatTime(self.timeLeft)
				self.remaining:SetText(time)
				self.remaining:SetTextColor(0.8, 0.8, 0.9)
			elseif self.timeLeft > 5 then
				local time = FormatTime(self.timeLeft)
				self.remaining:SetText(time)
				self.remaining:SetTextColor(0.8, 0.8, 0.2)
			elseif self.timeLeft > 0 then
				local time = FormatTime(self.timeLeft)
				self.remaining:SetText(time)
				self.remaining:SetTextColor(0.9, 0.3, 0.3)
			else
				self.remaining:Hide()
				self:SetScript("OnUpdate", nil)
			end
			self.elapsed = 0
		end
	end
end

local function PostCreateAuraIcon(self, button, icons, index, debuff)
	button.backdrop = CreateFrame("Frame", nil, button)
	button.backdrop:SetPoint("TOPLEFT", button, "TOPLEFT", -3.5, 3)
	button.backdrop:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 4, -3.5)
	button.backdrop:SetFrameStrata("BACKGROUND")
	button.backdrop:SetBackdrop {
		edgeFile = glowTex, edgeSize = 5,
		insets = {left = 3, right = 3, top = 3, bottom = 3}
	}
	button.backdrop:SetBackdropColor(0, 0, 0, 0)
	button.backdrop:SetBackdropBorderColor(0, 0, 0)

	button.count:SetPoint("BOTTOMRIGHT", 3,-3)
	button.count:SetJustifyH("RIGHT")
	if self.unit == "player" then
		button.count:SetFont(fontn, 17, "OUTLINE")
	else
		button.count:SetFont(fontn, 14, "OUTLINE")
	end
	button.count:SetTextColor(0.8, 0.8, 0.8)

	button.cd.noOCC = true
	button.cd.noCooldownCount = true
	icons.disableCooldown = true

	button.overlay:SetTexture(textureborder)
	button.overlay:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 1)
	button.overlay:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1)
	button.overlay:SetTexCoord(0, 1, 0, 1)
	button.overlay.Hide = function(self) end

	button.remaining = setFontString(button, fontn, 12)
		button.remaining:SetFont(fontn, 14, "OUTLINE")
		if self.unit == "player" then
			button.remaining:SetFont(fontn, 17, "OUTLINE")
			button:SetScript("OnMouseUp", CancelAura)
		end
	if icons == self.Enchant then
		button.remaining:SetFont(fontn, 15, "OUTLINE")
		button.overlay:SetVertexColor(0.33, 0.59, 0.33)
	end
	button.remaining:SetPoint("CENTER", 1, -1)
end

local CreateEnchantTimer = function(self, icons)
	for i = 1, 2 do
		local icon = icons[i]
		if icon.expTime then
			icon.timeLeft = icon.expTime - GetTime()
			icon.remaining:Show()
		else
			icon.remaining:Hide()
		end
		icon:SetScript("OnUpdate", CreateAuraTimer)
	end
end

local function PostUpdateAuraIcon(self, icons, unit, icon, index, offset, filter, debuff)
	local _, _, _, _, _, duration, expirationTime, unitCaster, _ = UnitAura(unit, index, icon.filter)
	if (unitCaster == "player" or unitCaster == "pet" or unitCaster == "vehicle") and self.unit == "target" then
		if icon.debuff then
			icon.overlay:SetVertexColor(0.8, 0.2, 0.2)
		else
			icon.overlay:SetVertexColor(0.2, 0.8, 0.2)
		end
	else
		if UnitIsEnemy("player", unit) then
			if icon.debuff then
				icon.icon:SetDesaturated(true)
			end
		end
		icon.overlay:SetVertexColor(0.5, 0.5, 0.5)
	end

	if duration and duration > 0 then
		icon.remaining:Show()
	else
		icon.remaining:Hide()
	end

	icon.duration = duration
	icon.timeLeft = expirationTime
	icon.first = true
	icon:SetScript("OnUpdate", CreateAuraTimer)
end

local menu = function(self)
	local unit = self.unit:sub(1, -2)
	local cunit = self.unit:gsub('(.)', string.upper, 1)

	if(unit == 'party') then
		ToggleDropDownMenu(1, nil, _G['PartyMemberFrame'..self.id..'DropDown'], 'cursor', 0, 0)
	elseif(_G[cunit..'FrameDropDown']) then
		ToggleDropDownMenu(1, nil, _G[cunit..'FrameDropDown'], 'cursor', 0, 0)
	end
end

local function OverrideCastbarTime(self, duration)
		if(self.channeling) then
			self.Time:SetFormattedText('%.1f / %.2f', self.max - duration, self.max)
		elseif(self.casting) then
			self.Time:SetFormattedText('%.1f / %.2f', duration, self.max)
		end	
end

local function OverrideCastbarDelay(self, duration)
		if(self.channeling) then
			self.Time:SetFormattedText('%.1f / %.2f |cffff0000+ %.1f', self.max - duration, self.max, self.delay)
		elseif(self.casting) then
			self.Time:SetFormattedText('%.1f / %.2f |cffff0000+ %.1f', duration, self.max, self.delay)
		end	
end


-- New style functions.... Painful.
local UnitSpecific = {

	player = function(self)	
		
		self:SetWidth(275)
		self:SetHeight(47)
		self:SetScale(0.85)
		
		self.Health:SetHeight(27)
		self.Power:SetHeight(10.5)
		
		self.Health.value = setFontString(self.Health, fontn, 13)
		self.Health.value:SetHeight(20)
		self.Health.value:SetPoint("RIGHT", -3,0)
		self.Health.value.frequentUpdates = true
		self:Tag(self.Health.value, "[alekk:smarthp]")
		
		self.Power.value = setFontString(self.Power, fontn, 12)
		self.Power.value:SetPoint("RIGHT", self.Power, "RIGHT", -3, 0)
		self:Tag(self.Power.value, "[curpp] | [maxpp]")
		
		if IsAddOnLoaded("oUF_WeaponEnchant") then
			self.Enchant = CreateFrame("Frame", nil, self)
			self.Enchant:SetHeight(41)
			self.Enchant:SetWidth(41 * 2)
			self.Enchant:SetPoint("TOPRIGHT", self, "TOPLEFT", -2, -1)
			self.Enchant.size = 38
			self.Enchant.spacing = 2
			self.Enchant.initialAnchor = "TOPRIGHT"
			self.Enchant["growth-x"] = "LEFT"
		end
		
		self.Info = setFontString(self.Power, fontn, 12)
		self.Info:SetPoint("LEFT", self.Power, "LEFT", 2, 0.5)
		self:Tag(self.Info, "[difficulty][smartlevel] [raidcolor][smartclass] |r[race]")
		
		--BuffFrame:Hide()
		--TemporaryEnchantFrame:Hide()
		
		self.Debuffs = CreateFrame("Frame", nil, self)
		self.Debuffs:SetHeight(41*4)
		self.Debuffs:SetWidth(41*4)
		self.Debuffs.size = 40
		self.Debuffs.spacing = 2
		
		self.Debuffs.initialAnchor = "BOTTOMLEFT"
		self.Debuffs["growth-x"] = "RIGHT"
		self.Debuffs["growth-y"] = "UP"
		self.Debuffs:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 7.5)
	
		self.Buffs = CreateFrame("Frame", nil, self)
		self.Buffs:SetHeight(320)
		self.Buffs:SetWidth(42 * 12)
		self.Buffs.size = 35
		self.Buffs.spacing = 2
		
		self.Buffs:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -5, -35)
		self.Buffs.initialAnchor = "TOPRIGHT"
		self.Buffs["growth-x"] = "LEFT"
		self.Buffs["growth-y"] = "DOWN"
		self.Buffs.filter = true
		
		self.Combat = self.Health:CreateTexture(nil, 'OVERLAY')
		self.Combat:SetHeight(17)
		self.Combat:SetWidth(17)
		self.Combat:SetPoint('TOPRIGHT', 2, 12)
		self.Combat:SetTexture('Interface\\CharacterFrame\\UI-StateIcon')
		self.Combat:SetTexCoord(0.58, 0.90, 0.08, 0.41)
		
		if(tCastbar) then
			local classcb = select(2, UnitClass("player"))
			local colorcb = oUF.colors.class[classcb]

			self.Castbar = CreateFrame('StatusBar', nil, self)
			self.Castbar:SetPoint('TOP', UIParentr, 'CENTER', 0, -93)
			self.Castbar:SetStatusBarTexture(texturebar)
			self.Castbar:SetStatusBarColor(colorcb[1], colorcb[2], colorcb[3])
			self.Castbar:SetBackdrop(backdrophp)
			self.Castbar:SetBackdropColor(colorcb[1]/3, colorcb[2]/3, colorcb[3]/3)
			self.Castbar:SetHeight(19)
			self.Castbar:SetWidth(322)
			
			self.Castbar.Spark = self.Castbar:CreateTexture(nil,'OVERLAY')
			self.Castbar.Spark:SetBlendMode("ADD")
			self.Castbar.Spark:SetHeight(55)
			self.Castbar.Spark:SetWidth(27)
			self.Castbar.Spark:SetVertexColor(colorcb[1], colorcb[2], colorcb[3])
			
			self.Castbar.Text = setFontString(self.Castbar, fontn, 13)
			self.Castbar.Text:SetPoint('LEFT', self.Castbar, 2, 0)

			self.Castbar.Time = setFontString(self.Castbar, fontn, 13)
			self.Castbar.Time:SetPoint('RIGHT', self.Castbar, -2, 0)
			self.Castbar.CustomTimeText = OverrideCastbarTime
			self.Castbar.CustomDelayText = OverrideCastbarDelay
			
			self.Castbar2 = CreateFrame('StatusBar', nil, self.Castbar)
			self.Castbar2:SetPoint('BOTTOMRIGHT', self.Castbar, 'BOTTOMRIGHT', 4, -4)
			self.Castbar2:SetPoint('TOPLEFT', self.Castbar, 'TOPLEFT', -4, 4)
			self.Castbar2:SetBackdrop(backdrop)
			self.Castbar2:SetBackdropColor(0,0,0,1)
			self.Castbar2:SetHeight(27)
			self.Castbar2:SetFrameLevel(0)
			
			self.Castbar.SafeZone = self.Castbar:CreateTexture(nil,'BACKGROUND')
			self.Castbar.SafeZone:SetPoint('TOPRIGHT')
			self.Castbar.SafeZone:SetPoint('BOTTOMRIGHT')
			self.Castbar.SafeZone:SetHeight(20)
			self.Castbar.SafeZone:SetTexture(texturebar)
			self.Castbar.SafeZone:SetVertexColor(1,1,.01,0.5)
		end
		
		if select(2, UnitClass("player") == 'DEATHKNIGHT' and unit == 'player' and tRunebar) then
		self.RuneBar = {}
		for i = 1, 6 do
			self.RuneBar[i] = CreateFrame('StatusBar', nil, self)
			if(i == 1) then
				self.RuneBar[i]:SetPoint('BOTTOMRIGHT', self, 'BOTTOMLEFT', -4, 4)
			else
				self.RuneBar[i]:SetPoint('TOPRIGHT', self.RuneBar[i-1], 'TOPLEFT', -7, 0)
			end
			self.RuneBar[i]:SetStatusBarTexture(texturebar)--(trunebar)
			--self.RuneBar[i]:SetStatusBarColor(unpack(runeloadcolors[i]))
			self.RuneBar[i]:SetHeight(39)
			self.RuneBar[i]:SetWidth(6)--(275/6 - 1.25)
			self.RuneBar[i]:SetBackdrop(backdrophp)
			self.RuneBar[i]:SetBackdropColor(.75,.75,.75)
			self.RuneBar[i]:SetMinMaxValues(0, 1)
			self.RuneBar[i]:SetOrientation("Vertical")
			self.RuneBar[i]:SetID(i)
			local runetype = GetRuneType(i)
			if(runetype) then
				self.RuneBar[i]:SetStatusBarColor(unpack(colors.runes[runetype]))
				
			end

			self.RuneBar[i].bg = CreateFrame('StatusBar', nil, self.RuneBar[i])
			self.RuneBar[i].bg:SetPoint('BOTTOMRIGHT', self.RuneBar[i], 'BOTTOMRIGHT', 4, -4)
			self.RuneBar[i].bg:SetPoint('TOPLEFT', self.RuneBar[i], 'TOPLEFT', -4, 4)
			self.RuneBar[i].bg:SetBackdrop(backdrop)
			self.RuneBar[i].bg:SetBackdropColor(0,0,0,1)
			self.RuneBar[i].bg:SetHeight(27)
			self.RuneBar[i].bg:SetFrameLevel(0)
			
		end

		RuneFrame:Hide()

		self:RegisterEvent('RUNE_TYPE_UPDATE', UpdateRuneType)
		self:RegisterEvent('RUNE_REGEN_UPDATE', UpdateRuneType)
		self:RegisterEvent('RUNE_POWER_UPDATE', UpdateRunePower)
	end
	end,
	
	target = function(self)
		self:SetWidth(275)
		self:SetHeight(47)
		self:SetScale(0.85)
		
		self.Health:SetHeight(27)
		self.Power:SetHeight(10.5)
		
		self.Health.value = setFontString(self.Health, fontn, 13)
		self.Health.value:SetHeight(20)
		self.Health.value:SetPoint("LEFT", 2, 0)
		self.Health.value.frequentUpdates = true
		self:Tag(self.Health.value, "[alekk:smarthp]")
		
		self.Power.value = setFontString(self.Power, fontn, 12)
		self.Power.value:SetPoint("RIGHT", self.Power, "RIGHT", -3, 0)
		self:Tag(self.Power.value, "[alekk:tarpp]")
		
		self.Info = setFontString(self.Power, fontn, 12)
		self.Power.value:SetPoint("LEFT", self.Power, "LEFT", 2,0)
		self:Tag(self.Info, "[difficulty][smartlevel] [raidcolor][smartclass] |r[race]")
		
		self.Name = setFontString(self.Health, fontn, 13)
		self.Name:SetPoint("RIGHT", self.Health, "RIGHT",-3,0)
		self.Name:SetWidth(170)
		self.Name:SetJustifyH('RIGHT')
		self:Tag(self.Name, "[name]")
		
		self.Auras = CreateFrame('StatusBar', nil, self)
		self.Auras:SetHeight(120)
		self.Auras:SetWidth(280)
		self.Auras:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 1, 2)
		self.Auras['growth-x'] = 'RIGHT'
		self.Auras['growth-y'] = 'UP' 
		self.Auras.initialAnchor = 'BOTTOMLEFT'
		self.Auras.spacing = 2.5
		self.Auras.size = 28
		self.Auras.gap = true
		self.Auras.numBuffs = 18 
		self.Auras.numDebuffs = 18 
		--self.sortAuras = {}
		--self.sortAuras.selfFirst = true
		
		self.CPoints = {}
		--self.CPoints.unit = 'player'
		self.CPoints[1] = self.Power:CreateTexture(nil, 'OVERLAY')
		self.CPoints[1]:SetHeight(17)
		self.CPoints[1]:SetWidth(17)
		self.CPoints[1]:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, 0)
		self.CPoints[1]:SetTexture(bubbleTex)
		self.CPoints[1]:SetVertexColor(.33,.63,.33)

		self.CPoints[2] = self.Power:CreateTexture(nil, 'OVERLAY')
		self.CPoints[2]:SetHeight(17)
		self.CPoints[2]:SetWidth(17)
		self.CPoints[2]:SetPoint('LEFT', self.CPoints[1], 'RIGHT', 1)
		self.CPoints[2]:SetTexture(bubbleTex)
		self.CPoints[2]:SetVertexColor(.33,.63,.33)

		self.CPoints[3] = self.Power:CreateTexture(nil, 'OVERLAY')
		self.CPoints[3]:SetHeight(17)
		self.CPoints[3]:SetWidth(17)
		self.CPoints[3]:SetPoint('LEFT', self.CPoints[2], 'RIGHT', 1)
		self.CPoints[3]:SetTexture(bubbleTex)
		self.CPoints[3]:SetVertexColor(.67,.67,.33)

		self.CPoints[4] = self.Power:CreateTexture(nil, 'OVERLAY')
		self.CPoints[4]:SetHeight(17)
		self.CPoints[4]:SetWidth(17)
		self.CPoints[4]:SetPoint('LEFT', self.CPoints[3], 'RIGHT', 1)
		self.CPoints[4]:SetTexture(bubbleTex)
		self.CPoints[4]:SetVertexColor(.67,.67,.33)

		self.CPoints[5] = self.Power:CreateTexture(nil, 'OVERLAY')
		self.CPoints[5]:SetHeight(17)
		self.CPoints[5]:SetWidth(17)
		self.CPoints[5]:SetPoint('LEFT', self.CPoints[4], 'RIGHT', 1)
		self.CPoints[5]:SetTexture(bubbleTex)
		self.CPoints[5]:SetVertexColor(.69,.31,.31)	
		
		--CastBars
	
		if(tCastbar) then
			self.Castbar = CreateFrame('StatusBar', nil, self)
			self.Castbar:SetPoint('TOP', UIParentr, 'CENTER', 0, -73)
			self.Castbar:SetStatusBarTexture(texturebar)
			self.Castbar:SetStatusBarColor(.81,.81,.25)
			self.Castbar:SetBackdrop(backdrophp)
			self.Castbar:SetBackdropColor(.81/3,.81/3,.25/3)
			self.Castbar:SetHeight(11)
			self.Castbar:SetWidth(322)
			
			self.Castbar.Text = setFontString(self.Castbar, fontn, 13)
			self.Castbar.Text:SetPoint('LEFT', self.Castbar, 2, 1)

			self.Castbar.Time = setFontString(self.Castbar, fontn, 13)
			self.Castbar.Time:SetPoint('RIGHT', self.Castbar, -2, 1)
			self.Castbar.CustomTimeText = OverrideCastbarTime
			
			self.Castbar2 = CreateFrame('StatusBar', nil, self.Castbar)
			self.Castbar2:SetPoint('BOTTOMRIGHT', self.Castbar, 'BOTTOMRIGHT', 4, -4)
			self.Castbar2:SetPoint('TOPLEFT', self.Castbar, 'TOPLEFT', -4, 4)
			self.Castbar2:SetBackdrop(backdrop)
			self.Castbar2:SetBackdropColor(0,0,0,1)
			self.Castbar2:SetHeight(21)
			self.Castbar2:SetFrameLevel(0)
			
			self.Castbar.Spark = self.Castbar:CreateTexture(nil,'OVERLAY')
			self.Castbar.Spark:SetBlendMode("Add")
			self.Castbar.Spark:SetHeight(35)
			self.Castbar.Spark:SetWidth(25)
			self.Castbar.Spark:SetVertexColor(.69,.31,.31)
		end
	end,
	
	targettarget = function(self)
		self:SetWidth(135)
		self:SetHeight(25)
		self:SetScale(0.85)
		
		self.Health:SetHeight(16.5)
		self.Power:SetHeight(0)
		
		self.Name = setFontString(self.Health, fontn, 13)
		self.Name:SetPoint("RIGHT", self.Health, "RIGHT",-3,0)
		self.Name:SetWidth(80)
		self.Name:SetJustifyH('RIGHT')
		self:Tag(self.Name, "[name]")
		
		self.Health.value = setFontString(self.Health, fontn, 13)
		self.Health.value:SetPoint("LEFT", self.Health, "LEFT", 2, 0)
		self:Tag(self.Health.value, "[perhp]%")
	end,
	
	focus = function(self)
		self:SetWidth(135)
		self:SetHeight(25)
		self:SetScale(0.85)
		
		self.Health:SetHeight(16.5)
		self.Power:SetHeight(0)
		
		self.Name = setFontString(self.Health, fontn, 13)
		self.Name:SetPoint("LEFT", self.Health, "LEFT",2,0)
		self.Name:SetWidth(80)
		self.Name:SetHeight(20)
		self.Name:SetJustifyH('LEFT')
		self:Tag(self.Name, "[name]")
		
		self.Health.value = setFontString(self.Health, fontn, 13)
		self.Health.value:SetPoint("RIGHT", self.Health, "RIGHT", -3, 0)
		self:Tag(self.Health.value, "[perhp]%")
		
		if(tCastbar) then
			self.Castbar = CreateFrame('StatusBar', nil, self)
			self.Castbar:SetPoint('TOP', UIParentr, 'CENTER', 0, -123)
			self.Castbar:SetStatusBarTexture(texturebar)
			self.Castbar:SetStatusBarColor(.79,.41,.31)
			self.Castbar:SetBackdrop(backdrophp)
			self.Castbar:SetBackdropColor(.79/3,.41/3,.31/3)
			self.Castbar:SetHeight(11)
			self.Castbar:SetWidth(280)
			
			self.Castbar.Text = setFontString(self.Castbar, fontn, 12)
			self.Castbar.Text:SetPoint('LEFT', self.Castbar, 2, 1)

			self.Castbar.Time = setFontString(self.Castbar, fontn, 12)
			self.Castbar.Time:SetPoint('RIGHT', self.Castbar, -2, 1)
			self.Castbar.CustomTimeText = OverrideCastbarTime
			
			self.Castbar2 = CreateFrame('StatusBar', nil, self.Castbar)
			self.Castbar2:SetPoint('BOTTOMRIGHT', self.Castbar, 'BOTTOMRIGHT', 4, -4)
			self.Castbar2:SetPoint('TOPLEFT', self.Castbar, 'TOPLEFT', -4, 4)
			self.Castbar2:SetBackdrop(backdrop)
			self.Castbar2:SetBackdropColor(0,0,0,1)
			self.Castbar2:SetHeight(21)
			self.Castbar2:SetFrameLevel(0)
			
			self.Castbar.Spark = self.Castbar:CreateTexture(nil,'OVERLAY')
			self.Castbar.Spark:SetBlendMode("Add")
			self.Castbar.Spark:SetHeight(35)
			self.Castbar.Spark:SetWidth(25)
			self.Castbar.Spark:SetVertexColor(.69,.31,.31)
		end
		
	end,
	
	focustarget = function(self)
		self:SetWidth(135)
		self:SetHeight(25)
		self:SetScale(0.85)
		
		self.Health:SetHeight(16.5)
		self.Power:SetHeight(0)
		
		self.Name = setFontString(self.Health, fontn, 13)
		self.Name:SetPoint("LEFT", self.Health, "LEFT",2,0)
		self.Name:SetWidth(80)
		self.Name:SetHeight(20)
		self.Name:SetJustifyH('LEFT')
		self:Tag(self.Name, "[name]")
		
		self.Health.value = setFontString(self.Health, fontn, 13)
		self.Health.value:SetPoint("RIGHT", self.Health, "RIGHT", -3, 0)
		self:Tag(self.Health.value, "[perhp]%")
	end,
	
	pet = function(self)
		self:SetWidth(125)
		self:SetHeight(38)
		self:SetScale(0.85)
		
		self.Power.colorHappiness = true
	
		self.Auras = CreateFrame('StatusBar', nil, self)
		self.Auras:SetHeight(100)
		self.Auras:SetWidth(130)
		self.Auras:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 1, -2)
		self.Auras['growth-x'] = 'RIGHT'
		self.Auras['growth-y'] = 'DOWN'
		self.Auras.initialAnchor = 'TOPLEFT' 
		self.Auras.spacing = 3
		self.Auras.size = 28
		self.Auras.gap = true
		self.Auras.numBuffs = 8
		self.Auras.numDebuffs = 8
		
		self.Name = setFontString(self.Health, fontn, 13)
		self.Name:SetPoint("TOPLEFT", self.Health, "TOPLEFT",2,-2)
		self.Name:SetWidth(80)
		self.Name:SetHeight(20)
		self.Name:SetJustifyH('RIGHT')
		self:Tag(self.Name, "[name]")
	end,

}

local function Shared(self, unit)
	
	self:RegisterForClicks('AnyDown')
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)
	self.menu = menu

	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0,0,0,1)
	self:SetWidth(125)
	self:SetHeight(38)
	self:SetScale(0.85)
	
	if (UnitClassification(unit)~= "normal") then
		self:SetBackdropBorderColor(1,0.84,0,1)
	else
		self:SetBackdropBorderColor(1,1,1,1)
	end	
		
	self.Health = CreateFrame("StatusBar", nil, self)
	self.Health:SetStatusBarTexture(texturebar)
	self.Health:SetStatusBarColor(.31, .31, .31)
	self.Health:SetPoint("LEFT", 4.5,0)
	self.Health:SetPoint("RIGHT", -4.5,0)
	self.Health:SetPoint("TOP", 0,-4.5)
	self.Health:SetBackdrop(backdrophp)
	self.Health:SetHeight(23)
	self.Health.Smooth = true
	self.Health.colorClass = true
	self.Health.colorClassNPC = true
	self.Health.colorClassPet = true
	self.Health.colorTapping = true
	self.Health.colorDisconnected = true
	self.Health.frequentUpdates = true

	self.Power = CreateFrame("StatusBar", nil, self)
	self.Power:SetHeight(9.5)
	self.Power:SetStatusBarTexture(texturebar)
	self.Power:SetStatusBarColor(.25, .25, .35)
	
	self.Power:SetPoint("LEFT", self.Health)
	self.Power:SetPoint("RIGHT", self.Health)
	self.Power:SetPoint("TOP", self.Health, "BOTTOM", 0, -1)
	self.Power:SetBackdrop(backdrophp)
	self.Power.colorPower = true
	self.Power.frequentUpdates = true
	
	self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY")
	self.RaidIcon:SetHeight(18)
	self.RaidIcon:SetWidth(18)
	self.RaidIcon:SetPoint("TOP", self, 0, 5)
	self.RaidIcon:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")

	self.PostCreateAuraIcon = PostCreateAuraIcon
	self.PostUpdateAuraIcon = PostUpdateAuraIcon
	self.PostUpdateName = OverrideUpdateName
	self.PostUpdateHealth = PostUpdateHealth
	self.PostUpdatePower = PostUpdatePower
	self.PostCreateEnchantIcon = PostCreateAuraIcon
	self.PostUpdateEnchantIcons = CreateEnchantTimer
	
	if(not unit) then 
		self.SpellRange = true
		self.Range = {
			insideAlpha = 1,
			outsideAlpha = 0.8,
		}
	end
	
	if(UnitSpecific[unit]) then
		return UnitSpecific[unit](self)
	end

end


oUF:RegisterStyle('alekk', Shared)

oUF:Factory(function(self) -- the new "where stuff goes method
	oUF:SetActiveStyle('alekk')

	oUF:Spawn("player"):SetPoint("CENTER", -305, -92)
	oUF:Spawn("target"):SetPoint("CENTER", 305, -92)
	oUF:Spawn("pet"):SetPoint("TOPLEFT", oUF.units.player, "BOTTOMLEFT", 0, -45)
	oUF:Spawn("targettarget"):SetPoint("TOPRIGHT", oUF.units.target, "BOTTOMRIGHT", 0, -1)
	oUF:Spawn("focus"):SetPoint("TOPLEFT", oUF.units.player, "BOTTOMLEFT", 0, -1)
	oUF:Spawn("focustarget"):SetPoint("TOPLEFT", oUF.units.focus, "TOPRIGHT", 5, 0)
	
	 -- Maintank Frames
	local maintank = self:SpawnHeader("oUF_MainTank", nil, "raid, party, solo",
		"showRaid", true,
		"yOffset", -3,
		"point", "LEFT",
		"columnAnchorPoint", "TOP",
		"sortMethod", "NAME",
		"groupFilter", "MAINTANK",
		"oUF-initialConfigFunction", [[
			self:SetWidth(%d)
			self:SetHeight(%d)
			self:SetScale(1))
			]]
		)
	maintank:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 8, 225)
	-- Maintank Targets
	local mtt = self:SpawnHeader(
		nil, nil, 'raid,party',
		'showRaid', true,
		'groupFilter', 'MAINTANK',
		'oUF-initialConfigFunction', [[
			self:SetHeight(22)
			self:SetWidth(220)
			self:SetAttribute('unitsuffix', 'target')
			]]
		)
	mtt:SetPoint("BOTTOMLEFT", maintank, "BOTTOMRIGHT")
	-- party
	if tParty then
		local party = self:SpawnHeader(
			nil, nil, 
			'party',
			'showSolo', true, -- for the sake of debug
			'showParty', true,
			'yOffset', -3,
			'oUF-initialConfigFunction', [[
				-- unit {raid, party}{pet, target}
				local unit = ...
				-- can't set width/height
			]]
		)
		party:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 8, 180)
	end

end)