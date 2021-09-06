TOOL.Category = "Keys" -- Name of the category
TOOL.Name = "#tool.keys.name" -- Name to display. # means it will be translated ( see below )

if ( CLIENT ) then -- We can only use language.Add on client
	language.Add( "tool.keys.name", "Door Configurator" ) -- Add translation
	language.Add( "tool.keys.desc", "Left click to add doors. Right click to remove doors" ) -- Add translation
else
    return
end

TOOL.SelectedDoors = {}
TOOL.bSelectedDoors = {}
function TOOL:LeftClick( trace )
	if SERVER or not LocalPlayer():IsSuperAdmin() then print("FAT L") return end
    local Ent = trace.Entity
    if not IsValid(Ent) or not Ent:IsDoor() or self.bSelectedDoors[Ent] then
        return
    end
    local pos = table.insert(self.SelectedDoors, Ent)
    self.bSelectedDoors[Ent] = pos
    LocalPlayer():ChatPrint("Added door: ".. tostring(Ent).. " to the list! ("..tostring(#self.SelectedDoors)..")")
end

local PLUGIN = ix and ix.plugin and ix.plugin.Get and ix.plugin.Get("keys") or false
function TOOL:Deploy() -- Doesnt get called for some reason??
    if not PLUGIN or not PLUGIN.WriteProperty then
        PLUGIN = ix.plugin.Get("keys")
    end
end

hook.Add("InitPostEntity", "ixKeysSetup", function()
    PLUGIN = ix and ix.plugin and ix.plugin.Get and ix.plugin.Get("keys") or false
    print("Yayyy, Plugin", PLUGIN)
end)

function TOOL:DrawHUD()
    cam.Start3D()
        render.SetBlend(0.5)
        render.SetColorModulation(0.455, 0.863, 1)
        for k,v in ipairs(self.SelectedDoors) do
            if not IsValid(v) then
                table.remove(self.SelectedDoors, k)
                goto skip
            end
            
            v:DrawModel()

            ::skip::
        end
        render.SetColorModulation(1, 1, 1)
        render.SetBlend(1)
    cam.End3D()

    for k,v in ipairs(self.SelectedDoors) do
        if not IsValid(v) then
            table.remove(self.SelectedDoors, k)
            goto skip
        end
        
        local pos = (v:GetPos() + v:OBBCenter()):ToScreen()
        draw.SimpleText("Selected ("..k..")", "ChatFont", pos.x, pos.y, color_white, 1, 1)
        ::skip::
    end
end

function TOOL:Holster()
    self.SelectedDoors = {}
    self.bSelectedDoors = {}
end

function TOOL:RemoveDoor(Ent)
    if not IsValid(Ent) then
        return
    end

    if self.bSelectedDoors then
        self.bSelectedDoors[Ent] = nil
        for k,v in ipairs(self.SelectedDoors) do
            if v == Ent then
                self.bSelectedDoors[Ent] = nil
                table.remove(self.SelectedDoors, k)
                break
            end
        end

        self.bSelectedDoors = {}
        for k,v in ipairs(self.SelectedDoors) do
            self.bSelectedDoors[v] = k
        end
    end
end

function TOOL:RightClick( trace )
    if SERVER then return end
	local Ent = trace.Entity
    if not IsValid(Ent) or not Ent:IsDoor() then return end
    self:RemoveDoor(Ent)
    LocalPlayer():ChatPrint("Removed door from the list :(")
end

-- This function/hook is called when the player presses their reload key
local frame 

function TOOL:Reload( trace )
    if SERVER then return end
    if IsValid(frame) or not PLUGIN then
        print("RL1", frame, PLUGIN)
        return
    end
    PLUGIN:RequestData(function(data)
        frame = vgui.Create("ixDoorsMenu")
        PrintTable(data)
        for k,v in ipairs(data) do
            frame.AllHouses:AddProperty(v)
        end
    end)
end

net.Receive("ixKeysCreateProperty", function()
    if frame and frame:IsValid() then
        frame:Remove()
    end
end)

-- This function/hook is called every frame on client and every tick on the server

local circlecol = Color(97, 97, 115)
function TOOL:DrawToolScreen(w, h)
	-- Draw black background
	surface.SetDrawColor(47, 47, 52)
	surface.DrawRect( 0, 0, w, h )
	
	-- Draw white text in middle
	local tH, tW = draw.SimpleText( "Doors Selected", "DermaLarge", w / 2, h*0.1, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	draw.SimpleText( #self.SelectedDoors, "DermaLarge", w / 2, h*0.25, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )

    local count = w*0.05
    local margin = w*0.15
    for i = 0, (count-1)*margin, margin do
        draw.RoundedBox(
            5,
            ((i + (CurTime()*15))%w)-2, 
            h*0.66 + ((math.cos((CurTime() + (i/10))*(1)) * h*0.08))-2,
            5,
            5,
            circlecol
        )

        draw.RoundedBox(
            5,
            ((i + (CurTime()*15))%w)-2, 
            h*0.66 + (-(math.cos((CurTime() + (i/10))*(1)) * h*0.08))-2,
            5,
            5,
            circlecol
        )
        --surface.SetTextPos(iPosX + textOffsetX + boxWidth, iPosY + (math.cos((CurTime() + (i/10))*(iAnimSpeed)) * 20))
        --surface.DrawText(char)
    end
end