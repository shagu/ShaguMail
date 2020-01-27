-- pfUI Compatibility
local SkinButton = pfUI and pfUI.api.SkinButton or function() return end

-- ShaguMail
local index, running
local mail = CreateFrame("Frame", "ShaguMail", MailFrame)
mail:RegisterEvent("UI_ERROR_MESSAGE")
mail:RegisterEvent("MAIL_INBOX_UPDATE")
mail:SetScript("OnEvent", function()
  if event == "UI_ERROR_MESSAGE" then
    if arg1 == ERR_INV_FULL then
      running = nil -- abort
    elseif arg1 == ERR_ITEM_MAX_COUNT then
      index = index + 1
    end
  elseif event == "MAIL_INBOX_UPDATE" then
    index = 1
  end
end)

mail:SetScript("OnUpdate", function()
  if ( this.tick or 0) < GetTime() then CheckInbox() this.tick = GetTime() + 1 end

  if not running then return end
  if index > GetInboxNumItems() then
    running = nil -- done
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

-- open all button
mail.button = CreateFrame("Button", "ShaguMailOpenAll", InboxFrame, "UIPanelButtonTemplate")
mail.button:SetPoint("BOTTOM", -10, 95)
mail.button:SetWidth(100)
mail.button:SetHeight(20)
mail.button:SetText(T["Open All"])
mail.button:SetScript("OnClick", function()
  running, index = true, 1
end)
SkinButton(mail.button) 
