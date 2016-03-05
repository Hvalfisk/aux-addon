local private, public = {}, {}
Aux.search_frame = public

aux_favorite_searches = {}
aux_recent_searches = {}

private.popup_info = {
    rename = {}
}

StaticPopupDialogs['AUX_SEARCH_SAVED_RENAME'] = {
    text = 'Enter a new name for this search.',
    button1 = 'Accept',
    button2 = 'Cancel',
    hasEditBox = 1,
    OnShow = function()
        local rename_info = private.popup_info.rename
        local edit_box = getglobal(this:GetName()..'EditBox')
        edit_box:SetText(rename_info.name or '')
        edit_box:HighlightText()
        edit_box:SetFocus()
        edit_box:SetScript('OnEscapePressed', function() StaticPopup_Hide('AUX_SEARCH_SAVED_RENAME') end)
        edit_box:SetScript('OnEnterPressed', function() getglobal(this:GetParent():GetName()..'Button1'):Click() end)
    end,
    OnAccept = function()
        private.popup_info.rename.name = getglobal(this:GetParent():GetName()..'EditBox'):GetText()
        private.update_search_listings()
    end,
    timeout = 0,
    hideOnEscape = 1,
}

local RESULTS, SAVED, FILTER = {}, {}, {}

private.elements = {
    [RESULTS] = {},
    [SAVED] = {},
    [FILTER] = {},
}

function private.update_search_listings()
    local favorite_search_rows = {}
    for i, favorite_search in ipairs(aux_favorite_searches) do
        local name = favorite_search.name or favorite_search.prettified
        tinsert(favorite_search_rows, {
            cols = {{value=name}},
            search = favorite_search,
            index = i,
            name = name,
        })
    end
    private.favorite_searches_listing:SetData(favorite_search_rows)

    local recent_search_rows = {}
    for i, recent_search in ipairs(aux_recent_searches) do
        local name = recent_search.name or recent_search.prettified
        tinsert(recent_search_rows, {
            cols = {{value=name}},
            search = recent_search,
            index = i,
            name = name,
        })
    end
    private.recent_searches_listing:SetData(recent_search_rows)
end

function private.update_tab(tab)

    private.search_results_button:UnlockHighlight()
    private.saved_searches_button:UnlockHighlight()
    private.new_filter_button:UnlockHighlight()
    AuxSearchFrameResults:Hide()
    AuxSearchFrameSaved:Hide()
    AuxSearchFrameFilter:Hide()

    if tab == RESULTS then
        AuxSearchFrameResults:Show()
        private.search_results_button:LockHighlight()
    elseif tab == SAVED then
        AuxSearchFrameSaved:Show()
        private.saved_searches_button:LockHighlight()
    elseif tab == FILTER then
        AuxSearchFrameFilter:Show()
        private.new_filter_button:LockHighlight()
    end
end

function public.set_filter(filter_string)
    private.search_box:SetText(filter_string)
end

function private.add_filter(filter_string, replace)
    filter_string = filter_string or private.get_form_filter()


    local old_filter_string
    if not replace then
        old_filter_string = private.search_box:GetText()
        old_filter_string = Aux.util.trim(old_filter_string)

        if strlen(old_filter_string) > 0 then
            old_filter_string = old_filter_string..';'
        end
    end

    private.search_box:SetText((old_filter_string or '')..filter_string)
end

function private.clear_filter()
    AuxSearchFrameFilterNameInputBox:SetText('')
    AuxSearchFrameFilterExactCheckButton:SetChecked(nil)
    AuxSearchFrameFilterMinLevel:SetText('')
    AuxSearchFrameFilterMaxLevel:SetText('')
    UIDropDownMenu_ClearAll(private.class_dropdown)
    UIDropDownMenu_ClearAll(private.subclass_dropdown)
    UIDropDownMenu_ClearAll(private.slot_dropdown)
    UIDropDownMenu_ClearAll(private.quality_dropdown)
    AuxSearchFrameFilterUsableCheckButton:SetChecked(nil)
    private.max_buyout_price:SetText('')
    private.max_percent:SetText('')
    private.tooltip1:SetText('')
    private.tooltip2:SetText('')
    private.tooltip3:SetText('')
    private.tooltip4:SetText('')
    private.tooltip5:SetText('')
    private.tooltip6:SetText('')
end

