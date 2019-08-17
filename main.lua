-- vim: sw=2 sts=2 et
local TEv = CreateFrame("ScrollFrame", "TankEvents", UIParent)
TEv:RegisterEvent("ADDON_LOADED")

TEv.events = {}
TEv.config = nil

function TEv:InitAddon(ev, addon)
  if not (ev == "ADDON_LOADED" and addon == "TankEvents") then
    return
  end
  local latest = 1
  local defaultsize = {150,200}
  if self.config == nil then
    self.config = {
      version = latest,
      offset = {0, 0},
      size = defaultsize,
      movable = true
    }
  end
  local f = self
  f:SetFrameStrata("LOW")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:SetResizable(true)
  f:SetMinResize(unpack(defaultsize))
  f:RegisterForDrag("LeftButton", "RightButton")
  f:SetScript("OnDragStart", function(t,b)
    if b == "LeftButton" then
      t:StartMoving()
    else
      t:StartSizing()
    end
  end)
  -- TODO: save position
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:EnableMouse(self.config.movable)
  f:EnableMouseWheel(true)
  -- TODO: mousewheel scrolling

  f:SetSize(unpack(self.config.size))
  if not f:IsUserPlaced() then
    f:SetPoint("CENTER", UIParent, "CENTER", unpack(self.config.offset))
  end
  f.bg = f:CreateTexture(nil, "BACKGROUND")
  f.bg:SetAllPoints()
  local alpha = self.config.movable and 0.5 or 0
  f.bg:SetColorTexture(0, 0, 0, alpha)

  local evheight = 16
  local evcontainer = CreateFrame("Frame", "TankEvContainer", f)
  evcontainer:SetAllPoints()
  f:SetScrollChild(evcontainer)
  for i=1, 100 do
    local t = CreateFrame("Frame", "TankEvent"..i, evcontainer)
    local fs = evcontainer:CreateFontString("TankEventText"..i, "ARTWORK", "GameFontNormal")
    local icon = t:CreateTexture("TankEventIcon"..i, "ARTWORK")
    t.tooltip = nil
    t.fs = fs
    t.icon = icon
    if i == 1 then
      t:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT")
      t.nexti = 100
    else
      t:SetPoint("BOTTOMRIGHT", self.events[i - 1], "TOPRIGHT")
      t.nexti = i - 1
    end
    t:SetHeight(evheight)
    t.icon:SetPoint("BOTTOMRIGHT", t, "BOTTOMRIGHT")
    t.icon:SetPoint("TOPRIGHT", t, "TOPRIGHT")
    t.icon:SetWidth(evheight)
    t.fs:SetPoint("BOTTOMRIGHT", t.icon, "BOTTOMLEFT", -2, 0)
    t.fs:SetPoint("TOPRIGHT", t.icon, "TOPLEFT", -2, 0)
    t.fs:SetJustifyH("RIGHT")
    t.fs:SetJustifyV("CENTER")
    function t:GetCombatLogMessage()
      -- this is terrible, but there is no API to remove the escape seqs
      -- nor to get a combat log message without them.
      -- just assume we only have colorings, raid marker icons and hyperlinks
      -- to units/spells; spell links would be fine but need to be replaced
      -- with ones from GetSpellLink for proper chat formatting.
      local msg = self.tooltip
      msg = msg:gsub("|Hunit:.-|h(.-)|h", "%1")
      msg = msg:gsub("|Hspell:.-|h(.-)|h", "%1")
      msg = msg:gsub("|c%x%x%x%x%x%x%x%x(.-)|r", "%1")
      -- for some reason target marker icons are formatted like:
      -- |Hicon:...|h|T...|t|h
      -- ie. there is an extra '|h' after the closing '|t'.
      msg = msg:gsub("|Hicon:.-|h", "")
      msg = msg:gsub("|T.-|t|h", "")
      return msg
    end
    function t:ShowSpellTooltipWindow()
      if (not ItemRefTooltip:IsVisible()) then
        ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE");
      end
      ItemRefTooltip:SetHyperlink("spell:" .. self.spellid)
      ItemRefTooltip:Show()
    end
    local function insertintoeditbox(msg)
      local editbox = GetCurrentKeyBoardFocus()
      if editbox and editbox:IsVisible() then
        editbox:Insert(msg)
      else
        ChatFrame_OpenChat(msg)
      end
    end
    local function clickhandler(self)
      if IsControlKeyDown() then
        insertintoeditbox(self:GetCombatLogMessage())
      elseif IsShiftKeyDown() and self.spellid then
        insertintoeditbox(GetSpellLink(self.spellid))
      elseif self.spellid then
        self:ShowSpellTooltipWindow()
      end
    end
    local function showtooltip(self)
      if not self.tooltip then return end
      GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
      GameTooltip:SetText(self.tooltip)
      GameTooltip:Show()
    end
    t:SetScript("OnEnter", showtooltip)
    t:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
    t:SetScript("OnMouseUp", clickhandler)
    t:EnableMouse(not self.config.movable)
    self.events[i] = t
  end
  self.bottom = self.events[1]
  self:UnregisterEvent("ADDON_LOADED")
  self:SetScript("OnEvent", self.CombatEvent)
  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end
