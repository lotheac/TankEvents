-- vim: sw=2 sts=2 et
local eh = CreateFrame("Frame", "TEv", UIParent)
eh:RegisterEvent("ADDON_LOADED")

TankEv = {}

function eh:InitAddon(ev, addon)
  if not (ev == "ADDON_LOADED" and addon == "TankEvents") then
    return
  end
  local latest = 1
  local defaultsize = {150,200}
  if TankEvents == nil then
    TankEvents = {
      version = latest,
      offset = {0, 0},
      size = defaultsize,
      movable = true
    }
  end
  local f = CreateFrame("ScrollFrame", "TankEventsFrame", UIParent)
  TankEvFrame = f
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
  f:EnableMouse(TankEvents.movable)
  f:EnableMouseWheel(true)
  -- TODO: mousewheel scrolling

  f:SetSize(unpack(TankEvents.size))
  if not f:IsUserPlaced() then
    f:SetPoint("CENTER", UIParent, "CENTER", unpack(TankEvents.offset))
  end
  f.bg = f:CreateTexture(nil, "BACKGROUND")
  f.bg:SetAllPoints()
  local alpha = TankEvents.movable and 0.5 or 0
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
      t:SetPoint("BOTTOMRIGHT", TankEv[i - 1], "TOPRIGHT")
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
    local function showtooltip(self)
      if not self.tooltip then return end
      GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
      GameTooltip:SetText(self.tooltip)
      GameTooltip:Show()
    end
    t:SetScript("OnEnter", showtooltip)
    t:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
    t:EnableMouse(not TankEvents.movable)
    TankEv[i] = t
  end
  TankEvFrame.bottom = TankEv[1]
  TankEvFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  TankEvFrame:SetScript("OnEvent", TEv.CombatEvent)
end
eh:SetScript("OnEvent", eh.InitAddon)

function TEv:Add(msg, tooltip, icon, color)
  -- anchor topmost frame to container
  local ev = TankEv[TankEvFrame.bottom.nexti]
  ev:SetPoint("BOTTOMRIGHT", TankEvFrame, "BOTTOMRIGHT")
  -- and move the rest up
  local bottom = TankEvFrame.bottom
  bottom:SetPoint("BOTTOMRIGHT", ev, "TOPRIGHT")
  TankEvFrame.top = TankEv[ev.nexti]
  TankEvFrame.bottom = ev
  if (icon) then
    ev.icon:SetTexture(icon)
    ev.icon:Show()
  else
    ev.icon:Hide()
  end
  ev.tooltip = tooltip
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
  if dguid ~= UnitGUID("player") then return end
  local msg = CombatLog_OnEvent(Blizzard_CombatLog_CurrentSettings, CombatLogGetCurrentEventInfo())
  local seloffset
  local spid, spnam, spsch
  local texture
  if ev == "SWING_DAMAGE" then
    seloffset = 12
  elseif ev == "ENVIRONMENTAL_DAMAGE" then
    seloffset = 13
  elseif ev == "RANGE_DAMAGE" or ev == "SPELL_DAMAGE" or ev == "SPELL_PERIODIC_DAMAGE" then
    spid, spnam, spsch = select(12, CombatLogGetCurrentEventInfo())
    seloffset = 15
  elseif string.find(ev, "_DAMAGE$") then
    print("unhandled evtype ".. ev)
    return
  elseif string.find(ev, "_HEAL$") then
    local spid, spnam, spsch, heal, overheal, absorb, crit = select(12, CombatLogGetCurrentEventInfo())
    local effheal = heal - overheal
    if (effheal < 0.025 * UnitHealthMax("player")) then return end
    local icon = select(3, GetSpellInfo(spid))
    TEv:Add(string.format("+%s", AbbreviateLargeNumbers(effheal)), msg, icon, {0,1,0})
    return
  else return
  end

  local dam, overkill, sch, resist, block, absorb, crit = select(seloffset, CombatLogGetCurrentEventInfo())
  if (dam < 0.025 * UnitHealthMax("player")) then return end
  local text = AbbreviateLargeNumbers(dam) .. "|cffffffff"
  resist = resist or 0
  absorb = absorb or 0
  block = block or 0
  if (resist >= 0.1 * dam) then text = text .. string.format(" <%s>", AbbreviateLargeNumbers(resist)) end
  if (block >= 0.1 * dam) then text = text .. string.format(" {%s}", AbbreviateLargeNumbers(block)) end
  if (absorb >= 0.1 * dam) then text = text .. string.format(" (%s)", AbbreviateLargeNumbers(absorb)) end
  if (overkill > 0) then text = string.format("%s †", text) end
  local icon
  if (spid) then
    icon = select(3, GetSpellInfo(spid))
  end
  TEv:Add(text, msg, icon, Colors[sch])
end

SLASH_TEV1 = '/tev'
function SlashCmdList.TEV(msg, editbox)
  TankEvents.movable = not TankEvents.movable
  TankEvFrame:EnableMouse(TankEvents.movable)
  for _,ev in pairs(TankEv) do
    ev:EnableMouse(not TankEvents.movable)
  end
  local alpha = TankEvents.movable and 0.5 or 0
  TankEvFrame.bg:SetColorTexture(0, 0, 0, alpha)
end
