local shopZone = nil
local currentShopId
local currentJobBuy

RegisterNetEvent("esx_inventoryhud:openShop")
AddEventHandler("esx_inventoryhud:openShop", function(zone, items, shopId, jobBuy)
            currentShopId = shopId
            currentJobBuy = jobBuy
            setShopData(zone, items)
            openShop()
        end
)

function setShopData(zone, items)
    shopZone = zone

    SendNUIMessage(
            {
                action = "setType",
                type = "shop"
            }
    )

    SendNUIMessage(
            {
                action = "setInfoText",
                text = _U("store")
            }
    )

    SendNUIMessage(
            {
                action = "setSecondInventoryItems",
                itemList = items,
            }
    )
end

function openShop()
    loadPlayerInventory()
    isInInventory = true

    SendNUIMessage(
            {
                action = "display",
                type = "shop"
            }
    )

    SetNuiFocus(true, true)
end

RegisterNUICallback("BuyItem", function(data, cb)
    if type(data.number) == "number" and math.floor(data.number) == data.number then
        local count = tonumber(data.number)
        if shopZone == "custom" then
            TriggerServerEvent("esx_inventoryhud:buyItem", data.item, count, currentShopId, currentJobBuy)
        else
            TriggerServerEvent("esx_shops:buyItem", data.item.name, count, shopZone)
        end
    end

    Wait(250)
    loadPlayerInventory()

    cb("ok")
end
)

RegisterNUICallback("PutIntoShop", function(data, cb)
    local count = tonumber(data.number)

    if data.item.type == "item_weapon" then
        count = GetAmmoInPedWeapon(PlayerPedId(), GetHashKey(data.item.name))
    end

    TriggerServerEvent("esx_inventoryhud_shops:sellItemShop", data.item.name, count, currentShopId, data.item.type, GetPlayerServerId(PlayerId()))
    Wait(250)
    loadPlayerInventory()
    cb("ok")
end)