TEv:SetScript("OnEvent", TEv.InitAddon)

function TEv:Add(msg, tooltip, icon, color, spellid)
  -- anchor topmost frame to container
  local ev = self.events[self.bottom.nexti]
  ev:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT")
  -- and move the rest up
  local bottom = self.bottom
  bottom:SetPoint("BOTTOMRIGHT", ev, "TOPRIGHT")
  self.bottom = ev
  if (icon) then
    ev.icon:SetTexture(icon)
    ev.icon:Show()
  else
    ev.icon:Hide()
  end
  ev.tooltip = tooltip
  ev.spellid = spellid
  if not color then color = { 1, 1, 0 } end
  ev.fs:SetTextColor(unpack(color))
  ev.fs:SetText(msg)
  ev:SetWidth(ev.fs:GetStringWidth() + 2 + ev.icon:GetWidth())
end

local Colors = {
  [0x1] = {1,1,1},      --phys
  [0x2] = {1,0.9,0.5},  --holy
  [0x4] = {1,0.5,0},    --fire
  [0x8] = {0.6,1,0.6},  --nature
  [0x10] = {0.5,1,1},   --frost
  [0x20] = {0.5,0.5,1}, --shadow
  [0x40] = {1,0.5,1}    --arcane
}

function TEv:CombatEvent(event)
  if event ~= "COMBAT_LOG_EVENT_UNFILTERED" then
    print("unexpected " .. event)
  end
  local ts, ev, hidecaster, sguid, sname, sflg, srflg, dguid, dflg, drflg = CombatLogGetCurrentEventInfo()
  if not (dguid == UnitGUID("player") or sguid == UnitGUID("player")) then
    return
  end
  local spid, spnam, spsch
  local icon
  local msg = CombatLog_OnEvent(Blizzard_CombatLog_CurrentSettings, CombatLogGetCurrentEventInfo())
  local seloffset
  local to_me = dguid == UnitGUID("player")
  if to_me and ev == "SWING_DAMAGE" then
    seloffset = 12
  elseif to_me and ev == "ENVIRONMENTAL_DAMAGE" then
    seloffset = 13
  elseif to_me and (ev == "RANGE_DAMAGE" or ev == "SPELL_DAMAGE" or ev == "SPELL_PERIODIC_DAMAGE") then
    spid, spnam, spsch = select(12, CombatLogGetCurrentEventInfo())
    seloffset = 15
  elseif to_me and string.find(ev, "_DAMAGE$") then
    print("unhandled evtype ".. ev)
    return
  elseif to_me and string.find(ev, "_HEAL$") then
    local spid, spnam, spsch, heal, overheal, absorb, crit = select(12, CombatLogGetCurrentEventInfo())
    local effheal = heal - overheal
    if (effheal < 0.025 * UnitHealthMax("player")) then return end
    local icon = select(3, GetSpellInfo(spid))
    self:Add(string.format("+%s", AbbreviateLargeNumbers(effheal)), msg, icon, {0,1,0}, spid)
    return
  elseif ev == "SPELL_INTERRUPT" and sguid == UnitGUID("player") then
    local spid, spnam, spsch, extraspid, extraspnam = select(12, CombatLogGetCurrentEventInfo())
    icon = select(3, GetSpellInfo(spid))
    self:Add(extraspnam, msg, icon, {1,1,0}, extraspid)
    return
  else return
  end

  local dam, overkill, sch, resist, block, absorb, crit = select(seloffset, CombatLogGetCurrentEventInfo())
  if (dam < 0.025 * UnitHealthMax("player")) then return end
  local text = AbbreviateLargeNumbers(dam)
  resist = resist or 0
  absorb = absorb or 0
  block = block or 0
  if (resist >= 0.1 * dam) then text = text .. string.format(" <%s>", AbbreviateLargeNumbers(resist)) end
  if (block >= 0.1 * dam) then text = text .. string.format(" {%s}", AbbreviateLargeNumbers(block)) end
  if (absorb >= 0.1 * dam) then text = text .. string.format(" (%s)", AbbreviateLargeNumbers(absorb)) end
  if (overkill > 0) then text = string.format("%s|cffffffff †", text) end
  local icon
  if (spid) then
    icon = select(3, GetSpellInfo(spid))
  end
  print(self:GetName() .. " " .. self:GetObjectType())
  self:Add(text, msg, icon, Colors[sch], spid)
end

SLASH_TEV1 = '/tev'
function SlashCmdList.TEV(msg, editbox)
  TEv.config.movable = not TEv.config.movable
  TEv:EnableMouse(TEv.config.movable)
  for _,ev in ipairs(TEv.events) do
    ev:EnableMouse(not TEv.config.movable)
  end
  local alpha = TEv.config.movable and 0.5 or 0
  TEv.bg:SetColorTexture(0, 0, 0, alpha)
end
