local tParty = true
local tCastbar = true
local tRunebar = true
local tBuffs = true

local fontn = 'Interface\\AddOns\\oUF_alekk\\fonts\\CalibriBold.ttf'
local fontpixel = 'Interface\\AddOns\\oUF_alekk\\fonts\\Calibri.ttf'
local texturebar = 'Interface\\AddOns\\oUF_alekk\\textures\\Ruben'
local trunebar = 'Interface\\AddOns\\oUF_alekk\\textures\\rothTex'
local textureborder = 'Interface\\AddOns\\oUF_alekk\\textures\\Caith.tga'
local bubbleTex = 'Interface\\Addons\\oUF_alekk\\textures\\bubbleTex'
local cbborder = 'Interface\\AddOns\\oUF_alekk\\textures\\border'
local glowTexture = 'Interface\\AddOns\\oUF_alekk\\textures\\glowTex'
local mscale = 1

local backdrop = {
	bgFile = 'Interface\\Tooltips\\UI-Tooltip-Background',
	edgeFile = 'Interface\\AddOns\\oUF_alekk\\textures\\border', edgeSize = 12,
	insets = {left = 0, right = 0, top = 0, bottom = 0},
}

local backdrophp = {
	bgFile = 'Interface\\AddOns\\oUF_alekk\\textures\\Ruben',
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
		[1] = {0.69, 0.31, 0.31},	-- Blood
		[2] = {0.33, 0.59, 0.33},	-- Unholy
		[3] = {0.31, 0.45, 0.63},	-- Frost
		[4] = {0.84, 0.75, 0.05},	-- Death
}

oUF.colors.tapped = {.55,.57,.61}
oUF.colors.disconnected = {.5,.5,.5}

local setFontString = function(parent, fontStyle, fontHeight)
	local fs = parent:CreateFontString(nil, 'OVERLAY')
	fs:SetFont(fontStyle, fontHeight)
	fs:SetShadowColor(0,0,0)
	fs:SetShadowOffset(1, -1)
	fs:SetTextColor(1,1,1)
	fs:SetJustifyH('LEFT')
	return fs
end

local kilo = function(value)
	if value >= 1e6 then
		return ('%.1fm'):format(value / 1e6):gsub('%.?0+([km])$', '%1')
	elseif value >= 1e3 or value <= -1e3 then
		return ('%.1fk'):format(value / 1e3):gsub('%.?0+([km])$', '%1')
	else
		return value
	end
end

-- New tagging system
oUF.Tags.Methods['alekk:smarthp'] = function(unit) -- gives Dead Ghost or HP | max HP | percentage HP
	local min, max = UnitHealth(unit), UnitHealthMax(unit)
	local status = not UnitIsConnected(unit) and 'Offline' or UnitIsGhost(unit) and 'Ghost' or UnitIsDead(unit) and 'Dead'
	
	if(status) then
		return status
	elseif (unit == 'target') then
		return format('%.1f%% | %s', (min/max*100),kilo(max))
	else
		return format('%d | %d | %d%%',min , max ,floor(min/max*100))
	end
end

oUF.Tags.Methods['alekk:tarpp'] = function(unit) -- gives 4.5k | 4.5k
	return UnitIsDeadOrGhost(unit) and '' or UnitPower(unit) <= 0 and '' or format('%s | %s', kilo(UnitPower(unit)), kilo(UnitPowerMax(unit)))
end

-- these are just for the editor -- I play a priest :P 
local Shadow_Orb = GetSpellInfo(77487)
oUF.Tags.Methods['alekk:ShadowOrbs'] = function(unit)
    if(unit == 'player') then
      local name, _, icon, count = UnitBuff('player', Shadow_Orb)
	  return name and count
    end
end
oUF.Tags.Events['alekk:ShadowOrbs'] = 'UNIT_AURA'

local Evangelism = GetSpellInfo(81661) or GetSpellInfo(81660)
local Dark_Evangelism = GetSpellInfo(87118) or GetSpellInfo(87117)
oUF.Tags.Methods['alekk:Evangelism'] = function(unit)
	if unit == 'player' then
      local name, _, icon, count = UnitBuff('player', Evangelism)
	  if name then return count end
	  name, _, icon, count = UnitBuff('player', Dark_Evangelism)
	  return name and count
	end
end
oUF.Tags.Events['alekk:Evangelism'] = 'UNIT_AURA'

local function UpdateRuneBar(self, elapsed)
	local start, duration, ready = GetRuneCooldown(self:GetID())

	if(ready) then
		self:SetValue(1)
		self:SetScript('OnUpdate', nil)
	else
		self:SetValue((GetTime() - start) / duration)
	end