function private.get_form_filter()
    local filter_term = ''

    local function add(part)
        filter_term = filter_term == '' and part or filter_term..'/'..part
    end

    add(AuxSearchFrameFilterNameInputBox:GetText())

    if AuxSearchFrameFilterExactCheckButton:GetChecked() then
        add('exact')
    end

    if tonumber(AuxSearchFrameFilterMinLevel:GetText()) then
        add(tonumber(AuxSearchFrameFilterMinLevel:GetText()))
    end

    if tonumber(AuxSearchFrameFilterMaxLevel:GetText()) then
        add(tonumber(AuxSearchFrameFilterMaxLevel:GetText()))
    end

    if AuxSearchFrameFilterUsableCheckButton:GetChecked() then
        add('usable')
    end

    local class = UIDropDownMenu_GetSelectedValue(private.class_dropdown) ~= 0 and UIDropDownMenu_GetSelectedValue(private.class_dropdown)
    if class then
        local classes = { GetAuctionItemClasses() }
        add(strlower(classes[class]))
        local subclass = UIDropDownMenu_GetSelectedValue(private.subclass_dropdown) ~= 0 and UIDropDownMenu_GetSelectedValue(private.subclass_dropdown)
        if subclass then
            local subclasses = {GetAuctionItemSubClasses(class)}
            add(strlower(subclasses[subclass]))
            local slot = UIDropDownMenu_GetSelectedValue(private.slot_dropdown) ~= 0 and UIDropDownMenu_GetSelectedValue(private.slot_dropdown)
            if slot then
                add(strlower(getglobal(slot)))
            end
        end
    end

    local quality = UIDropDownMenu_GetSelectedValue(private.quality_dropdown) ~= 0 and UIDropDownMenu_GetSelectedValue(private.quality_dropdown)
    if quality then
        add(strlower(getglobal('ITEM_QUALITY'..quality..'_DESC')))
    end

    return filter_term
end

function public.on_open()
    private.update_search_listings()
end

function public.on_close()
end

