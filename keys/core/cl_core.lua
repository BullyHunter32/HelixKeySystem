local PLUGIN = PLUGIN


PLUGIN.Properties = {}

local fCallback = function()end
function PLUGIN:RequestData(fCallback_)
    net.Start("ixKeysDataRequest")
    fCallback = fCallback_ or function() end
    net.SendToServer()
end

function PLUGIN:ReadProperty()
    local tData = {
        name = net.ReadString(),
        lock = net.ReadBool(),
        open = net.ReadBool(),
        entities = {}
    }

    local iEntities = net.ReadUInt(8)
    for i = 1, iEntities do
        tData.entities[i] = net.ReadEntity()
    end
    return tData
end

function PLUGIN:ReadProperties()
    local tProperties = {}
    local propertyCount = net.ReadUInt(12)
    for i = 1, propertyCount do
        tProperties[i] = self:ReadProperty()
    end
    self.Properties = tProperties
    return tProperties
end

function PLUGIN:DeleteProperty(sName)
    if not LocalPlayer():IsSuperAdmin() or not sName then
        return
    end
    net.Start("ixKeysDeleteProperty")
    net.WriteString(sName)
    net.SendToServer()
end

function PLUGIN:WriteProperty(name, lock_spawn, start_open, entities)
    if not name then return end
    net.WriteString(name)
    net.WriteBool(tobool(lock_spawn))
    net.WriteBool(tobool(start_open))
    
    local len = #entities
    net.WriteUInt(len, 8)
    for i = 1, len do
        net.WriteEntity(entities[i])
    end
end

function PLUGIN:RegisterProperty(sName, bLock, bOpen)
    if not sName then return end
    local tool = LocalPlayer():GetTool()
    if not tool or not istable(tool) then return end
    if tool.Name ~= "#tool.keys.name" then
        --print("Wrong tool!")
        return 
    end
    --print("Ents:")
    --PrintTable(tool.SelectedDoors or {})
    net.Start("ixKeysCreateProperty")
    self:WriteProperty(sName, bLock, bOpen, tool.SelectedDoors)
    net.SendToServer()
end

net.Receive("ixKeysDataRequest", function()
    local Data = PLUGIN:ReadProperties()
    fCallback(Data)
end)