end

local function UpdateRunePower(self, event, rune, usable)
	for i = 1, 6 do
		if(rune == i and not usable and GetRuneType(rune)) then
			self.RuneBar[i]:SetScript('OnUpdate', UpdateRuneBar)
		end
	end
end

local function UpdateRuneType(self, event, rune)
	if(rune) then
		local runetype = GetRuneType(rune)
		if(runetype) then
			self.RuneBar[rune]:SetStatusBarColor(unpack(colors.runes[runetype]))
		end
	else
		for i = 1, 6 do
			local runetype = GetRuneType(i)
			if(runetype) then
				self.RuneBar[i]:SetStatusBarColor(unpack(colors.runes[runetype]))
				
			end
		end
	end
end

local FormatTime = function(s)
	local day, hour, minute = 86400, 3600, 60
	if s >= day then
		return format("%dd", floor(s/day + 0.5)), s % day
	elseif s >= hour then
		return format("%dh", floor(s/hour + 0.5)), s % hour
	elseif s >= minute then
		if s <= minute * 5 then
			return format("%d:%02d", floor(s/60), s % minute), s - floor(s)
		end
		return format("%dm", floor(s/minute + 0.5)), s % minute
	elseif s >= minute / 12 then
		return floor(s + 0.5), (s * 100 - floor(s * 100))/100
	end
	return format("%.1f", s), (s * 100 - floor(s * 100))/100
end

local CreateAuraTimer = function(self, elapsed)
	if self.timeLeft then
		self.elapsed = (self.elapsed or 0) + elapsed
		if self.elapsed >= 0.1 then
			if not self.first then
				self.timeLeft = self.timeLeft - self.elapsed
			else
				self.timeLeft = self.timeLeft - GetTime()
				self.first = false
			end
			if self.timeLeft > 0 then
				local time = FormatTime(self.timeLeft)
					self.remaining:SetText(time)
				if self.timeLeft < 5 then
					self.remaining:SetTextColor(0.9, 0.3, 0.3) -- red
				elseif 5 < self.timeLeft and self.timeLeft < 60 then
					self.remaining:SetTextColor(0.8, 0.8, 0.2) -- yellow
				else
					self.remaining:SetTextColor(0.8, 0.8, 0.9) -- blueish white
				end
			else
				self.remaining:Hide()
				self:SetScript("OnUpdate", nil)
			end
			self.elapsed = 0
		end
	end
end

local PostCreateIcon = function(self, button, icons, index, debuff)
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
	
	button.count:ClearAllPoints()
	button.count:SetPoint("BOTTOMRIGHT", 3,-3)
	button.count:SetJustifyH("RIGHT")
	button.count:SetTextColor(0.8, 0.8, 0.8)	
	
	if self.unit == "player" then
		button.count:SetFont(fontn, 17, "OUTLINE")
	else
		button.count:SetFont(fontn, 14, "OUTLINE")
	end	

	button.cd.noOCC = true
	button.cd.noCooldownCount = true
	self.disableCooldown = true

	button.overlay:SetTexture(textureborder)
	button.overlay:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 1)
	button.overlay:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1)
	button.overlay:SetTexCoord(0, 1, 0, 1)
	button.icon:SetTexCoord(.07, .93, .07, .93)
	button.overlay.Hide = function(self) end
	
	button.remaining = button:CreateFontString(nil, 'OVERLAY')
	button.remaining:SetPoint('CENTER', button)
	button.remaining:SetJustifyH('CENTER')
	button.remaining:SetFont(fontn, 14, 'OUTLINE')	

	if self.unit == "player" then
		button.remaining:SetFont(fontn, 17, "OUTLINE")
	end
	
	if icons == self.Enchant then
		button.remaining:SetFont(fontn, 15, "OUTLINE")
		button.overlay:SetVertexColor(136/255, 57/255, 184/255)
	end
end

local PostUpdateIcon = function(element, unit, icon, index, offset, filter, isDebuff)
	local name, _, _, _, dtype, duration, expirationTime, unitCaster, _ = UnitAura(unit, index, icon.filter)

	if icon.debuff and not UnitIsEnemy('player', unit) then
		icon.overlay:SetVertexColor(0.8, 0.2, 0.2)
	elseif (unitCaster == 'player' or unitCaster == 'pet' or unitCaster == 'vehicle') then
		if unit == 'target' then
			icon.overlay:SetVertexColor(0.2, 0.8, 0.2)
		else
			icon.overlay:SetVertexColor(.5, .5, .5)
		end
	elseif UnitIsEnemy('player', unit) and icon.debuff then
		icon.icon:SetDesaturated(true)
	else
		icon.overlay:SetVertexColor(.5, .5, .5)
	end
	
	if unit == 'player' then
		icon.remaining:SetFont(fontn, 17, 'OUTLINE')
		icon.count:SetFont(fontn, 17, 'OUTLINE')
	else
		icon.remaining:SetFont(fontn, 14, 'OUTLINE')	
		icon.count:SetFont(fontn, 14, 'OUTLINE')
	end

	if duration and duration > 0 then
		icon.remaining:Show()
		icon.timeLeft = expirationTime
		icon:SetScript("OnUpdate", CreateAuraTimer)
	else
		icon.remaining:Hide()
		icon.timeLeft = math.huge
		icon:SetScript("OnUpdate", nil)
	end

	icon.first = true
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

