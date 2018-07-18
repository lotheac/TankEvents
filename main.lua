-- vim: sw=2 sts=2 et
local eh = CreateFrame("Frame", "TankEventsLoad", UIParent)
eh:RegisterEvent("ADDON_LOADED")

function eh:InitAddon(ev, addon)
  if not (ev == "ADDON_LOADED" and addon == "TankEvents") then
    return
  end
  local latest = 1
  if TankEvents == nil then
    TankEvents = {
      version = latest,
      offset = {0, 0},
      size = {100,100},
      movable = true
    }
  end
  local f = CreateFrame("ScrollFrame", "TankEventsFrame", UIParent)
  TankEvFrame = f
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:SetResizable(true)
  f:SetMinResize(100,100)
  f:RegisterForDrag("LeftButton", "RightButton")
  f:SetScript("OnDragStart", function(t,b)
    if b == "LeftButton" then
      t:StartMoving()
    else
      t:StartSizing()
    end
  end)
  f:SetScript("OnDragStop", f.StopMovingOrSizing)
  f:EnableMouse(TankEvents.movable)
  f:EnableMouseWheel(true)

  f:SetSize(unpack(TankEvents.size))
  if not f:IsUserPlaced() then
    f:SetPoint("CENTER", UIParent, "CENTER", unpack(TankEvents.offset))
  end
  f.tex = f:CreateTexture(nil, "BACKGROUND")
  f.tex:SetAllPoints()
  f.tex:SetColorTexture(0, 0, 0, 0.5)
end
eh:SetScript("OnEvent", eh.InitAddon)

SLASH_TEV1 = '/tev'
function SlashCmdList.TEV(msg, editbox)
  TankEvents.movable = not TankEvents.movable
  TankEvFrame:EnableMouse(TankEvents.movable)
  local alpha = TankEvents.movable and 0.5 or 0
  TankEvFrame.tex:SetColorTexture(0, 0, 0, alpha)
end

