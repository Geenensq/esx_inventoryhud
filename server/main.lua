ESX = nil

TriggerEvent(
        "esx:getSharedObject",
        function(obj)
            ESX = obj
        end
)

ESX.RegisterServerCallback(
        "esx_inventoryhud:getPlayerInventory",
        function(source, cb, target)
            local targetXPlayer = ESX.GetPlayerFromId(target)

            if targetXPlayer ~= nil then
                cb({ inventory = targetXPlayer.inventory, money = targetXPlayer.getMoney(), accounts = targetXPlayer.accounts, weapons = targetXPlayer.loadout })
            else
                cb(nil)
            end
        end
)

RegisterServerEvent("esx_inventoryhud:tradePlayerItem")
AddEventHandler(
        "esx_inventoryhud:tradePlayerItem",
        function(from, target, type, itemName, itemCount)
            local _source = from

            local sourceXPlayer = ESX.GetPlayerFromId(_source)
            local targetXPlayer = ESX.GetPlayerFromId(target)

            if type == "item_standard" then
                local sourceItem = sourceXPlayer.getInventoryItem(itemName)
                local targetItem = targetXPlayer.getInventoryItem(itemName)

                if itemCount > 0 and sourceItem.count >= itemCount then
                    if targetItem.limit ~= -1 and (targetItem.count + itemCount) > targetItem.limit then
                    else
                        sourceXPlayer.removeInventoryItem(itemName, itemCount)
                        targetXPlayer.addInventoryItem(itemName, itemCount)
                    end
                end
            elseif type == "item_money" then
                if itemCount > 0 and sourceXPlayer.getMoney() >= itemCount then
                    sourceXPlayer.removeMoney(itemCount)
                    targetXPlayer.addMoney(itemCount)
                end
            elseif type == "item_account" then
                if itemCount > 0 and sourceXPlayer.getAccount(itemName).money >= itemCount then
                    sourceXPlayer.removeAccountMoney(itemName, itemCount)
                    targetXPlayer.addAccountMoney(itemName, itemCount)
                end
            elseif type == "item_weapon" then
                if not targetXPlayer.hasWeapon(itemName) then
                    local pos, playerWeapon = sourceXPlayer.getWeapon(itemName)
                    local components = playerWeapon.components

                    sourceXPlayer.removeWeapon(itemName)
                    targetXPlayer.addWeapon(itemName, itemCount)

                    if components == nil then
                        components = {}
                    end

                    for i = 1, #components do
                        targetXPlayer.addWeaponComponent(itemName, components[i])
                    end
                end
            end
        end
)

RegisterCommand(
        "openinventory",
        function(source, args, rawCommand)
            if IsPlayerAceAllowed(source, "inventory.openinventory") then
                local target = tonumber(args[1])
                local targetXPlayer = ESX.GetPlayerFromId(target)

                if targetXPlayer ~= nil then
                    TriggerClientEvent("esx_inventoryhud:openPlayerInventory", source, target, targetXPlayer.name)
                else
                    TriggerClientEvent("chatMessage", source, "^1" .. _U("no_player"))
                end
            else
                TriggerClientEvent("chatMessage", source, "^1" .. _U("no_permissions"))
            end
        end
)

RegisterServerEvent("esx_inventoryhud:buyItem")
AddEventHandler("esx_inventoryhud:buyItem", function(item, amount, potentialShopId, potentialJobBuy)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local haveJob = false;
    if potentialJobBuy ~= nil then
        for i, v in ipairs(potentialJobBuy) do
            if xPlayer.job.name == potentialJobBuy[i] then
                haveJob = true;
            end
        end

        if not haveJob then
            TriggerClientEvent(
                    'mythic_notify:client:SendAlert',
                    _source,
                    { type = 'error', text = 'Cette boutique ne vend qu\'exclusivement au employés d\'un métier' }
            )
            return
        end
    end

    TriggerEvent('esx_inventoryhud_shops:getStockItem', potentialShopId, function(result)
        local stockItem = result[item.name]
        local haveTheLicense = false

        if item.type == "item_standard" then

            if stockItem >= amount then
                if amount > 0 then
                    print('Try log for the error : ' , item.name, amount)
                    if not xPlayer.canCarryItem(item.name, amount) then
                        TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'error', text = _U("not_enough_space") })
                    else
                        local price = amount * item.price

                        if potentialJobBuy ==  xPlayer.job.name then
                            -- Gives money to society
                            local societyName = "society_" .. potentialJobBuy
                            TriggerEvent('esx_addonaccount:getSharedAccount', societyName, function(account)
                                account.removeMoney(price)
                            end)
                        else
                            if xPlayer.getMoney() >= price then
                                xPlayer.removeMoney(price)
                                xPlayer.addInventoryItem(item.name, amount)

                                TriggerClientEvent(
                                        'mythic_notify:client:SendAlert',
                                        _source,
                                        { type = 'success', text = _U("bought", amount, item.label, item.price) }
                                )

                                TriggerEvent('esx_inventoryhud_shops:decrementStockItem', potentialShopId, item.name, amount)

                            else
                                TriggerClientEvent(
                                        'mythic_notify:client:SendAlert',
                                        _source,
                                        { type = 'error', text = _U("not_enough_money") }
                                )
                            end

                        end

                    end
                end
            else
                TriggerClientEvent(
                        'mythic_notify:client:SendAlert',
                        _source,
                        { type = 'error', text = 'La boutique n\'a pas assez de stock pour ce produit' }
                )
            end

        elseif item.type == "item_weapon" then

            -- check if the item need a license and if the player have the license
            if item.need_license then
                TriggerEvent('esx_license:getLicenses', _source, function(licenses)
                    for i, v in ipairs(licenses) do
                        if licenses[i].type == item.license then
                            haveTheLicense = true
                        end
                    end

                    if not haveTheLicense and item.need_license then
                        TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'error', text = 'Vous devez avoir une license pour acheter cet article !' })
                    else
                        if xPlayer.getMoney() >= item.price then
                            if not xPlayer.hasWeapon(item.name) then
                                xPlayer.removeMoney(item.price)
                                xPlayer.addWeapon(item.name, item.ammo)

                                TriggerClientEvent(
                                        'mythic_notify:client:SendAlert',
                                        _source,
                                        { type = 'success', text = _U("bought", 1, item.label, item.price) }
                                )

                            else

                                TriggerClientEvent(
                                        'mythic_notify:client:SendAlert',
                                        _source,
                                        { type = 'error', text = _U("already_have_weapon") }
                                )

                            end
                        else
                            TriggerClientEvent(
                                    'mythic_notify:client:SendAlert',
                                    _source,
                                    { type = 'error', text = _U("not_enough_money") }
                            )
                        end
                    end
                end)
            else
                if xPlayer.getMoney() >= item.price then
                    if not xPlayer.hasWeapon(item.name) then
                        xPlayer.removeMoney(item.price)
                        xPlayer.addWeapon(item.name, item.ammo)
                        TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'success', text = _U("bought", 1, item.label, item.price) })
                    else
                        TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'error', text = _U("already_have_weapon") })
                    end
                else
                    TriggerClientEvent('mythic_notify:client:SendAlert', _source, { type = 'error', text = _U("not_enough_money") })
                end
            end

        end

    end)
end)