local CreateEnchantTimer = function(self, icons)
	for i = 1, 2 do
		local button = icons[i]
		if button.expTime then
			button.timeLeft = button.expTime - GetTime()
			button.remaining:Show()
		else
			button.remaining:Hide()
		end
		button:SetScript('OnUpdate', CreateAuraTimer)
	end
end

local UpdateClassification = function(self)
	local class = UnitClassification(self.unit)
	if (class == 'elite' or class == 'rareelite' or class == 'worldboss') then
		self:SetBackdropBorderColor(1,0.84,0,1)
	else
		self:SetBackdropBorderColor(1,1,1,1)
	end
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

local updateAllElements = function(frame)
	for _, v in ipairs(frame.__elements) do
		v(frame, "UpdateElement", frame.unit)
	end
end

-- New style functions.... Painful.
local UnitSpecific = {

	player = function(self)	
		
		self:SetWidth(275)
		self:SetHeight(47)
		--self:SetScale(0.85)
		
		self.Health:SetHeight(27)
		self.Power:SetHeight(10.5)
		
		self.Health.value = setFontString(self.Health, fontn, 13)
		self.Health.value:SetHeight(20)
		self.Health.value:SetPoint('RIGHT', -3,0)
		self.Health.value.frequentUpdates = 1/4
		self:Tag(self.Health.value, '[alekk:smarthp]')
		
		self.Power.value = setFontString(self.Power, fontn, 12)
		self.Power.value:SetPoint('RIGHT', self.Power, 'RIGHT', -3, 0)
		self:Tag(self.Power.value, '[curpp] | [maxpp]')
		
		if IsAddOnLoaded('oUF_WeaponEnchant') then
			self.Enchant = CreateFrame('Frame', nil, self)
			self.Enchant:SetHeight(41)
			self.Enchant:SetWidth(41 * 2)
			self.Enchant:SetPoint('TOPRIGHT', self, 'TOPLEFT', -2, -1)
			self.Enchant.size = 38
			self.Enchant.spacing = 2
			self.Enchant.initialAnchor = 'TOPRIGHT'
			self.Enchant['growth-x'] = 'LEFT'
		end
		
		self.Info = setFontString(self.Power, fontn, 12)
		self.Info:SetPoint('LEFT', self.Power, 'LEFT', 2, 0.5)
		self:Tag(self.Info, '[difficulty][smartlevel] [raidcolor][smartclass] |r[race]')
		
		if (tBuffs) then
			BuffFrame:Hide()
			TemporaryEnchantFrame:Hide()
			
			self.Debuffs = CreateFrame('Frame', nil, self)
			self.Debuffs:SetHeight(41*4)
			self.Debuffs:SetWidth(41*4)
			self.Debuffs.size = 40
			self.Debuffs.spacing = 2
			
			self.Debuffs.initialAnchor = 'BOTTOMLEFT'
			self.Debuffs['growth-x'] = 'RIGHT'
			self.Debuffs['growth-y'] = 'UP'
			self.Debuffs:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 0, 7.5)
			self.Debuffs.showDebuffType = true
			
			self.Debuffs.PostCreateIcon = PostCreateIcon
			self.Debuffs.PostUpdateIcon = PostUpdateIcon
		
			self.Buffs = CreateFrame('Frame', nil, self)
			self.Buffs:SetHeight(320)
			self.Buffs:SetWidth(42 * 12)
			self.Buffs.size = 35
			self.Buffs.spacing = 2
			
			self.Buffs:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -5, -35)
			--self.Buffs:SetPoint('TOPRIGHT', Minimap, 'TOPLEFT', -5, 10)
			self.Buffs.initialAnchor = 'TOPRIGHT'
			self.Buffs['growth-x'] = 'LEFT'
			self.Buffs['growth-y'] = 'DOWN'
			self.Buffs.filter = true
			
			self.Buffs.PostCreateIcon = PostCreateIcon
			self.Buffs.PostUpdateIcon = PostUpdateIcon
		end
		
		self.Combat = self.Health:CreateTexture(nil, 'OVERLAY')
		self.Combat:SetHeight(17)
		self.Combat:SetWidth(17)
		self.Combat:SetPoint('TOPRIGHT', 2, 12)
		self.Combat:SetTexture('Interface\\CharacterFrame\\UI-StateIcon')
		self.Combat:SetTexCoord(0.58, 0.90, 0.08, 0.41)
		
		if(tCastbar) then
			local classcb = select(2, UnitClass('player'))
			local colorcb = oUF.colors.class[classcb]

			self.Castbar = CreateFrame('StatusBar', nil, self)
			self.Castbar:SetPoint('TOP', UIParent, 'CENTER', 0, -93)
			self.Castbar:SetStatusBarTexture(texturebar)
			self.Castbar:SetStatusBarColor(colorcb[1], colorcb[2], colorcb[3])
			self.Castbar:SetBackdrop(backdrophp)
			self.Castbar:SetBackdropColor(colorcb[1]/3, colorcb[2]/3, colorcb[3]/3)
			self.Castbar:SetHeight(19)
			self.Castbar:SetWidth(322)
			
			self.Castbar.Spark = self.Castbar:CreateTexture(nil,'OVERLAY')
			self.Castbar.Spark:SetBlendMode('ADD')
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
		
		if (select(2, UnitClass('player')) == 'DEATHKNIGHT' and tRunebar) then
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
				self.RuneBar[i]:SetOrientation('Vertical')
				self.RuneBar[i]:SetID(i)
				local runetype = GetRuneType(i)
				if(runetype) then
					self.RuneBar[i]:SetStatusBarColor(unpack(oUF.colors.runes[runetype]))
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
		
		if(select(2, UnitClass('player')) == 'PALADIN') then
			self.HolyPower = {}
			
			for i = 1, UnitPowerMax('player', SPELL_POWER_HOLY_POWER) do
				self.HolyPower[i] = self.Health:CreateTexture(nil, 'OVERLAY')
				self.HolyPower[i]:SetHeight(17)
				self.HolyPower[i]:SetWidth(17)
				self.HolyPower[i]:SetTexture(bubbleTex)
				if (i == 1) then
					self.HolyPower[i]:SetPoint('LEFT', self.Health, 'LEFT', 2, 0)
				else
					self.HolyPower[i]:SetPoint('LEFT', self.HolyPower[i-1], 'RIGHT', 1)
				end	
				local color = self.colors.power["HOLY_POWER"]
				self.HolyPower[i]:SetVertexColor(color[1], color[2], color[3])
			end			
		end

		if(select(2, UnitClass('player')) == 'WARLOCK') then
			self.SoulShards = {}
			
			for i = 1, 3 do
				self.SoulShards[i] = self.Health:CreateTexture(nil, 'OVERLAY')
				self.SoulShards[i]:SetHeight(17)
				self.SoulShards[i]:SetWidth(17)
				self.SoulShards[i]:SetTexture(bubbleTex)
				if (i == 1) then
					self.SoulShards[i]:SetPoint('LEFT', self.Health, 'LEFT', 2, 0)
				else
					self.SoulShards[i]:SetPoint('LEFT', self.SoulShards[i-1], 'RIGHT', 1)
				end	
				local color = self.colors.power["SOUL_SHARDS"]
				self.SoulShards[i]:SetVertexColor(color[1], color[2], color[3])
			end
		end
		
		if select(2, UnitClass('player')) == 'DRUID' then
			self.EclipseBar = CreateFrame('Frame', nil, self)
			self.EclipseBar:SetSize(275, 20)
			self.EclipseBar:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, 0)
			self.EclipseBar:SetPoint('TOPRIGHT', self, 'BOTTOMRIGHT', 0, 0)
			self.EclipseBar:SetBackdrop(backdrop)
			self.EclipseBar:SetBackdropColor(1, 1, 1, 1)
			
			self.EclipseBar.LunarBar = CreateFrame('StatusBar', nil, self.EclipseBar)
			self.EclipseBar.LunarBar:SetPoint('LEFT', self.EclipseBar, 'LEFT', 4.5, 0)
			self.EclipseBar.LunarBar:SetSize(266, 13)
			self.EclipseBar.LunarBar:SetStatusBarTexture(texturebar)
			self.EclipseBar.LunarBar:SetStatusBarColor(0, 144/255, 1)
			
			self.EclipseBar.SolarBar = CreateFrame('StatusBar', nil, self.EclipseBar)
			self.EclipseBar.SolarBar:SetPoint('LEFT', self.EclipseBar.LunarBar:GetStatusBarTexture(), 'RIGHT', 0, 0)
			self.EclipseBar.SolarBar:SetSize(266, 13)
			self.EclipseBar.SolarBar:SetStatusBarTexture(texturebar)
			self.EclipseBar.SolarBar:SetStatusBarColor(0.95, 0.73, 0.15)
			--[[
			self.EclipseBar.Glow = self.EclipseBar:CreateTexture(nil, 'OVERLAY')
			self.EclipseBar.Glow:SetTexture('Interface\\CastingBar\\UI-CastingBar-Spark')
			self.EclipseBar.Glow:SetPoint('CENTER', self.EclipseBar.LunarBar, 'RIGHT', 0, 0)
			self.EclipseBar.Glow:SetBlendMode('Add')
			self.EclipseBar.Glow:SetHeight(24)
			self.EclipseBar.Glow:SetWidth(25)
			self.EclipseBar.Glow:SetVertexColor(.69,.31,.31)
			--]]
			self.EclipseBar.Text = setFontString(self.EclipseBar.SolarBar, fontn, 13)
			self.EclipseBar.Text:SetPoint('CENTER', self.EclipseBar, 'CENTER', 0, 0)
			self:Tag(self.EclipseBar.Text, '[pereclipse]%')
		end
		
		if select(2, UnitClass('player')) == 'PRIEST' then
			self.Priestly = setFontString(self.Health, fontn, 20)
			self.Priestly:SetPoint('BOTTOMRIGHT', self.Health, 'TOPRIGHT', 0, -3)
			self:Tag(self.Priestly, '[alekk:ShadowOrbs][alekk:Evangelism]')
		end

		if select(2, UnitClass('player')) == 'MONK' then
			self.Harmony = {}

			for i= 1, UnitPowerMax('player',SPELL_POWER_LIGHT_FORCE) do
				self.Harmony[i] = self.Health:CreateTexture(nil, 'OVERLAY')
				self.Harmony[i]:SetHeight(17)
				self.Harmony[i]:SetWidth(17)
				self.Harmony[i]:SetTexture(bubbleTex)
				if (i == 1) then
					self.Harmony[i]:SetPoint('LEFT', self.Health, 'LEFT', 2, 0)
				else
					self.Harmony[i]:SetPoint('LEFT', self.Harmony[i-1], 'RIGHT', 1)
				end	
				local color = self.colors.power["LIGHT_FORCE"]
				self.Harmony[i]:SetVertexColor(color[1], color[2], color[3])
			end			
		end
	end,
	
	target = function(self)
		self:SetWidth(275)
		self:SetHeight(47)
		--self:SetScale(0.85)
		
		self.Health:SetHeight(27)
		self.Power:SetHeight(10.5)
		
		self.Health.value = setFontString(self.Health, fontn, 13)
		self.Health.value:SetHeight(20)
		self.Health.value:SetPoint('LEFT', 2, 0)
		self.Health.value.frequentUpdates = 1/4
		self:Tag(self.Health.value, '[alekk:smarthp]')
		
		self.Power.value = setFontString(self.Power, fontn, 12)
		self.Power.value:SetPoint('LEFT', self.Power, 'LEFT', 2, 0)
		self:Tag(self.Power.value, '[alekk:tarpp]')
		
		self.Info = setFontString(self.Power, fontn, 12)
		self.Info:SetPoint('RIGHT', self.Power, 'RIGHT', -3, 0)
		self:Tag(self.Info, '[difficulty][smartlevel] [raidcolor][smartclass] |r[race]')
		
		self.Name = setFontString(self.Health, fontn, 13)
		self.Name:SetPoint('RIGHT', self.Health, 'RIGHT',-3,0)
		self.Name:SetWidth(170)
		self.Name:SetHeight(20)
		self.Name:SetJustifyH('RIGHT')
		self:Tag(self.Name, '[name]')
		
		if (tBuffs) then
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
			self.Auras.showDebuffType = true
			
			self.Auras.PostCreateIcon = PostCreateIcon
			self.Auras.PostUpdateIcon = PostUpdateIcon

			--self.sortAuras = {}
			--self.sortAuras.selfFirst = true
		end
		
		self.CPoints = {}
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
			self.Castbar.Spark:SetBlendMode('Add')
			self.Castbar.Spark:SetHeight(35)
			self.Castbar.Spark:SetWidth(25)
			self.Castbar.Spark:SetVertexColor(.69,.31,.31)
		end
	end,
	
	targettarget = function(self)
		self:SetWidth(135)
		self:SetHeight(25)
		--self:SetScale(0.85)
		
		self.Health:SetHeight(16.5)
		self.Power:SetHeight(0)
		
		self.Name = setFontString(self.Health, fontn, 13)
		self.Name:SetPoint('RIGHT', self.Health, 'RIGHT',-3,0)
		self.Name:SetWidth(80)
		self.Name:SetHeight(20)
		self.Name:SetJustifyH('RIGHT')
		self:Tag(self.Name, '[name]')
		
		self.Health.value = setFontString(self.Health, fontn, 13)
		self.Health.value:SetPoint('LEFT', self.Health, 'LEFT', 2, 0)
		self:Tag(self.Health.value, '[perhp]%')
	end,
	
	focus = function(self)
		self:SetWidth(135)
		self:SetHeight(25)
		--self:SetScale(0.85)
		
		self.Health:SetHeight(16.5)
		self.Power:SetHeight(0)
		
		self.Name = setFontString(self.Health, fontn, 13)
		self.Name:SetPoint('LEFT', self.Health, 'LEFT',2,0)
		self.Name:SetWidth(80)
		self.Name:SetHeight(20)
		self.Name:SetJustifyH('LEFT')
		self:Tag(self.Name, '[name]')
		
		self.Health.value = setFontString(self.Health, fontn, 13)
		self.Health.value:SetPoint('RIGHT', self.Health, 'RIGHT', -3, 0)
		self:Tag(self.Health.value, '[perhp]%')
		
		if(tCastbar) then
			self.Castbar = CreateFrame('StatusBar', nil, self)
			self.Castbar:SetPoint('TOP', UIParent, 'CENTER', 0, -123)
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
			self.Castbar.Spark:SetBlendMode('Add')
			self.Castbar.Spark:SetHeight(35)
			self.Castbar.Spark:SetWidth(25)
			self.Castbar.Spark:SetVertexColor(.69,.31,.31)
		end
	end,
	
	focustarget = function(self)
		self:SetWidth(135)
		self:SetHeight(25)
		--self:SetScale(0.85)
		
		self.Health:SetHeight(16.5)
		self.Power:SetHeight(0)
		
		self.Name = setFontString(self.Health, fontn, 13)
		self.Name:SetPoint('LEFT', self.Health, 'LEFT',2,0)
		self.Name:SetWidth(80)
		self.Name:SetHeight(20)
		self.Name:SetJustifyH('LEFT')
		self:Tag(self.Name, '[name]')
		
		self.Health.value = setFontString(self.Health, fontn, 13)
		self.Health.value:SetPoint('RIGHT', self.Health, 'RIGHT', -3, 0)
		self:Tag(self.Health.value, '[perhp]%')
	end,
	
	pet = function(self)
		self:SetWidth(125)
		self:SetHeight(38)
		--self:SetScale(0.85)
		
		self.Health:SetHeight(23)
		self.Power:SetHeight(6)
		
		if (tBuffs) then
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
			self.Auras.showDebuffType = true
			
			self.Auras.PostCreateIcon = PostCreateIcon
			self.Auras.PostUpdateIcon = PostUpdateIcon
		end
		
		self.Name = setFontString(self.Health, fontn, 13)
		self.Name:SetPoint('LEFT', self.Health, 'LEFT',2,0)
		self.Name:SetWidth(80)
		self.Name:SetHeight(20)
		self:Tag(self.Name, '[name]')
		
		self.Health.value = setFontString(self.Health, fontn, 13)
		self.Health.value:SetPoint('RIGHT', self.Health, 'RIGHT', -3, 0)
		self:Tag(self.Health.value, '[perhp]%')
	end,
	
	party = function(self, ...)
		self:SetWidth(125)
		self:SetHeight(38)
		
		self.Health:SetHeight(23)
		self.Power:SetHeight(6)
		
		self.Name = setFontString(self.Health, fontn, 13)
		self.Name:SetPoint('LEFT', self.Health, 'LEFT',2,0)
		self.Name:SetWidth(80)
		self.Name:SetHeight(20)
		self:Tag(self.Name, '[name]')
		
		self.Health.value = setFontString(self.Health, fontn, 13)
		self.Health.value:SetPoint('RIGHT', self.Health, 'RIGHT', -3, 0)
		self:Tag(self.Health.value, '[perhp]%')
	end,	
}

