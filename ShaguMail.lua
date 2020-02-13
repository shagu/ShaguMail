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

local auctions = {
  cancel  = gsub(AUCTION_REMOVED_MAIL_SUBJECT, "%%s", ".*"),
  expire  = gsub(AUCTION_EXPIRED_MAIL_SUBJECT, "%%s", ".*"),
  outbid  = gsub(AUCTION_OUTBID_MAIL_SUBJECT, "%%s", ".*"),
  pending = gsub(AUCTION_INVOICE_MAIL_SUBJECT, "%%s", ".*"),
  success = gsub(AUCTION_SOLD_MAIL_SUBJECT, "%%s", ".*"),
  won     = gsub(AUCTION_WON_MAIL_SUBJECT, "%%s", ".*"),
}

function IsAuctionMail(subject)
  if not subject then return end
  for k, pattern in pairs(auctions) do
    if strfind(subject, pattern) then return true end
  end
end

local index, running, money, stalled, mailcount, lastcount
local mail = CreateFrame("Frame", "ShaguMail", MailFrame)
mail:RegisterEvent("UI_ERROR_MESSAGE")
mail:RegisterEvent("PLAYER_MONEY")
mail:RegisterEvent("BAG_UPDATE")
mail:SetScript("OnEvent", function()
  if running and event == "UI_ERROR_MESSAGE" then
    if arg1 == ERR_INV_FULL then
      this:Stop("Aborted")
    elseif arg1 == ERR_ITEM_MAX_COUNT then
      index = index + 1
    end
  elseif stalled then
    stalled = nil
  end
end)

mail:SetScript("OnUpdate", function()
  if ( this.tick or 0) < GetTime() then CheckInbox() this.tick = GetTime() + 1 end

  mailcount = GetInboxNumItems()

  -- enable/disable the mail opening button
  if mailcount > 0 and not running then
    buttonstate = true
    mail.button_all:Enable()
    mail.button_ah:Enable()
  else
    buttonstate = nil
    mail.button_all:Disable()
    mail.button_ah:Disable()
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

  -- skip gm, cod and text-only mails (also skip non-auction mails)
  if gm or cod > 0 or ( money <= 0 and not item ) or ( running == "AH" and not IsAuctionMail(subject)) then
    index = index + 1
    return
  end

  -- wait for events to signal an opened mail
  stalled = (item or money > 0) and GetTime() + .5 or nil

  -- notify for openining a new mail when the count changed
  if not lastcount or mailcount < lastcount then
    DEFAULT_CHAT_FRAME:AddMessage("Opening |cff33ffcc" .. subject .. "|r")
  end

  -- actually open the mail and save the count
  lastcount = mailcount
  TakeInboxMoney(index)
  TakeInboxItem(index)
  GetInboxText(index)
  index = 1
end)

mail.OpenAll = function()
  running = "ALL"
  mail:Start()
end

mail.OpenAH = function()
  running = "AH"
  mail:Start()
end

mail.Start = function()
  DEFAULT_CHAT_FRAME:AddMessage("Processing |cff33ffcc" .. GetInboxNumItems() .. "|r Mails")
  money = GetMoney()
  index = 1
end

mail.Stop = function(self, reason)
  local diff = GetMoney() - money
  local prefix = diff < 0 and "|cffff3333-|r" or "|cff33ff33+|r"
  local money = diff ~= 0 and "Money difference " .. prefix .. BeautifyGoldString(abs(diff)) or ""
  DEFAULT_CHAT_FRAME:AddMessage("Mails " .. reason .. ". " .. money)
  running = nil
end

-- open all button
mail.button_all = CreateFrame("Button", "ShaguMailOpenAll", InboxFrame, "UIPanelButtonTemplate")
mail.button_all:SetPoint("BOTTOM", -50, 95)
mail.button_all:SetWidth(75)
mail.button_all:SetHeight(20)
mail.button_all:SetText("Open All")
mail.button_all:SetScript("OnClick", mail.OpenAll)
SkinButton(mail.button_all)

-- open all button
mail.button_ah = CreateFrame("Button", "ShaguMailOpenAH", InboxFrame, "UIPanelButtonTemplate")
mail.button_ah:SetPoint("BOTTOM", 30, 95)
mail.button_ah:SetWidth(75)
mail.button_ah:SetHeight(20)
mail.button_ah:SetText("Open AH")
mail.button_ah:SetScript("OnClick", mail.OpenAH)
SkinButton(mail.button_ah)