function public.on_load()
    do
        local btn = Aux.gui.button(AuxSearchFrame, 22)
        btn:SetPoint('TOPRIGHT', -5, -8)
        btn:SetWidth(60)
        btn:SetHeight(25)
        btn:SetText('Search')
        btn:SetScript('OnClick', function()
            private.search_box:ClearFocus()
            public.start_search()
        end)
        private.search_button = btn
    end
    do
        local btn = Aux.gui.button(AuxSearchFrame, 22)
        btn:SetPoint('TOPRIGHT', -5, -8)
        btn:SetWidth(60)
        btn:SetHeight(25)
        btn:SetText('Stop')
        btn:SetScript('OnClick', Aux.search_frame.stop_search)
        btn:Hide()
        private.stop_button = btn
    end
    do
        local editbox = Aux.gui.editbox(AuxSearchFrame)
        editbox:SetMaxLetters(nil)
        editbox:EnableMouse(1)
        editbox.complete = Aux.completion.complete
        editbox:SetPoint('TOPLEFT', 5, -8)
        editbox:SetPoint('RIGHT', private.search_button, 'LEFT', -4, 0)
        editbox:SetWidth(400)
        editbox:SetHeight(25)
        editbox:SetScript('OnChar', function()
            this:complete()
        end)
        editbox:SetScript('OnTabPressed', function()
            this:HighlightText(0, 0)
        end)
        editbox:SetScript('OnEnterPressed', function()
            this:HighlightText(0, 0)
            this:ClearFocus()
            public.start_search()
        end)
        editbox:SetScript('OnEscapePressed', function()
            this:HighlightText(0, 0)
            this:ClearFocus()
        end)
        editbox:SetScript('OnEditFocusGained', function()
            this:HighlightText()
        end)
        editbox:SetScript('OnReceiveDrag', function()
            local item_info = Aux.cursor_item() and Aux.static.item_info(Aux.cursor_item().item_id)
            if item_info then
                public.start_search(strlower(item_info.name)..'/exact')
            end
            ClearCursor()
        end)
        private.search_box = editbox
    end
    do
        Aux.gui.horizontal_line(AuxSearchFrame, -40)
    end
    do
        local btn = Aux.gui.button(AuxSearchFrame, 18)
        btn:SetPoint('BOTTOMLEFT', AuxFrameContent, 'TOPLEFT', 10, 8)
        btn:SetWidth(243)
        btn:SetHeight(22)
        btn:SetText('Search Results')
        btn:SetScript('OnClick', function() private.update_tab(RESULTS) end)
        private.search_results_button = btn
    end
    do
        local btn = Aux.gui.button(AuxSearchFrame, 18)
        btn:SetPoint('TOPLEFT', private.search_results_button, 'TOPRIGHT', 5, 0)
        btn:SetWidth(243)
        btn:SetHeight(22)
        btn:SetText('Saved Searches')
        btn:SetScript('OnClick', function() private.update_tab(SAVED) end)
        private.saved_searches_button = btn
    end
    do
        local btn = Aux.gui.button(AuxSearchFrame, 18)
        btn:SetPoint('TOPLEFT', private.saved_searches_button, 'TOPRIGHT', 5, 0)
        btn:SetWidth(243)
        btn:SetHeight(22)
        btn:SetText('New Filter')
        btn:SetScript('OnClick', function() private.update_tab(FILTER) end)
        private.new_filter_button = btn
    end
    do
        local status_bar = Aux.gui.status_bar(AuxSearchFrame)
        status_bar:SetWidth(265)
        status_bar:SetHeight(25)
        status_bar:SetPoint('TOPLEFT', AuxFrameContent, 'BOTTOMLEFT', 0, -6)
        status_bar:update_status(100, 100)
        status_bar:set_text('')
        private.status_bar = status_bar
    end
    do
    local btn = Aux.gui.button(AuxSearchFrameResults, 16)
        btn:SetPoint('TOPLEFT', private.status_bar, 'TOPRIGHT', 5, 0)
        btn:SetWidth(80)
        btn:SetHeight(24)
        btn:SetText('Bid')
        btn:Disable()
        private.bid_button = btn
    end
    do
        local btn = Aux.gui.button(AuxSearchFrameResults, 16)
        btn:SetPoint('TOPLEFT', private.bid_button, 'TOPRIGHT', 5, 0)
        btn:SetWidth(80)
        btn:SetHeight(24)
        btn:SetText('Buyout')
        btn:Disable()
        private.buyout_button = btn
    end
    do
        local btn1 = Aux.gui.button(AuxSearchFrameFilter, 16)
        btn1:SetPoint('TOPLEFT', private.status_bar, 'TOPRIGHT', 5, 0)
        btn1:SetWidth(80)
        btn1:SetHeight(24)
        btn1:SetText('Search')
        btn1:SetScript('OnClick', function()
            private.search_box:SetText('')
            private.add_filter()
            public.start_search()
        end)

        local btn2 = Aux.gui.button(AuxSearchFrameFilter, 16)
        btn2:SetPoint('LEFT', btn1, 'RIGHT', 5, 0)
        btn2:SetWidth(80)
        btn2:SetHeight(24)
        btn2:SetText('Add')
        btn2:SetScript('OnClick', private.add_filter)

        local btn3 = Aux.gui.button(AuxSearchFrameFilter, 16)
        btn3:SetPoint('LEFT', btn2, 'RIGHT', 5, 0)
        btn3:SetWidth(80)
        btn3:SetHeight(24)
        btn3:SetText('Replace')
        btn3:SetScript('OnClick', function()
            private.add_filter(nil, true)
        end)
    end
    do
        local editbox = Aux.gui.editbox(AuxSearchFrameFilter, '$parentNameInputBox')
        editbox.complete_item = Aux.completion.complete_item
        editbox:SetPoint('TOPLEFT', 14, -20)
        editbox:SetWidth(300)
        editbox:SetScript('OnChar', function()
            if AuxSearchFrameFilterExactCheckButton:GetChecked() then
                this:complete_item()
            end
        end)
        editbox:SetScript('OnTabPressed', function()
            if IsShiftKeyDown() then
                getglobal(this:GetParent():GetName()..'MaxLevel'):SetFocus()
            else
                getglobal(this:GetParent():GetName()..'MinLevel'):SetFocus()
            end
        end)
        editbox:SetScript('OnEnterPressed', function()
            this:ClearFocus()
            public.start_search()
        end)
        editbox:SetScript('OnEscapePressed', function()
            this:ClearFocus()
        end)
        editbox:SetScript('OnEditFocusGained', function()
            this:HighlightText()
        end)
        local label = Aux.gui.label(editbox, 13)
        label:SetPoint('BOTTOMLEFT', editbox, 'TOPLEFT', -2, 1)
        label:SetText('Name')
    end
    do
        local editbox = Aux.gui.editbox(AuxSearchFrameFilter, '$parentMinLevel')
        editbox:SetPoint('TOPLEFT', AuxSearchFrameFilterNameInputBox, 'BOTTOMLEFT', 0, -22)
        editbox:SetWidth(145)
        editbox:SetNumeric(true)
        editbox:SetMaxLetters(2)
        editbox:SetScript('OnTabPressed', function()
            if IsShiftKeyDown() then
                getglobal(this:GetParent():GetName()..'NameInputBox'):SetFocus()
            else
                getglobal(this:GetParent():GetName()..'MaxLevel'):SetFocus()
            end
        end)
        editbox:SetScript('OnEnterPressed', function()
            this:ClearFocus()
            public.start_search()
        end)
        editbox:SetScript('OnEscapePressed', function()
            this:ClearFocus()
        end)
        editbox:SetScript('OnEditFocusGained', function()
            this:HighlightText()
        end)
        local label = Aux.gui.label(editbox, 13)
        label:SetPoint('BOTTOMLEFT', editbox, 'TOPLEFT', -2, 1)
        label:SetText('Level Range')
    end
    do
        local editbox = Aux.gui.editbox(AuxSearchFrameFilter, '$parentMaxLevel')
        editbox:SetPoint('TOPLEFT', AuxSearchFrameFilterMinLevel, 'TOPRIGHT', 10, 0)
        editbox:SetWidth(145)
        editbox:SetNumeric(true)
        editbox:SetMaxLetters(2)
        editbox:SetScript('OnTabPressed', function()
            if IsShiftKeyDown() then
                getglobal(this:GetParent():GetName()..'MinLevel'):SetFocus()
            else
                getglobal(this:GetParent():GetName()..'NameInputBox'):SetFocus()
            end
        end)
        editbox:SetScript('OnEnterPressed', function()
            this:ClearFocus()
            public.start_search()
        end)
        editbox:SetScript('OnEscapePressed', function()
            this:ClearFocus()
        end)
        editbox:SetScript('OnEditFocusGained', function()
            this:HighlightText()
        end)
        local label = Aux.gui.label(editbox, 13)
        label:SetPoint('RIGHT', editbox, 'LEFT', -4, 0)
        label:SetText('-')
    end
    do
        local dropdown = Aux.gui.dropdown(AuxSearchFrameFilter)
        dropdown:SetPoint('TOPLEFT', AuxSearchFrameFilterMinLevel, 'BOTTOMLEFT', 0, -22)
        dropdown:SetWidth(300)
        dropdown:SetHeight(10)
        local label = Aux.gui.label(dropdown, 13)
        label:SetPoint('BOTTOMLEFT', dropdown, 'TOPLEFT', -2, -4)
        label:SetText('Item Class')
        UIDropDownMenu_Initialize(dropdown, private.initialize_class_dropdown)
        dropdown:SetScript('OnShow', function()
            UIDropDownMenu_Initialize(this, private.initialize_class_dropdown)
        end)
        private.class_dropdown = dropdown
    end
    do
        local dropdown = Aux.gui.dropdown(AuxSearchFrameFilter)
        dropdown:SetPoint('TOPLEFT', private.class_dropdown, 'BOTTOMLEFT', 0, -22)
        dropdown:SetWidth(300)
        dropdown:SetHeight(10)
        local label = Aux.gui.label(dropdown, 13)
        label:SetPoint('BOTTOMLEFT', dropdown, 'TOPLEFT', -2, -4)
        label:SetText('Item Subclass')
        UIDropDownMenu_Initialize(dropdown, private.initialize_subclass_dropdown)
        dropdown:SetScript('OnShow', function()
            UIDropDownMenu_Initialize(this, private.initialize_subclass_dropdown)
        end)
        private.subclass_dropdown = dropdown
    end
    do
        local dropdown = Aux.gui.dropdown(AuxSearchFrameFilter)
        dropdown:SetPoint('TOPLEFT', private.subclass_dropdown, 'BOTTOMLEFT', 0, -22)
        dropdown:SetWidth(300)
        dropdown:SetHeight(10)
        local label = Aux.gui.label(dropdown, 13)
        label:SetPoint('BOTTOMLEFT', dropdown, 'TOPLEFT', -2, -4)
        label:SetText('Item Slot')
        UIDropDownMenu_Initialize(dropdown, private.initialize_slot_dropdown)
        dropdown:SetScript('OnShow', function()
            UIDropDownMenu_Initialize(this, private.initialize_slot_dropdown)
        end)
        private.slot_dropdown = dropdown
    end
    do
        local dropdown = Aux.gui.dropdown(AuxSearchFrameFilter)
        dropdown:SetPoint('TOPLEFT', private.slot_dropdown, 'BOTTOMLEFT', 0, -22)
        dropdown:SetWidth(300)
        dropdown:SetHeight(10)
        local label = Aux.gui.label(dropdown, 13)
        label:SetPoint('BOTTOMLEFT', dropdown, 'TOPLEFT', -2, -4)
        label:SetText('Min Rarity')
        UIDropDownMenu_Initialize(dropdown, private.initialize_quality_dropdown)
        dropdown:SetScript('OnShow', function()
            UIDropDownMenu_Initialize(this, private.initialize_quality_dropdown)
        end)
        private.quality_dropdown = dropdown
    end
    Aux.gui.vertical_line(AuxSearchFrameFilter, 332)
    do
        local label = Aux.gui.label(AuxSearchFrameFilterExactCheckButton, 13)
        label:SetPoint('BOTTOMLEFT', AuxSearchFrameFilterExactCheckButton, 'TOPLEFT', 1, -3)
        label:SetText('Exact')
    end
    do
        local label = Aux.gui.label(AuxSearchFrameFilterUsableCheckButton, 13)
        label:SetPoint('BOTTOMLEFT', AuxSearchFrameFilterUsableCheckButton, 'TOPLEFT', 1, -3)
        label:SetText('Usable')
    end
    Aux.gui.vertical_line(AuxSearchFrameFilter, 425)
    local function add_modifier(...)
        local current_filter_string = private.search_box:GetText()
        for i=1,arg.n do
            if current_filter_string ~= '' and string.sub(current_filter_string, strlen(current_filter_string), strlen(current_filter_string)) ~= '/' then
                current_filter_string = current_filter_string..'/'
            end
            current_filter_string = current_filter_string..arg[i]
        end
        private.search_box:SetText(current_filter_string)
    end
    private.modifier_buttons = {}
    do
        local btn = Aux.gui.button(AuxSearchFrameFilter, 16)
        btn:SetPoint('TOPRIGHT', -250, -10)
        btn:SetWidth(50)
        btn:SetHeight(24)
        btn:SetText('and')
        btn:SetScript('OnClick', function()
            add_modifier('and')
        end)
        private.modifier_buttons['and'] = btn
    end
    do
        local btn = Aux.gui.button(AuxSearchFrameFilter, 16)
        btn:SetPoint('LEFT', private.modifier_buttons['and'], 'RIGHT', 10, 0)
        btn:SetWidth(50)
        btn:SetHeight(24)
        btn:SetText('or')
        btn:SetScript('OnClick', function()
            add_modifier('or')
        end)
        private.modifier_buttons['or'] = btn
    end
    do
        local btn = Aux.gui.button(AuxSearchFrameFilter, 16)
        btn:SetPoint('LEFT', private.modifier_buttons['or'], 'RIGHT', 10, 0)
        btn:SetWidth(50)
        btn:SetHeight(24)
        btn:SetText('not')
        btn:SetScript('OnClick', function()
            add_modifier('not')
        end)
        private.modifier_buttons['not'] = btn
    end
    do
        local btn = Aux.gui.button(AuxSearchFrameFilter, 16)
        btn:SetPoint('TOPLEFT', private.modifier_buttons['and'], 'BOTTOMLEFT', 100, -25)
        btn:SetWidth(80)
        btn:SetHeight(24)
        btn:SetText('item')
        btn:SetScript('OnClick', function()
            add_modifier('item')
        end)
        private.modifier_buttons['item'] = btn
    end
    do
        local btn = Aux.gui.button(AuxSearchFrameFilter, 16)
        btn:SetPoint('TOPLEFT', private.modifier_buttons['item'], 'BOTTOMLEFT', 0, -10)
        btn:SetWidth(80)
        btn:SetHeight(24)
        btn:SetText('tt')
        btn:SetScript('OnClick', function()
            add_modifier('tt')
        end)
        private.modifier_buttons['tt'] = btn
    end
    do
        local btn = Aux.gui.button(AuxSearchFrameFilter, 16)
        btn:SetPoint('TOPLEFT', private.modifier_buttons['tt'], 'BOTTOMLEFT', 0, -10)
        btn:SetWidth(80)
        btn:SetHeight(24)
        btn:SetText('min-lvl')
        btn:SetScript('OnClick', function()
            add_modifier('min-lvl')
        end)
        private.modifier_buttons['min-lvl'] = btn
    end
    do
        local btn = Aux.gui.button(AuxSearchFrameFilter, 16)
        btn:SetPoint('TOPLEFT', private.modifier_buttons['min-lvl'], 'BOTTOMLEFT', 0, -10)
        btn:SetWidth(80)
        btn:SetHeight(24)
        btn:SetText('max-lvl')
        btn:SetScript('OnClick', function()
            add_modifier('max-lvl')
        end)
        private.modifier_buttons['max-lvl'] = btn
    end
    do
        local btn = Aux.gui.button(AuxSearchFrameFilter, 16)
        btn:SetPoint('TOPLEFT', private.modifier_buttons['max-lvl'], 'BOTTOMLEFT', 0, -10)
        btn:SetWidth(80)
        btn:SetHeight(24)
        btn:SetText('rarity')
        btn:SetScript('OnClick', function()
            add_modifier('rarity')
        end)
        private.modifier_buttons['rarity'] = btn
    end
    do
        local btn = Aux.gui.button(AuxSearchFrameFilter, 16)
        btn:SetPoint('TOPLEFT', private.modifier_buttons['rarity'], 'BOTTOMLEFT', 0, -10)
        btn:SetWidth(80)
        btn:SetHeight(24)
        btn:SetText('left')
        btn:SetScript('OnClick', function()
            add_modifier('left')
        end)
        private.modifier_buttons['left'] = btn
    end
    do
        local btn = Aux.gui.button(AuxSearchFrameFilter, 16)
        btn:SetPoint('TOPLEFT', private.modifier_buttons['left'], 'BOTTOMLEFT', 0, -10)
        btn:SetWidth(80)
        btn:SetHeight(24)
        btn:SetText('utilizable')
        btn:SetScript('OnClick', function()
            add_modifier('utilizable')
        end)
        private.modifier_buttons['utilizable'] = btn
    end
    do
        local btn = Aux.gui.button(AuxSearchFrameFilter, 16)
        btn:SetPoint('TOPLEFT', private.modifier_buttons['utilizable'], 'BOTTOMLEFT', 0, -10)
        btn:SetWidth(80)
        btn:SetHeight(24)
        btn:SetText('discard')
        btn:SetScript('OnClick', function()
            add_modifier('discard')
        end)
        private.modifier_buttons['discard'] = btn
    end
    do
        local btn = Aux.gui.button(AuxSearchFrameFilter, 16)
        btn:SetPoint('TOPLEFT', private.modifier_buttons['and'], 'BOTTOMLEFT', 0, -25)
        btn:SetWidth(80)
        btn:SetHeight(24)
        btn:SetText('min-bid')
        btn:SetScript('OnClick', function()
            add_modifier('min-bid')
        end)
        private.modifier_buttons['min-bid'] = btn
    end
    do
        local btn = Aux.gui.button(AuxSearchFrameFilter, 16)
        btn:SetPoint('TOPLEFT', private.modifier_buttons['min-bid'], 'BOTTOMLEFT', 0, -10)
        btn:SetWidth(80)
        btn:SetHeight(24)
        btn:SetText('max-bid')
        btn:SetScript('OnClick', function()
            add_modifier('max-bid')
        end)
        private.modifier_buttons['max-bid'] = btn
    end
    do
        local btn = Aux.gui.button(AuxSearchFrameFilter, 16)
        btn:SetPoint('TOPLEFT', private.modifier_buttons['max-bid'], 'BOTTOMLEFT', 0, -10)
        btn:SetWidth(80)
        btn:SetHeight(24)
        btn:SetText('bid-profit')
        btn:SetScript('OnClick', function()
            add_modifier('bid-profit')
        end)
        private.modifier_buttons['bid-profit'] = btn
    end
    do
        local btn = Aux.gui.button(AuxSearchFrameFilter, 16)
        btn:SetPoint('TOPLEFT', private.modifier_buttons['bid-profit'], 'BOTTOMLEFT', 0, -10)
        btn:SetWidth(80)
        btn:SetHeight(24)
        btn:SetText('bid-pct')
        btn:SetScript('OnClick', function()
            add_modifier('bid-pct')
        end)
        private.modifier_buttons['bid-pct'] = btn
    end
    do
        local btn = Aux.gui.button(AuxSearchFrameFilter, 16)
        btn:SetPoint('TOPLEFT', private.modifier_buttons['bid-pct'], 'BOTTOMLEFT', 0, -10)
        btn:SetWidth(80)
        btn:SetHeight(24)
        btn:SetText('min-buyout')
        btn:SetScript('OnClick', function()
            add_modifier('min-buyout')
        end)
        private.modifier_buttons['min-buyout'] = btn
    end
    do
        local btn = Aux.gui.button(AuxSearchFrameFilter, 16)
        btn:SetPoint('TOPLEFT', private.modifier_buttons['min-buyout'], 'BOTTOMLEFT', 0, -10)
        btn:SetWidth(80)
        btn:SetHeight(24)
        btn:SetText('max-buyout')
        btn:SetScript('OnClick', function()
            add_modifier('max-buyout')
        end)
        private.modifier_buttons['max-buyout'] = btn
    end
    do
        local btn = Aux.gui.button(AuxSearchFrameFilter, 16)
        btn:SetPoint('TOPLEFT', private.modifier_buttons['max-buyout'], 'BOTTOMLEFT', 0, -10)
        btn:SetWidth(80)
        btn:SetHeight(24)
        btn:SetText('buyout-profit')
        btn:SetScript('OnClick', function()
            add_modifier('buyout-profit')
        end)
        private.modifier_buttons['buyout-profit'] = btn
    end
    do
        local btn = Aux.gui.button(AuxSearchFrameFilter, 16)
        btn:SetPoint('TOPLEFT', private.modifier_buttons['buyout-profit'], 'BOTTOMLEFT', 0, -10)
        btn:SetWidth(80)
        btn:SetHeight(24)
        btn:SetText('buyout-pct')
        btn:SetScript('OnClick', function()
            add_modifier('buyout-pct')
        end)
        private.modifier_buttons['buyout-pct'] = btn
    end

    private.results_listing = Aux.auction_listing.CreateAuctionResultsTable(AuxSearchFrameResults)
    private.results_listing:Show()
    private.results_listing:SetSort(9)
    private.results_listing:Clear()
    private.results_listing:SetHandler('OnCellAltClick', function(cell, button)
        private.results_listing:SetSelectedRecord(nil)
        private.find_auction_and_bid(cell.row.data.record, button == 'LeftButton')
    end)
    private.results_listing:SetHandler('OnSelectionChanged', function(rt, datum)
        if not datum then return end
        private.find_auction(datum.record)
    end)

    local handlers = {
        OnClick = function(st, data, _, button)
            if not data then return end
            if button == 'LeftButton' and IsShiftKeyDown() then
                private.search_box:SetText(data.search.filter_string)
            elseif button == 'RightButton' and IsShiftKeyDown() then
                private.add_filter(data.search.filter_string)
            elseif button == 'LeftButton' and IsAltKeyDown() then
                private.popup_info.rename = data.search
                StaticPopup_Show('AUX_SEARCH_SAVED_RENAME')
            elseif button == 'LeftButton' then
                private.search_box:SetText(data.search.filter_string)
                public.start_search()
            elseif button == 'RightButton' then
                if st == private.recent_searches_listing then
                    tinsert(aux_favorite_searches, data.search)
                elseif st == private.favorite_searches_listing then
                    tremove(aux_favorite_searches, data.index)
                end
                private.update_search_listings()
            end
        end,
        OnEnter = function(st, data, self)
            if not data then return end
                        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
                        GameTooltip:AddLine(gsub(data.search.prettified, ';', '\n'), 255/255, 254/255, 250/255)
                        GameTooltip:Show()
--            GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
--            GameTooltip:AddLine(data.search, 1, 1, 1, true)
--            GameTooltip:AddLine("")
--            local color = TSMAPI.Design:GetInlineColor("link")
--            if st == private.frame.saved.recentST then
--                GameTooltip:AddLine(color..'Left-Click to run this search.', 1, 1, 1, true)
--                GameTooltip:AddLine(color..'Shift-Left-Click to export this search.', 1, 1, 1, true)
--                GameTooltip:AddLine(color..'Ctrl-Left-Click to rename this search.', 1, 1, 1, true)
--                GameTooltip:AddLine(color..'Right-Click to favorite this recent search.', 1, 1, 1, true)
--                GameTooltip:AddLine(color..'Shift-Right-Click to remove this recent search.', 1, 1, 1, true)
--            elseif st == private.frame.saved.favoriteST then
--                GameTooltip:AddLine(color..'Left-Click to run this search.', 1, 1, 1, true)
--                GameTooltip:AddLine(color..'Shift-Left-Click to export this search.', 1, 1, 1, true)
--                GameTooltip:AddLine(color..'Ctrl-Left-Click to rename this search.', 1, 1, 1, true)
--                GameTooltip:AddLine(color..'Right-Click to remove from favorite searches.', 1, 1, 1, true)
--            end
            GameTooltip:Show()
        end,
        OnLeave = function()
            GameTooltip:ClearLines()
            GameTooltip:Hide()
        end
    }

    private.recent_searches_listing = Aux.listing.CreateScrollingTable(AuxSearchFrameSavedRecent)
    private.recent_searches_listing:DisableSelection(true)
    private.recent_searches_listing:SetColInfo({{name='Recent Searches', width=1}})
    private.recent_searches_listing:SetHandler('OnClick', handlers.OnClick)
    private.recent_searches_listing:SetHandler('OnEnter', handlers.OnEnter)
    private.recent_searches_listing:SetHandler('OnLeave', handlers.OnLeave)

    Aux.gui.vertical_line(AuxSearchFrameSaved, 379)

    private.favorite_searches_listing = Aux.listing.CreateScrollingTable(AuxSearchFrameSavedFavorite)
    private.favorite_searches_listing:DisableSelection(true)
    private.favorite_searches_listing:SetColInfo({{name='Favorite Searches', width=1}})
    private.favorite_searches_listing:SetHandler('OnClick', handlers.OnClick)
    private.favorite_searches_listing:SetHandler('OnEnter', handlers.OnEnter)
    private.favorite_searches_listing:SetHandler('OnLeave', handlers.OnLeave)


    private.update_tab(SAVED)
