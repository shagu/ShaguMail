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

local index, running, money, stalled, mailcount
local mail = CreateFrame("Frame", "ShaguMail", MailFrame)
mail:RegisterEvent("UI_ERROR_MESSAGE")
mail:RegisterEvent("MAIL_INBOX_UPDATE")
mail:RegisterEvent("PLAYER_MONEY")
mail:RegisterEvent("BAG_UPDATE")
mail:SetScript("OnEvent", function()
  if event == "UI_ERROR_MESSAGE" then
    if running and arg1 == ERR_INV_FULL then
      this:Stop("Aborted")
    elseif arg1 == ERR_ITEM_MAX_COUNT then
      index = index + 1
    end
  elseif event == "MAIL_INBOX_UPDATE" then
    index = 1
  else
    stalled = nil
  end
end)

mail:SetScript("OnUpdate", function()
  if ( this.tick or 0) < GetTime() then CheckInbox() this.tick = GetTime() + 1 end

  mailcount = GetInboxNumItems()

  -- enable/disable the mail opening button
  if mailcount > 0 and not running then
    mail.button:Enable()
  else
    mail.button:Disable()
  end

  -- abort here while not opening
  if not running then return end

  -- wait for mail events to be processed
  if stalled and stalled > GetTime() then return end

  -- while running we require fully updated mail data each tick
  CheckInbox()
  mailcount = GetInboxNumItems()

  -- check if our index exceeded the available mails and stop
  if index > mailcount then
    this:Stop("Done")
    return
  end

  -- read new mail data
  local _, _, _, subject, money, cod, _, item, _, _, _, _, gm = GetInboxHeaderInfo(index)

  -- skip gm, cod and text-only mails
  if gm or cod > 0 or ( money <= 0 and not item ) then
    index = index + 1
    return
  end

  -- wait for events to signal an opened mail
  stalled = (item or money > 0) and GetTime() + .5 or nil

  -- actually open the mail and save the count
  lastcount = mailcount
  TakeInboxMoney(index)
  TakeInboxItem(index)
  GetInboxText(index)
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
