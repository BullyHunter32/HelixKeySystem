ITEM.name = "House Key"
ITEM.description = "A key used to open a door."
ITEM.model = "models/spartex117/key.mdl"
ITEM.width = 1
ITEM.height = 1

-- function ITEM:OnInstanced(invID, x, y, item)
-- 	item:SetData("HouseName", "Unknown House")
-- 	item:SetData("PropertyID", -1)
-- end

function ITEM:GetName()
    return "Key for ".. self:GetData("HouseName", "unknown door")
end