end

function public.stop_search()
	Aux.scan.abort('list')
end

function public.start_search(filter_string)

    Aux.scan.abort('list')

    if filter_string then
        private.search_box:SetText(filter_string)
    end

    local queries

    local filters = Aux.scan_util.parse_filter_string(private.search_box:GetText())
    if not filters then
        return
    end

    local queries = Aux.util.map(filters, function(filter)
        return {
            start_page = 0,
            blizzard_query = filter.blizzard_query,
            validator = filter.validator,
        }
    end)

    tinsert(aux_recent_searches, 1, {
        filter_string = private.search_box:GetText(),
        prettified = Aux.util.join(Aux.util.map(filters, function(filter) return filter.prettified end), ';'),
    })
    while getn(aux_recent_searches) > 50 do
        tremove(aux_recent_searches)
    end
    private.update_search_listings()

    private.search_button:Hide()
    private.stop_button:Show()

    private.update_tab(RESULTS)

    private.status_bar:update_status(0,0)
    private.status_bar:set_text('Scanning auctions...')

    private.results_listing:Clear()
    local scanned_records = {}
    private.results_listing:SetDatabase(scanned_records)

    local current_query
    Aux.scan.start{
        type = 'list',
        queries = queries,
        on_page_loaded = function(page, total_pages)
            local current_page = page + 1
            local current_total_pages = total_pages
            private.status_bar:update_status(100 * (current_query - 1) / getn(queries), 100 * (current_page - 1) / current_total_pages) -- TODO
            private.status_bar:set_text(format('Scanning %d / %d (Page %d / %d)', current_query, getn(queries), current_page, current_total_pages))
        end,
        on_page_scanned = function()
            private.results_listing:SetDatabase()
        end,
        on_start_query = function(query_index)
            current_query = query_index
            private.status_bar:update_status(100 * (current_query - 1) / getn(queries), 0) -- TODO
            private.status_bar:set_text(format('Scanning %d / %d', current_query, getn(queries)))
        end,
        on_read_auction = function(auction_info, ctrl)
--            if getn(scanned_records) == 0 then
--                SetCVar('MasterSoundEffects', 0)
--                SetCVar('MasterSoundEffects', 1)
--                PlaySoundFile([[Interface\AddOns\Aux-AddOn\Event_wardrum_ogre.ogg]], 'Master')
--                PlaySoundFile([[Interface\AddOns\Aux-AddOn\scourge_horn.ogg]], 'Master')
--                tinsert(scanned_records, auction_info)
--                private.results_listing:SetDatabase()
--                ctrl.suspend()
--                Aux.scan.abort('list')
--            end
            if getn(scanned_records) < 1000 then -- TODO static popup, remove discard
                tinsert(scanned_records, auction_info)
            end
        end,
        on_complete = function()
            private.results_listing:SetDatabase()
            private.status_bar:update_status(100, 100)
            private.status_bar:set_text('Done Scanning')

            private.stop_button:Hide()
            private.search_button:Show()

            if getn(scanned_records) == 0 then
                private.update_tab(SAVED)
            end
--            public.start_search(filter_string)
        end,
        on_abort = function()
            private.results_listing:SetDatabase()
            private.status_bar:update_status(100, 100)
            private.status_bar:set_text('Done Scanning')
            private.stop_button:Hide()
            private.search_button:Show()
        end,
    }
