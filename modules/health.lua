local Health = ShadowUF:NewModule("Health")
ShadowUF:RegisterModule(Health, "healthBar", ShadowUFLocals["Health bar"], "bar")

function Health:UnitEnabled(frame, unit)
	if( not frame.visibility.healthBar ) then
		return
	end
	
	frame.healthBar = frame.healthBar or ShadowUF.Units:CreateBar(frame, "HealthBar")
	frame:RegisterUnitEvent("UNIT_HEALTH", self.Update)
	frame:RegisterUnitEvent("UNIT_MAXHEALTH", self.Update)
	frame:RegisterUnitEvent("UNIT_FACTION", self.Update)
	frame:RegisterUnitEvent("UNIT_THREAT_SITUATION_UPDATE", self.UpdateThreat)
	frame:RegisterUpdateFunc(self.Update)
	frame:RegisterUpdateFunc(self.UpdateColor)
	frame:RegisterUpdateFunc(self.UpdateThreat)
end

function Health:UnitDisabled(frame, unit)
	frame:UnregisterAll(self.Update)
end

local function setBarColor(bar, r, g, b)
	bar:SetStatusBarColor(r, g, b, ShadowUF.db.profile.layout.general.barAlpha)
	bar.background:SetVertexColor(r, g, b, ShadowUF.db.profile.layout.general.backgroundAlpha)
end

local function setGradient(healthBar, unit)
	local current, max = UnitHealth(unit), UnitHealthMax(unit)
	local percent = current / max
	local r, g, b = 0, 0, 0
	
	if( percent == 1.0 ) then
		r, g, b = ShadowUF.db.profile.layout.healthColor.green.r, ShadowUF.db.profile.layout.healthColor.green.g, ShadowUF.db.profile.layout.healthColor.green.b
	elseif( percent > 0.50 ) then
		r = (ShadowUF.db.profile.layout.healthColor.red.r - percent) * 2
		g = ShadowUF.db.profile.layout.healthColor.green.g
	else
		r = ShadowUF.db.profile.layout.healthColor.red.r
		g = percent * 2
	end
	
	setBarColor(healthBar, r, g, b)
end

--[[
	WoWWIki docs on this are terrible, stole these from Omen
	
	nil = the unit is not on the mob's threat list
	0 = 0-99% raw threat percentage (no indicator shown)
	1 = 100% or more raw threat percentage (yellow warning indicator shown)
	2 = tanking, other has 100% or more raw threat percentage (orange indicator shown)
	3 = tanking, all others have less than 100% raw percentage threat (red indicator shown)
]]

function Health.UpdateThreat(self, unit)
	if( ShadowUF.db.profile.units[self.unitType].colorAggro and UnitThreatSituation(unit) == 3 ) then
		setBarColor(self.healthBar, ShadowUF.db.profile.layout.healthColor.red.r, ShadowUF.db.profile.layout.healthColor.red.g, ShadowUF.db.profile.layout.healthColor.red.b)
		self.healthBar.hasAggro = true
	elseif( self.healthBar.hasAggro ) then
		self.healthBar.hasAggro = nil
		Health.UpdateColor(self, unit)
	end
end

function Health.UpdateColor(self, unit)
	local color

	-- Tapped by a non-party member
	if( not UnitIsTappedByPlayer(unit) and UnitIsTapped(unit) ) then
		color = ShadowUF.db.profile.layout.healthColor.tapped
	elseif( ShadowUF.db.profile.units[self.unitType].healthColor == "reaction" and not UnitIsFriend(unit, "player") ) then
		if( UnitPlayerControlled(unit) ) then
			if( UnitCanAttack("player", unit) ) then
				color = ShadowUF.db.profile.layout.healthColor.red
			else
				color = ShadowUF.db.profile.layout.healthColor.enemyUnattack
			end
		elseif( UnitReaction(unit, "player") ) then
			local reaction = UnitReaction(unit, "player")
			if( reaction > 4 ) then
				color = ShadowUF.db.profile.layout.healthColor.green
			elseif( reaction == 4 ) then
				color = ShadowUF.db.profile.layout.healthColor.yellow
			elseif( reaction < 4 ) then
				color = ShadowUF.db.profile.layout.healthColor.red
			end
		end
	elseif( ShadowUF.db.profile.units[self.unitType].healthColor == "class" and UnitIsPlayer(unit) ) then
		local class = select(2, UnitClass(unit))
		if( class and RAID_CLASS_COLORS[class] ) then
			color = RAID_CLASS_COLORS[class]
		end
	elseif( ShadowUF.db.profile.units[self.unitType].healthColor == "static" ) then
		color = ShadowUF.db.profile.layout.healthColor.green
	elseif( ShadowUF.db.profile.units[self.unitType].colorAggro ) then
		Health.UpdateThreat(self, unit)
		
		if( self.healthBar.hasAggro ) then
			return
		end
	end
	
	if( color ) then
		setBarColor(self.healthBar, color.r, color.g, color.b)
	else
		setGradient(self.healthBar, unit)
	end
end

function Health.Update(self, unit)
	local max = UnitHealthMax(unit)
	local current = UnitHealth(unit)
	
	self.healthBar:SetMinMaxValues(0, max)
	self.healthBar:SetValue(current)
		
	if( not self.healthBar.hasAggro and ShadowUF.db.profile.units[self.unitType].healthColor == "percent" ) then
		setGradient(self.healthBar, unit)
	end
end
