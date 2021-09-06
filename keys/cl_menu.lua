-- Design taken from the glorious bSecure
-- https://github.com/BullyHunter32/bSecure/blob/master/lua/bsecure/modules/vgui/cl_bsecure_frame.lua
local PLUGIN = PLUGIN


--[[
Sorry about the super shit code
Was very tired while typing this up so I tried to do it quickly
]]

surface.CreateFont("bSecure.Title",{
    font = "Roboto",
    size = 22
})

surface.CreateFont("bSecure.Small",{
    font = "Roboto",
    size = 18
})


local PANEL = {}

local mat_close = Material("bsecure/cross.png")
local color_header = Color(60, 60, 63)
function PANEL:Init()
    self.Header = self:Add("DPanel")
    self.Header:Dock(TOP)
    self.Header:SetTall(30)
    self.Header.Paint = function(pnl, w, h)
        draw.RoundedBoxEx(4, 0, 0, w, h, color_header, true, true)
    end
    self.Header.Title = self.Header:Add("DLabel")
    self.Header.Title:Dock(LEFT)
    self.Header.Title:SetText("Doors System")
    self.Header.Title:SetFont("bSecure.Title")
    self.Header.Title:SetTextColor(color_white)
    self.Header.Title:DockMargin(10, 0, 0, 0)
    self.Header.Title:SizeToContents()

    self.Header.Close = self.Header:Add("DButton")
    self.Header.Close:Dock(RIGHT)
    self.Header.Close:SetWide(30)
    self.Header.Close:SetText("")
    self.Header.Close.DoClick = function() self:Remove() end
    self.Header.Close.Paint = function(pnl, w, h)
        surface.SetMaterial(mat_close)
        surface.SetDrawColor(180,180,180)
        surface.DrawTexturedRect(4, 4, w-8, h-8)
    end

end

local bg = Color(47, 47, 52)
function PANEL:Paint(w, h)
    draw.RoundedBox(4, 0, 0, w, h, bg, true, true)
end
    
vgui.Register("ixDoorsMenu.Frame", PANEL, "EditablePanel")

local PANEL = {}
AccessorFunc(PANEL, "m_accent", "Accent")

local color_accent = Color(70, 130, 170)
local color_text_i = Color(160,160,160)
local color_bg = Color(43, 43, 46)
function PANEL:Init()
    self:SetAccent(color_accent)
    self.Pages = {}
end

function PANEL:AddPage(strName, pPanel)
    self.Pages[strName] = self:Add("DButton")
    local btn = self.Pages[strName]
    btn:Dock(TOP)
    btn:SetText("")
    btn:SetTall(40) 
    btn:DockMargin(1,0,1,0)
    btn.Paint = function(pnl, w, h)
        if pnl.isActive then
            surface.SetDrawColor(self:GetAccent())
            surface.DrawRect(0, 0, w, h)
        end
        draw.SimpleText(strName, "bSecure.Title", 10, h/2, pnl.isActive and color_white or color_text_i, 0, 1)
    end
    btn.DoClick = function(pnl)
        self:SetActive(strName)
    end
    
    btn.Panel = self.Body:Add(pPanel or "Panel")
    btn.Panel:Dock(FILL)
    btn.Panel:SetVisible(false)

    return btn.Panel
end

function PANEL:Paint(w, h)
    draw.RoundedBoxEx(4, 0, 0, w, h, color_bg, false, false, true, false)
end

function PANEL:SetActive(strName)
    if IsValid(self.Pages.Active) then
        self.Pages.Active.isActive = false
        self.Pages.Active.Panel:SetVisible(false)
    end
    self.Pages.Active = self.Pages[strName]
    self.Pages[strName].isActive = true
    self.Pages[strName].Panel:SetVisible(true)
end 

function PANEL:SetBody(pBody)
    self.Body = pBody:Add("EditablePanel")
    self.Body:Dock(FILL)
    return self.Body
end

vgui.Register("ixDoorsMenu.NavBar", PANEL)