end

function private.test(record)
    return function(index)
        local auction_info = Aux.info.auction(index)
        return auction_info and auction_info.search_signature == record.search_signature
    end
end

function private.record_remover(record)
    return function()
        private.results_listing:RemoveAuctionRecord(record)
    end
end

function private.find_auction_and_bid(record, buyout_mode)
    if not private.results_listing:ContainsRecord(record) or (buyout_mode and not record.buyout_price) or (not buyout_mode and record.high_bidder) or Aux.is_player(record.owner) then
        return
    end

    Aux.scan_util.find(record, private.status_bar, Aux.util.pass, private.record_remover(record), function(index)
        if private.results_listing:ContainsRecord(record) then
            Aux.place_bid('list', index, buyout_mode and record.buyout_price or record.bid_price, private.record_remover(record))
        end
    end)
end

do
    local IDLE, SEARCHING, FOUND = {}, {}, {}
    local state = IDLE
    local found_index

    function private.find_auction(record)
        if not private.results_listing:ContainsRecord(record) or Aux.is_player(record.owner) then
            return
        end

        state = SEARCHING
        Aux.scan_util.find(
            record,
            private.status_bar,
            function()
                state = IDLE
            end,
            function()
                state = IDLE
                private.record_remover(record)()
            end,
            function(index)
                state = FOUND
                found_index = index

                if not record.high_bidder then
                    private.bid_button:SetScript('OnClick', function()
                        if private.test(record)(index) and private.results_listing:ContainsRecord(record) then
                            Aux.place_bid('list', index, record.bid_price, private.record_remover(record))
                        end
                    end)
                    private.bid_button:Enable()
                end

                if record.buyout_price > 0 then
                    private.buyout_button:SetScript('OnClick', function()
                        if private.test(record)(index) and private.results_listing:ContainsRecord(record) then
                            Aux.place_bid('list', index, record.buyout_price, private.record_remover(record))
                        end
                    end)
                    private.buyout_button:Enable()
                end
            end
        )
    end

    function public.on_update()
        if not AuxSearchFrame:IsVisible() then
            return
        end

        if state == IDLE or state == SEARCHING then
            private.buyout_button:Disable()
            private.bid_button:Disable()
        end

        if state == SEARCHING then
            return
        end

        local selection = private.results_listing:GetSelection()
        if not selection then
           state = IDLE
        elseif selection and state == IDLE then
            private.find_auction(selection.record)
        elseif state == FOUND and not private.test(selection.record)(found_index) then
            private.buyout_button:Disable()
            private.bid_button:Disable()
            if not Aux.bid_in_progress() then
                state = IDLE
            end
        end
    end
