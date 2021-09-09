local PLUGIN = PLUGIN

local bInit = false
function PLUGIN:DatabaseConnected()
    if bInit then return end
    local query = mysql:Create("ix_properties")
        query:Create("id", "INT(11) UNSIGNED NOT NULL AUTO_INCREMENT")
        query:Create("name", "VARCHAR(50) NOT NULL")
        query:Create("map", "VARCHAR(50) NOT NULL")
        query:Create("entities", "VARCHAR(255) NOT NULL")
        query:Create("lock_spawn", "INT(2) UNSIGNED NOT NULL DEFAULT '1'")
        query:Create("start_open", "INT(2) UNSIGNED NOT NULL DEFAULT '0'")
        query:PrimaryKey("id")
    query:Execute()
    bInit = true
end

PLUGIN.CachedDoors = {}
function PLUGIN:GetAllDoorData(fCallback)
    local select = mysql:Select("ix_properties")
        select:Select("id")
        select:Select("name")
        select:Select("entities")
        select:Select("lock_spawn")
        select:Select("start_open")
        select:Where("map", game.GetMap())
        select:Callback(function(results)
            PLUGIN.CachedDoors = results
            fCallback(results or {})
        end)
    select:Execute()
end

function PLUGIN:InitializeDoors(bInit)
    self:GetAllDoorData(function(data)
        for k,v in ipairs(data) do
            local bLock = tobool(v.lock_spawn)
            local bOpen = tobool(v.start_open)
            local EntIds = util.JSONToTable(v.entities)
            if not EntIds or istable(EntIds) and #EntIds == 0 then print("L ", EntIds) goto next_ end
            for k, EntId in ipairs(EntIds) do
                local Entity = ents.GetMapCreatedEntity(EntId)
                if not IsValid(Entity) then
                    goto skip
                end 
                if bInit then
                    if bOpen then
                        Entity:Fire("unlock")
                        Entity:Fire("open")
                    end
                    if bLock then
                        Entity:Fire("lock")
                    end
                end
                Entity.KeyRequired = v.id
                ::skip::
            end
            ::next_::
        end
    end)
end

function PLUGIN:InitPostEntity()
    if not bInit then
        self:DatabaseConnected()
    end
    self:InitializeDoors(true)
end

function PLUGIN:WriteProperty(name, lock_spawn, start_open, entities)
    net.WriteString(name or "Unknown")
    net.WriteBool(tobool(lock_spawn))
    net.WriteBool(tobool(start_open))
    
    local len = #entities
    net.WriteUInt(len, 8)
    for i = 1, len do
        net.WriteEntity(entities[i])
    end
end

util.AddNetworkString("ixKeysDataRequest")
function PLUGIN:WriteProperties(pPlayer)
    self:GetAllDoorData(function(data)
        print("Preparing to write the following data...")
        PrintTable(data or {"no data, wtf?"})
        net.Start("ixKeysDataRequest")
        net.WriteUInt(#data, 12)
        for k,v in ipairs(data) do
            local bLock = tobool(v.lock_spawn)
            local bOpen = tobool(v.start_open)
            local EntIds = util.JSONToTable(v.entities)
            if not EntIds or istable(EntIds) and #EntIds == 0 then print("L ", EntIds) goto next_ end
            local tEntities = {}
            for k, v in ipairs(EntIds) do
                local Entity = ents.GetMapCreatedEntity(v)
                if not IsValid(Entity) then
                    goto skip
                end 
                table.insert(tEntities, Entity)
                ::skip::
            end
            self:WriteProperty(v.name or "Invalid Name", bLock, bOpen, tEntities)
            ::next_::
        end
        net.Send(pPlayer)
    end)
end

function PLUGIN:RequestProperties(pPlayer)
    if not pPlayer:IsSuperAdmin() then
        return
    end
    self:WriteProperties(pPlayer)
end

function PLUGIN:DeleteProperty(sName, sMap)
    local select = mysql:Select("ix_properties")
        select:Select("id")
        select:Where("name", sName)
        select:Where("map", sMap)
        select:Limit(1)
        select:Callback(function(data)
            if istable(data) and #data > 0 then
                local id = data[1].id
                local delete = mysql:Delete("ix_properties")
                    delete:Where("id", id)
                    delete:Where("map", sMap)
                    delete:Where("name", sName)
                delete:Execute()
                print("Deleted property [id]["..sName.."]")
            end
        end)
    select:Execute()
end

function PLUGIN:CreateProperty(sName, tEntities, bOpen, bLock)
    if not sName then
        return
    end
    
    bSpawn = tostring(bSpawn)
    bLock = tostring(bLock)
    
    bSpawn = bSpawn == nil and 0 or bSpawn == 'true' and 1 or 0
    bLock = bLock == nil and 1 or bLock == 'true' and 1 or 0

    local tData = {}
    for k,v in ipairs(tEntities) do
        if IsValid(v) then
            table.insert(tData, v:MapCreationID())
        end
    end

    local sData = util.TableToJSON(tData)
    local select = mysql:Select("ix_properties")
        select:Where("name", sName)
        select:Where("map", game.GetMap())
        select:Callback(function(results)
            if not results or #results == 0 then
                local insert = mysql:Insert("ix_properties")
                    insert:Insert("name", sName)
                    insert:Insert("map", game.GetMap())
                    insert:Insert("entities", sData)
                    insert:Insert("lock_spawn", bLock)
                    insert:Insert("start_open", bOpen)
                insert:Execute()
            end
        end)
    select:Execute()
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

util.AddNetworkString("ixKeysCreateProperty")
net.Receive("ixKeysCreateProperty", function(_, pPlayer)
    if not pPlayer:IsSuperAdmin() then return end
    local p = PLUGIN:ReadProperty()
    print("Property: ", p)
    PrintTable(p or {"fat L"})
    if p.name == nil or p.lock == nil or p.open == nil or p.entities == nil then
        print("missing data :(")
        return
    end

    PLUGIN:CreateProperty(p.name, p.entities, p.open, p.lock)

    net.Start("ixKeysCreateProperty")
    net.WriteBool(true)
    net.Send(pPlayer)
end)

function PLUGIN:PlayerDeleteProperty(pPlayer, sName)
    if not pPlayer:IsSuperAdmin() then
        return
    end
    self:DeleteProperty(sName, game.GetMap())
end

net.Receive("ixKeysDataRequest", function(_, pPlayer)
    PLUGIN:RequestProperties(pPlayer)
end)

util.AddNetworkString("ixKeysDeleteProperty")
net.Receive("ixKeysDeleteProperty", function(_, pPlayer)
    if not pPlayer:IsSuperAdmin() then
        print("Banned player for attempting to bypass and exploit keys system")
        pPlayer:Ban(0, true)
        return
    end
    local sName = net.ReadString()
    if not sName then return end
    PLUGIN:PlayerDeleteProperty(pPlayer, sName)
end)