local PANEL = {} 

function PANEL:Init()
    self:SetFont("bSecure.Title")
end

local color_bg = Color(54, 54, 59)
local color_text = Color(200, 200, 200)
local color_highlight = Color(130, 130, 130)
local color_cursor = Color(160, 160, 160)

function PANEL:Paint(w, h)
    draw.RoundedBoxEx(4, 0, 0, w, h, color_bg, true, true, true, true)
    if not self:GetValue() or #self:GetValue() == 0 and self:GetPlaceholderText() and not self:IsEditing() then
        draw.SimpleText(self:GetPlaceholderText(), "bSecure.Title", 5, h/2, color_highlight, 0, 1)
        return
    end 
    self:DrawTextEntryText(color_text, color_highlight, color_cursor)
end
vgui.Register("ixDoorsMenu.Searchbar", PANEL, "DTextEntry")

local PANEL = {}
local color_bg = Color(65, 65, 69)
local color_toggle = Color(70,130,170)
AccessorFunc(PANEL, "b_ToggleState", "State", FORCE_BOOL)
function PANEL:Init()
    self:SetText("")
    self:NoClipping(true)
    self:SetState(false)
    self.anim = false
    self.ratio = 0
    self.start = 0
end

function PANEL:Toggle()
    local newValue = not self:GetState()
    self:SetState(newValue)
    self:OnToggled(newValue)
    self.anim = true
    self.start = CurTime()
end

function PANEL:Think()
    local iEnd = 1-(self:GetTall()/self:GetWide())
    if self:GetState() and self.ratio ~= iEnd then -- Just so it's not calling functions that essentially do nothiing 
        self.ratio = Lerp((CurTime()-self.start)/0.4, (self.ratio or 0), iEnd)
    elseif not self:GetState() and self.ratio ~= 0 then 
        self.ratio = Lerp((CurTime()-self.start)/0.4, (self.ratio or 0), 0)
    end
end

function PANEL:DoClick()
    self:Toggle()
end

function PANEL:Paint(w, h)
    draw.RoundedBox(h/3, 0, h*0.25, w, h/2, color_bg)
    local bounds = w*0.1
    local size = h
    draw.RoundedBox(size,self.ratio * w, 0, size, size, color_toggle)
end

function PANEL:OnToggled(bState) end

vgui.Register("ixDoorsMenu.Toggle", PANEL, "DButton")