local function Raidering(self, unit)
	self:RegisterForClicks('AnyDown')
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)
	self.menu = menu
	
	self:HookScript("OnShow", updateAllElements)

	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0 ,0 ,0 ,1)
	
	self:SetWidth(125)
	self:SetHeight(38)
	--self:SetScale(0.85)
	
	self.Health = CreateFrame('StatusBar', nil, self)
	self.Health:SetStatusBarTexture(texturebar)
	self.Health:SetStatusBarColor(.31, .31, .31)
	self.Health:SetPoint('LEFT', 4.5, 0)
	self.Health:SetPoint('RIGHT', -4.5, 0)
	self.Health:SetPoint('TOP', 0, -4.5)
	self.Health:SetHeight(23)
	self.Health.colorClass = true
	self.Health.colorReaction = true
	self.Health.colorHappiness = true
	self.Health.colorTapping = true
	self.Health.colorDisconnected = true
	self.Health.frequentUpdates = true

	self.Health.bg = self.Health:CreateTexture(nil, 'BACKGROUND')
	self.Health.bg:SetAllPoints(self.Health)
	self.Health.bg:SetTexture(texturebar)
	self.Health.bg.multiplier = .30
	
	self.Name = setFontString(self.Health, fontn, 13)
	self.Name:SetPoint('LEFT', self.Health, 'LEFT',2,0)
	self.Name:SetWidth(70)
	self.Name:SetHeight(17)
	self.Name:SetJustifyH('LEFT')
	self:Tag(self.Name, '[name]')
	
	self.Health.value = setFontString(self.Health, fontn, 13)
	self.Health.value:SetPoint('RIGHT', self.Health, 'RIGHT', -3, 0)
	self:Tag(self.Health.value, '[perhp]%')

	self.Power = CreateFrame('StatusBar', nil, self)
	self.Power:SetHeight(6)
	self.Power:SetStatusBarTexture(texturebar)
	self.Power:SetStatusBarColor(.25, .25, .35)
	
	self.Power:SetPoint('LEFT', self.Health)
	self.Power:SetPoint('RIGHT', self.Health)
	self.Power:SetPoint('TOP', self.Health, 'BOTTOM', 0, -1)
	self.Power.colorPower = true
	self.Power.frequentUpdates = true

	self.Power.bg = self.Power:CreateTexture(nil, 'BACKGROUND')
	self.Power.bg:SetAllPoints(self.Power)
	self.Power.bg:SetTexture(texturebar)
	self.Power.bg.multiplier = .30
	
	self.RaidIcon = self.Health:CreateTexture(nil, 'OVERLAY')
	self.RaidIcon:SetHeight(13)
	self.RaidIcon:SetWidth(13)
	self.RaidIcon:SetPoint('TOP', self, 0, 5)
	self.RaidIcon:SetTexture('Interface\\TargetingFrame\\UI-RaidTargetingIcons')

	self.Range = {
			insideAlpha = 1,
			outsideAlpha = 0.8,
			}
	
	self.MoveableFrames = true
		
	table.insert(self.__elements, UpdateClassification)
	self:RegisterEvent('UNIT_CLASSIFICATION_CHANGED', UpdateClassification)
