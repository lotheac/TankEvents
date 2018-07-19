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

  local evheight = nil
  local evcontainer = CreateFrame("Frame", "TankEvContainer", f)
  evcontainer:SetAllPoints()
  f:SetScrollChild(evcontainer)
  for i=1, 100 do
    local t = evcontainer:CreateFontString("TankEvent"..i, "ARTWORK", "GameFontNormal")
    if i == 1 then
      t:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT")
      t:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT")
      t.nexti = 100
    else
      t:SetPoint("BOTTOMRIGHT", TankEv[i - 1], "TOPRIGHT")
      t:SetPoint("BOTTOMLEFT", TankEv[i - 1], "TOPLEFT")
      t.nexti = i - 1
    end
    if not evheight then
      local _, fontsize, _ = t:GetFont()
      evheight = fontsize + 2
    end
    t:SetHeight(evheight)
    t:SetJustifyH("RIGHT")
    t:SetJustifyV("CENTER")
    TankEv[i] = t
  end
  TankEvFrame.bottom = TankEv[1]
  TankEvFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
  TankEvFrame:SetScript("OnEvent", TEv.CombatEvent)
end
eh:SetScript("OnEvent", eh.InitAddon)

function TEv:Add(msg)
  -- anchor topmost frame to container
  local ev = TankEv[TankEvFrame.bottom.nexti]
  ev:SetPoint("BOTTOMRIGHT", TankEvFrame, "BOTTOMRIGHT")
  ev:SetPoint("BOTTOMLEFT", TankEvFrame, "BOTTOMLEFT")
  -- and move the rest up
  local bottom = TankEvFrame.bottom
  bottom:SetPoint("BOTTOMRIGHT", ev, "TOPRIGHT")
  bottom:SetPoint("BOTTOMLEFT", ev, "TOPLEFT")
  TankEvFrame.top = TankEv[ev.nexti]
  TankEvFrame.bottom = ev
  ev:SetText(msg)
end

function TEv:CombatEvent(event)
  if event ~= "COMBAT_LOG_EVENT_UNFILTERED" then
    print("unexpected " .. event)
  end
  local ts, ev, hidecaster, sguid, sname, sflg, srflg, dguid, dflg, drflg = CombatLogGetCurrentEventInfo()
  if string.find(ev, "^SPELL_") then
    local spid, spnam, spsch = select(12, CombatLogGetCurrentEventInfo())
    TEv:Add(sname .. "(" .. spsch .. ")> " .. spnam)
  end
end

SLASH_TEV1 = '/tev'
function SlashCmdList.TEV(msg, editbox)
  TankEvents.movable = not TankEvents.movable
  TankEvFrame:EnableMouse(TankEvents.movable)
  local alpha = TankEvents.movable and 0.5 or 0
  TankEvFrame.bg:SetColorTexture(0, 0, 0, alpha)
end
