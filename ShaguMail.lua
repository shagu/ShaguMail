-- pfUI Compatibility
local SkinButton = pfUI and pfUI.api.SkinButton or function() return end

-- ShaguMail
local function BeautifyGoldString(money)
  local gold = floor(money/100/100)
  local silver = floor(mod((money/100),100))
  local copper = floor(mod(money,100))

  if gold > 0 then
    return string.format("|r%d|cffffd700g|r %02d|cffc7c7cfs|r %02d|cffeda55fc|r", gold, silver, copper)
  elseif silver > 0 then
    return string.format("|r%d|cffc7c7cfs|r %02d|cffeda55fc|r", silver, copper)
  else
    return string.format("|r%d|cffeda55fc|r", ( copper or 0 ))
  end
end

local index, running, money
local mail = CreateFrame("Frame", "ShaguMail", MailFrame)
mail:RegisterEvent("UI_ERROR_MESSAGE")
mail:RegisterEvent("MAIL_INBOX_UPDATE")
mail:SetScript("OnEvent", function()
  if event == "UI_ERROR_MESSAGE" then
    if arg1 == ERR_INV_FULL then
      this:Stop("Aborted")
    elseif arg1 == ERR_ITEM_MAX_COUNT then
      index = index + 1
    end
  elseif event == "MAIL_INBOX_UPDATE" then
    index = 1
  end
end)

mail:SetScript("OnUpdate", function()
  if ( this.tick or 0) < GetTime() then CheckInbox() this.tick = GetTime() + 1 end

  if GetInboxNumItems() > 0 and not running then
    mail.button:Enable()
  else
    mail.button:Disable()
  end

  if not running then return end
  if index > GetInboxNumItems() then
    this:Stop("Done")
  else
    local _, _, _, _, money, cod, _, item, _, _, _, _, gm = GetInboxHeaderInfo(index)
    -- skip gm, cod and text-only mails
    if gm or cod > 0 or ( money <= 0 and not item ) then
      index = index + 1
      return
    end

    TakeInboxMoney(index)
    TakeInboxItem(index)
    GetInboxText(index)
  end
end)

mail.Start = function()
  DEFAULT_CHAT_FRAME:AddMessage("Processing |cff33ffcc" .. GetInboxNumItems() .. "|r Mails")
  money = GetMoney()
  running = true
  index = 1
end

mail.Stop = function(self, reason)
  local diff = GetMoney() - money
  local prefix = diff < 0 and "|cffff3333-|r" or "|cff33ff33+|r"
  local money = prefix .. BeautifyGoldString(abs(diff))
  DEFAULT_CHAT_FRAME:AddMessage("Mails " .. reason .. ". Money difference " .. money)
  running = nil
end

-- open all button
mail.button = CreateFrame("Button", "ShaguMailOpenAll", InboxFrame, "UIPanelButtonTemplate")
mail.button:SetPoint("BOTTOM", -10, 95)
mail.button:SetWidth(100)
mail.button:SetHeight(20)
mail.button:SetText("Open All")
mail.button:SetScript("OnClick", mail.Start)
SkinButton(mail.button)