end


--    if auction_info.current_bid == 0 then
--        status = 'No Bid'
--    elseif auction_info.high_bidder then
--        status = GREEN_FONT_COLOR_CODE..'Your Bid'..FONT_COLOR_CODE_CLOSE
--    else
--        status = 'Other Bidder'
--    end


function private.initialize_class_dropdown()
    local function on_click()
        if this.value ~= UIDropDownMenu_GetSelectedValue(private.class_dropdown) then
            UIDropDownMenu_ClearAll(private.subclass_dropdown)
            UIDropDownMenu_ClearAll(private.slot_dropdown)
        end
        UIDropDownMenu_SetSelectedValue(private.class_dropdown, this.value)
    end

    UIDropDownMenu_AddButton{
        text = ALL,
        value = 0,
        func = on_click,
    }

    for i, class in pairs({ GetAuctionItemClasses() }) do
        UIDropDownMenu_AddButton{
            text = class,
            value = i,
            func = on_click,
        }
    end
end

function private.initialize_subclass_dropdown()

    local function on_click()
        if this.value ~= UIDropDownMenu_GetSelectedValue(private.subclass_dropdown) then
            UIDropDownMenu_ClearAll(private.slot_dropdown)
        end
        UIDropDownMenu_SetSelectedValue(private.subclass_dropdown, this.value)
    end

    local class_index = UIDropDownMenu_GetSelectedValue(private.class_dropdown)

    if class_index and GetAuctionItemSubClasses(class_index) then
        UIDropDownMenu_AddButton{
            text = ALL,
            value = 0,
            func = on_click,
        }

        for i, subclass in pairs({ GetAuctionItemSubClasses(class_index) }) do
            UIDropDownMenu_AddButton{
                text = subclass,
                value = i,
                func = on_click,
            }
        end
    end
end

function private.initialize_slot_dropdown()

    local function on_click()
        UIDropDownMenu_SetSelectedValue(private.slot_dropdown, this.value)
    end

    local class_index = UIDropDownMenu_GetSelectedValue(private.class_dropdown)
    local subclass_index = UIDropDownMenu_GetSelectedValue(private.subclass_dropdown)

    if class_index and subclass_index and GetAuctionInvTypes(class_index, subclass_index) then
        UIDropDownMenu_AddButton{
            text = ALL,
            value = 0,
            func = on_click,
        }

        for i, slot in pairs({ GetAuctionInvTypes(class_index, subclass_index) }) do
            local slot_name = getglobal(slot)
            UIDropDownMenu_AddButton{
                text = slot_name,
                value = slot,
                func = on_click,
            }
        end
    end
end

function private.initialize_quality_dropdown()

    local function on_click()
        UIDropDownMenu_SetSelectedValue(private.quality_dropdown, this.value)
    end

	UIDropDownMenu_AddButton{
		text = ALL,
        value = 0,
		func = on_click,
	}
	for i=0,4 do
		UIDropDownMenu_AddButton{
			text = getglobal('ITEM_QUALITY'..i..'_DESC'),
			value = i,
			func = on_click,
		}
	end
end