end

local function Shared(self, unit)
	
	self:RegisterForClicks('AnyDown')
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)
	self.menu = menu
	
	self:HookScript("OnShow", updateAllElements)

	self:SetBackdrop(backdrop)
	self:SetBackdropColor(0,0,0,1)
	self:SetWidth(125)
	self:SetHeight(38)
	--self:SetScale(0.85)
	
	self.Health = CreateFrame('StatusBar', nil, self)
	self.Health:SetStatusBarTexture(texturebar)
	self.Health:SetStatusBarColor(.31, .31, .31)
	self.Health:SetPoint('LEFT', 4.5,0)
	self.Health:SetPoint('RIGHT', -4.5,0)
	self.Health:SetPoint('TOP', 0, -4.5)
	self.Health:SetHeight(23)
	self.Health.colorClass = true
	self.Health.colorReaction = true
	self.Health.colorHappiness = true
	self.Health.colorTapping = true
	self.Health.colorDisconnected = true
	self.Health.frequentUpdates = true

	self.Health.bg = self.Health:CreateTexture(nil, 'BACKGROUND')
	self.Health.bg:SetAllPoints(self.Health)
	self.Health.bg:SetTexture(texturebar)
	self.Health.bg.multiplier = .30

	self.Power = CreateFrame('StatusBar', nil, self)
	self.Power:SetHeight(9.5)
	self.Power:SetStatusBarTexture(texturebar)
	self.Power:SetStatusBarColor(.25, .25, .35)
	
	self.Power:SetPoint('LEFT', self.Health)
	self.Power:SetPoint('RIGHT', self.Health)
	self.Power:SetPoint('TOP', self.Health, 'BOTTOM', 0, -1)
	self.Power.colorPower = true
	self.Power.frequentUpdates = true

	self.Power.bg = self.Power:CreateTexture(nil, 'BACKGROUND')
	self.Power.bg:SetAllPoints(self.Power)
	self.Power.bg:SetTexture(texturebar)
	self.Power.bg.multiplier = .30
	
	self.RaidIcon = self.Health:CreateTexture(nil, 'OVERLAY')
	self.RaidIcon:SetHeight(18)
	self.RaidIcon:SetWidth(18)
	self.RaidIcon:SetPoint('TOP', self, 0, 5)
	self.RaidIcon:SetTexture('Interface\\TargetingFrame\\UI-RaidTargetingIcons')
	
	self.Leader = self.Health:CreateTexture(nil, 'OVERLAY')
	self.Leader:SetHeight(17)
	self.Leader:SetWidth(17)
	self.Leader:SetPoint('TOPLEFT', -2, 12)
	self.Leader:SetTexture('Interface\\GroupFrame\\UI-Group-LeaderIcon')
	
	self.PostCreateEnchantIcon = PostCreateIcon
	self.PostUpdateEnchantIcons = CreateEnchantTimer

	self.Range = {
			insideAlpha = 1,
			outsideAlpha = 0.8,
			}
	
	self.MoveableFrames = true
	
	table.insert(self.__elements, UpdateClassification)
	self:RegisterEvent('UNIT_CLASSIFICATION_CHANGED', UpdateClassification)
	
	if(UnitSpecific[unit]) then
		return UnitSpecific[unit](self)
	end