local PANEL = {}
local color_grip = Color(70, 72, 74)
function PANEL:Init()
    self:DockPadding(8, 8, 8, 8)
    self.Title = self:Add("ixDoorsMenu.Searchbar")
    self.Title:Dock(TOP)
    self.Title:SetTall(38)
    self.Title:SetPlaceholderText("Enter the name of this Property")

    self.Body = self:Add("Panel")
    self.Body:Dock(FILL)

    self.Footer = self.Body:Add("Panel")
    self.Footer:Dock(BOTTOM)
    self.Footer:SetTall(28)

    self.DoorList = self.Body:Add("Panel")
    self.DoorList:Dock(RIGHT)
    self.DoorList:DockMargin(4, 4, 0, 4)

    self.DoorList.Header = self.DoorList:Add("Panel")
    self.DoorList.Header:Dock(TOP)
    self.DoorList.Header:SetTall(30)
    self.DoorList.Header.Paint = function(pnl, w, h)
        draw.SimpleText("Selected Doors", "bSecure.Small", w/2, h/2, color_white, 1, 1)
    end

    self.DoorList.Scroll = self.DoorList:Add("DScrollPanel")
    self.DoorList.Scroll:Dock(FILL)
    self.DoorList.Scroll.vBar = self.DoorList.Scroll:GetVBar()
    self.DoorList.Scroll.vBar:SetWide(8)
    self.DoorList.Scroll.vBar:SetHideButtons(true)
    self.DoorList.Scroll.vBar.btnGrip.Paint = function(pnl, w, h)
        draw.RoundedBoxEx(w/3, 0, 0, w, h, color_grip, true, true, true, true)
    end
    self.DoorList.Scroll.vBar.Paint = nil
    self.DoorList.Scroll.Paint = function(pnl, w, h)
        surface.SetDrawColor(60, 60, 63)
        surface.DrawOutlinedRect(0, 0, w, h)
    end

    self._options = {}
    self.Options = self.Body:Add("Panel")
    self.Options:Dock(FILL)
    self.Options:DockMargin(0, 12, 0, 0)

    self.CreateProperty = self.Footer:Add("DButton")
    self.CreateProperty:SetFont("bSecure.Title")
    self.CreateProperty:SetText("Create")
    self.CreateProperty:SizeToContentsX(32)
    self.CreateProperty:SizeToContentsY(8)
    self.CreateProperty:SetText("")
    self.CreateProperty.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, color_bg)
        draw.SimpleText("Create", "bSecure.Title", w/2, h/2, pnl:IsHovered() and color_white or color_text_i, 1, 1)
    end
    self.CreateProperty.DoClick = function(pnl)
        PLUGIN:RegisterProperty(self.Title:GetText(), self._options["lock_default"], self._options["start_open"])
    end
    
    self.Body.PerformLayout = function(pnl, w, h)
        local btnw, btnh = h*0.25, 28
        self.CreateProperty:SetSize(btnw, btnh)
        self.CreateProperty:SetPos(w/2 - btnw/2, 0)

        self.DoorList:SetWide(w*0.45)
    end

    local tool = LocalPlayer():GetTool("keys")
    if tool and tool.SelectedDoors then
        for k,v in ipairs(tool.SelectedDoors) do
            self:AddDoor(v)
        end
    end
end

function PANEL:AddOption(ID, strName, bDefault)
    self._options[ID] = bDefault

    local option = self.Options:Add("Panel")
    option:Dock(TOP)
    option:SetTall(42)
    option:DockMargin(0,0,0,0)

    option.Title = option:Add("Panel")
    option.Title:Dock(TOP)
    option.Title:SetTall(20)
    option.Title.Text = option.Title:Add("DLabel")
    option.Title.Text:Dock(LEFT)
    option.Title.Text:SetTextColor(color_white)
    option.Title.Text:SetText(strName)
    option.Title.Text:SetFont("bSecure.Title")
    option.Title.Text:SizeToContents()

    option:SizeToContents()

    option.Toggle = option.Title:Add("ixDoorsMenu.Toggle")
    option.Toggle:SetState(false)
    option.Toggle:Dock(RIGHT)
    option.Toggle:SetWide(40)
    option.Toggle:SetState(self._options[ID])
    option.Toggle.OnToggled = function(pnl,bool)
        self._options[ID] = bool
    end
end

function PANEL:AddDoor(Door)
    local color_active = Color(72, 72, 82)

    local door = self.DoorList.Scroll:Add("DButton")
    door:Dock(TOP)
    door:DockMargin(2,2,2,2)
    door:SetTall(28)
    door:SetText("")
    door.Paint = function(pnl, w, h)
        draw.RoundedBoxEx(4, 0, 0, w, h, color_bg, true, true, true, true)
    end
    door.DoClick = function(pnl)
        Derma_Query("Remove door from list?", "Remove door", "Yes", function()
            pnl:Remove()
            local tool = LocalPlayer():GetTool("keys")
            if tool and tool.RemoveDoor then
                tool:RemoveDoor(Door)
            end
        end, "No")
    end

    local tool = LocalPlayer():GetTool("keys")
    
    door.Name = door:Add("DLabel")
    door.Name:Dock(LEFT)
    door.Name:DockMargin(6, 0, 0, 0)
    door.Name:SetText("Door " .. tostring(tool.bSelectedDoors[Door] or "") .. " ["..Door:EntIndex().."]")
    door.Name:SetFont("bSecure.Title")
    door.Name:SizeToContents()
    door.Name:SetTextColor(color_white)
end 

function PANEL:PerformLayout(w, h)