end

  -----------------------------
  -- SPAWN UNITS
  -----------------------------

oUF:RegisterStyle('alekk', Shared)
oUF:RegisterStyle('alekk_maintank', Raidering)

oUF:Factory(function(self)
	oUF:SetActiveStyle('alekk')

	oUF:Spawn('player'):SetPoint('CENTER', -305, -92)
	oUF:Spawn('target'):SetPoint('CENTER', 305, -92)
	oUF:Spawn('pet'):SetPoint('TOPLEFT', oUF_AlekkPlayer, 'BOTTOMLEFT', 0, -45)
	oUF:Spawn('targettarget'):SetPoint('TOPRIGHT', oUF_AlekkTarget, 'BOTTOMRIGHT', 0, -1)
	if select(2, UnitClass('player')) == 'DRUID' then
		oUF:Spawn('focus'):SetPoint('TOPLEFT', oUF_AlekkPlayer, 'BOTTOMLEFT', 0, -20)
	else
		oUF:Spawn('focus'):SetPoint('TOPLEFT', oUF_AlekkPlayer, 'BOTTOMLEFT', 0, -1)
	end
	oUF:Spawn('focustarget'):SetPoint('TOPLEFT', oUF_AlekkFocus, 'TOPRIGHT', 5, 0)
		
	-- Maintank Frames
	oUF:SetActiveStyle('alekk_maintank')	
	local maintank = oUF:SpawnHeader('oUF_MainTank', nil, 'raid',
		'showRaid', true,
		'xOffset', 5,
		'yOffset', -3,
		'maxColumns', 1,
		'unitsPerColumn', 5,
		'columnSpacing', 2,
		'point', 'TOP',
		'columnAnchorPoint', 'BOTTOM',
		'sortMethod', 'NAME',
		'groupFilter', 'MAINTANK',
		'oUF-initialConfigFunction', ([[
			self:SetWidth(%d)
			self:SetHeight(%d)
			]]):format(125, 38, mscale))
	maintank:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 8, 225)
	
	-- Maintank Targets
	local mtt = oUF:SpawnHeader(
		nil, nil, 'raid',
		'showRaid', true,
		'xOffset', 5,
		'yOffset', -3,
		'maxColumns', 1,
		'unitsPerColumn', 5,
		'columnSpacing', 2,
		'point', 'TOP',
		'columnAnchorPoint', 'BOTTOM',
		'sortMethod', 'NAME',
		'groupFilter', 'MAINTANK',
		'oUF-initialConfigFunction', ([[
			self:SetWidth(%d)
			self:SetHeight(%d)
			self:SetAttribute('unitsuffix', 'target')
			]]):format(125, 38, mscale))
	mtt:SetPoint('TOPLEFT', maintank, 'TOPRIGHT', 5, 0)
	
	-- party
	if tParty then
		local party = oUF:SpawnHeader('oUF_Party', nil, 'party',
			'showParty', true, 
			'showPlayer', true,
			'sortMethod', 'NAME',
			'yOffset', -3,
			'oUF-initialConfigFunction', ([[
				self:SetWidth(%d)
				self:SetHeight(%d)
				]]):format(125, 38, mscale))
		party:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 8, 225)
	end


end)