end

vgui.Register("ixDoorsMenu.RegisterHouse", PANEL)


local PANEL = {}

function PANEL:Init()
    self:DockPadding(8, 8, 8, 8)
    self.Title = self:Add("ixDoorsMenu.Searchbar")
    self.Title:Dock(TOP)
    self.Title:SetTall(38)
    self.Title:SetPlaceholderText("Search for a Property")

    self.Body = self:Add("Panel")
    self.Body:Dock(FILL)

    self.Scroll = self.Body:Add("DScrollPanel")
    self.Scroll:DockMargin(0, 4, 0, 0)
    self.Scroll:Dock(FILL)
    self.Scroll.vBar = self.Scroll:GetVBar()
    self.Scroll.vBar:SetWide(8)
    self.Scroll.vBar:SetHideButtons(true)
    self.Scroll.vBar.btnGrip.Paint = function(pnl, w, h)
        draw.RoundedBoxEx(w/3, 0, 0, w, h, color_grip, true, true, true, true)
    end
    self.Scroll.vBar.Paint = nil
    self.Scroll.Paint = nil

end

local housebg = Color(54, 54, 59)
function PANEL:AddProperty(tData)
    tData.entities = tData.entities or {}

    local panel = self.Scroll:Add("DPanel")
    panel:Dock(TOP)
    panel:SetTall(38)
    panel:DockMargin(0, 0, 0, 6)
    panel.Paint = function(pnl, w, h)
        draw.RoundedBox(4, 0, 0, w, h, housebg)
        draw.SimpleText(tData.name, "bSecure.Title", 6, h/2, color_white, 0, 1)
    end
    local view = panel:Add("DButton")
    view:Dock(RIGHT)
    view:SetFont("bSecure.Small")
    view:SetText("View Property")
    view:SizeToContentsX(8)
    view:SetText("")
    view.Paint = function(pnl, w, h)
        draw.SimpleText("View Property", "bSecure.Small", w/2, h/2, color_white, 1, 1)
    end
    view.DoClick = function(pnl)
        local ply = LocalPlayer()
        local wep = ply:GetWeapon("gmod_tool")
        if IsValid(wep) then
            input.SelectWeapon(wep)
            spawnmenu.ActivateTool("keys")
            timer.Simple(0.3, function()
                ply:GetTool().SelectedDoors = tData.entities
                for k,v in ipairs(tData.entities) do
                    ply:GetTool().bSelectedDoors[v] = k
                end
            end)
        end
    end

    local delete = panel:Add("DButton")
    delete:Dock(RIGHT)
    delete:SetFont("bSecure.Small")
    delete:SetText("Delete Property")
    delete:SizeToContentsX(8)
    delete:SetText("")
    delete.Paint = function(pnl, w, h)
        draw.SimpleText("Delete Property", "bSecure.Small", w/2, h/2, color_white, 1, 1)
    end
    delete.DoClick = function(pnl)
        Derma_Query("Are you sure you want to delete ".. tData.name.."?", "Delete Property", "Yes", function()
            PLUGIN:DeleteProperty(tData.name)
            panel:Remove()
        end, "No")
    end
end

vgui.Register("ixDoorsMenu.AllHouses", PANEL, "EditablePanel")


local PANEL = {}

function PANEL:Init()
    self:SetSize(ScrH()*0.7, ScrH()*0.55)
    self:MakePopup()
    self:Center()

    local navbar = self:Add("ixDoorsMenu.NavBar")
    navbar:Dock(LEFT)
    navbar:SetWide(160)
    navbar:SetBody(self)
    local page = navbar:AddPage("Register House", "ixDoorsMenu.RegisterHouse")
    page:AddOption("lock_default", "Lock on spawn", true)
    page:AddOption("start_open", "Start open", false)
    
    self.AllHouses = navbar:AddPage("All Houses", "ixDoorsMenu.AllHouses")
end

vgui.Register("ixDoorsMenu", PANEL, "ixDoorsMenu.Frame")
