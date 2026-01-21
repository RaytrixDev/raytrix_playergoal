-- Framework Detection
local Framework = nil
local FrameworkName = nil

CreateThread(function()
    if GetResourceState('es_extended') == 'started' then
        Framework = exports['es_extended']:getSharedObject()
        FrameworkName = 'ESX'
    elseif GetResourceState('qb-core') == 'started' then
        Framework = exports['qb-core']:GetCoreObject()
        FrameworkName = 'QBCore'
    elseif GetResourceState('ox_core') == 'started' then
        Framework = require '@ox_core/lib/init'
        FrameworkName = 'OX'
    else
        FrameworkName = 'Standalone'
    end
end)

-- Geoptimaliseerde variabelen
local currentGoal = nil
local goalStartTime = nil
local completedGoals = {}
local claimedRewards = {} -- [identifier][goalPlayers] = true
local isGoalActive = false
local serverStartTime = os.time()
local lastPlayerCount = 0
local checkCounter = 0

-- Optimalisatie: Cache player count
local function GetOnlinePlayerCount()
    return GetNumPlayerIndices()
end

local function GetIdentifier(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if string.match(id, 'license:') then
            return id
        end
    end

    return ('src:%s'):format(src)
end

local function GetPlayer(src)
    if FrameworkName == 'ESX' then
        return Framework.GetPlayerFromId(src)
    elseif FrameworkName == 'QBCore' then
        return Framework.Functions.GetPlayer(src)
    elseif FrameworkName == 'OX' then
        return Framework.GetPlayer(src)
    end
    return nil
end

local function ShowNotification(src, message)
    if FrameworkName == 'ESX' then
        TriggerClientEvent('esx:showNotification', src, message)
    elseif FrameworkName == 'QBCore' then
        TriggerClientEvent('QBCore:Notify', src, message, 'success')
    elseif FrameworkName == 'OX' then
        TriggerClientEvent('ox_lib:notify', src, {type = 'success', description = message})
    else
        TriggerClientEvent('chat:addMessage', src, {args = {message}})
    end
end

local function HasClaimed(identifier, goalPlayers)
    return claimedRewards[identifier] and claimedRewards[identifier][goalPlayers] or false
end

local function MarkClaimed(identifier, goalPlayers)
    claimedRewards[identifier] = claimedRewards[identifier] or {}
    claimedRewards[identifier][goalPlayers] = true
end

-- Optimalisatie: Cache en find next goal efficient
local function FindNextGoal()
    for i = 1, #Config.Goals do
        local goal = Config.Goals[i]
        if not completedGoals[goal.players] then
            return goal
        end
    end
    return nil
end

local function HasCompletedGoal()
    for i = 1, #Config.Goals do
        if completedGoals[Config.Goals[i].players] then
            return true
        end
    end
    return false
end

local function BuildGoalStatus(identifier)
    local playerCount = GetOnlinePlayerCount()
    local status = {}

    for i = 1, #Config.Goals do
        local goal = Config.Goals[i]
        status[#status + 1] = {
            players = goal.players,
            label = goal.label,
            rewards = goal.rewards,
            completed = completedGoals[goal.players] == true,
            claimed = HasClaimed(identifier, goal.players),
            current = playerCount
        }
    end

    return status
end

-- Optimalisatie: Async database calls
local function SaveCompletedGoal(playerCount)
    MySQL.Async.execute('INSERT INTO playergoals_completed (player_count, server_start_time, completed_at) VALUES (@playerCount, @serverStartTime, @completedAt) ON DUPLICATE KEY UPDATE completed_at = @completedAt', {
        ['@playerCount'] = playerCount,
        ['@serverStartTime'] = serverStartTime,
        ['@completedAt'] = os.time()
    })
end

local function GiveReward(xPlayer, reward, src)
    if FrameworkName == 'ESX' then
        if reward.type == 'money' or reward.type == 'cash' then
            xPlayer.addMoney(reward.amount)
        elseif reward.type == 'bank' then
            xPlayer.addAccountMoney('bank', reward.amount)
        elseif reward.type == 'black_money' then
            xPlayer.addAccountMoney('black_money', reward.amount)
        elseif reward.type == 'item' then
            xPlayer.addInventoryItem(reward.item, reward.amount)
        elseif reward.type == 'coins' then
            local license = GetIdentifier(src)
            if license then
                MySQL.Async.execute('UPDATE player_coins SET coins = coins + @coins WHERE identifier = @identifier', {
                    ['@coins'] = reward.amount,
                    ['@identifier'] = license
                }, function(affectedRows)
                    if affectedRows > 0 then
                        ShowNotification(src, string.format('~y~+%d Premium Coin(s)~s~ ontvangen!', reward.amount))
                    end
                end)
            end
        end
    elseif FrameworkName == 'QBCore' then
        if reward.type == 'money' or reward.type == 'cash' then
            xPlayer.Functions.AddMoney('cash', reward.amount)
        elseif reward.type == 'bank' then
            xPlayer.Functions.AddMoney('bank', reward.amount)
        elseif reward.type == 'item' then
            xPlayer.Functions.AddItem(reward.item, reward.amount)
        elseif reward.type == 'coins' then
            local license = GetIdentifier(src)
            if license then
                MySQL.Async.execute('UPDATE player_coins SET coins = coins + @coins WHERE identifier = @identifier', {
                    ['@coins'] = reward.amount,
                    ['@identifier'] = license
                }, function(affectedRows)
                    if affectedRows > 0 then
                        ShowNotification(src, string.format('+%d Premium Coin(s) ontvangen!', reward.amount))
                    end
                end)
            end
        end
    elseif FrameworkName == 'OX' then
        if reward.type == 'money' or reward.type == 'cash' then
            exports.ox_inventory:AddItem(src, 'money', reward.amount)
        elseif reward.type == 'bank' then
            local accounts = xPlayer.getAccounts()
            if accounts then
                accounts.money = (accounts.money or 0) + reward.amount
                xPlayer.set('accounts', accounts)
            end
        elseif reward.type == 'item' then
            exports.ox_inventory:AddItem(src, reward.item, reward.amount)
        elseif reward.type == 'coins' then
            local license = GetIdentifier(src)
            if license then
                MySQL.Async.execute('UPDATE player_coins SET coins = coins + @coins WHERE identifier = @identifier', {
                    ['@coins'] = reward.amount,
                    ['@identifier'] = license
                }, function(affectedRows)
                    if affectedRows > 0 then
                        ShowNotification(src, string.format('+%d Premium Coin(s) ontvangen!', reward.amount))
                    end
                end)
            end
        end
    end
end

-- Optimalisatie: Single query load
local function LoadCompletedGoals()
    MySQL.Async.fetchAll('SELECT player_count FROM playergoals_completed WHERE server_start_time = @serverStartTime', {
        ['@serverStartTime'] = serverStartTime
    }, function(results)
        if results then
            for i = 1, #results do
                completedGoals[results[i].player_count] = true
            end
        end
    end)
end

-- Optimalisatie: Cleanup in single query
local function CleanupOldGoals()
    MySQL.Async.execute('DELETE FROM playergoals_completed WHERE server_start_time != @serverStartTime', {
        ['@serverStartTime'] = serverStartTime
    })
end

local function CompleteGoal(goal, playerCount)
    completedGoals[goal.players] = true
    SaveCompletedGoal(goal.players)

    TriggerClientEvent('playergoals:goalCompleted', -1, goal)
    TriggerClientEvent('playergoals:updateGoal', -1, {
        current = playerCount,
        required = goal.players,
        goal = goal,
        active = false,
        claimable = true
    })

    -- Framework-specific notification
    local players = GetPlayers()
    for i = 1, #players do
        ShowNotification(tonumber(players[i]), Config.Messages.goalReached or 'Player Goal bereikt!')
    end
    
    TriggerClientEvent('playergoals:announceCommand', -1)

    print(('[PlayerGoals] Goal %d voltooid! Beloning klaar om te claimen.'):format(goal.players))
end

-- Optimalisatie: Efficient goal checking met caching
local function CheckGoal()
    local playerCount = GetOnlinePlayerCount()
    
    -- Optimalisatie: Skip check als player count niet veranderd is
    if playerCount == lastPlayerCount and checkCounter < 12 then
        checkCounter = checkCounter + 1
        return
    end
    
    checkCounter = 0
    lastPlayerCount = playerCount
    
    local nextGoal = FindNextGoal()
    
    if nextGoal then
        if playerCount >= nextGoal.players and not completedGoals[nextGoal.players] then
            isGoalActive = true
            currentGoal = nextGoal

            CompleteGoal(nextGoal, playerCount)

            isGoalActive = false
            currentGoal = nil

            SetTimeout(500, function()
                CheckGoal()
            end)
            return
        else
            if isGoalActive then
                isGoalActive = false
                currentGoal = nil
            end

            TriggerClientEvent('playergoals:updateGoal', -1, {
                current = playerCount,
                required = nextGoal.players,
                goal = nextGoal,
                active = completedGoals[nextGoal.players] == true,
                claimable = completedGoals[nextGoal.players] == true or HasCompletedGoal()
            })
        end
    else
        TriggerClientEvent('playergoals:updateGoal', -1, {
            current = playerCount,
            required = 0,
            goal = nil,
            active = false,
            allCompleted = true
        })
        TriggerClientEvent('playergoals:allGoalsCompleted', -1)
    end
end

-- Optimalisatie: Cached request update
RegisterNetEvent('playergoals:requestUpdate', function()
    local src = source
    local playerCount = GetOnlinePlayerCount()
    local nextGoal = FindNextGoal()

    if nextGoal then
        TriggerClientEvent('playergoals:updateGoal', src, {
            current = playerCount,
            required = nextGoal.players,
            goal = nextGoal,
            active = completedGoals[nextGoal.players] == true,
            claimable = completedGoals[nextGoal.players] == true or HasCompletedGoal()
        })
    elseif playerCount < Config.Goals[1].players then
        TriggerClientEvent('playergoals:updateGoal', src, {
            current = playerCount,
            required = Config.Goals[1].players,
            goal = Config.Goals[1],
            active = false,
            claimable = HasCompletedGoal()
        })
    else
        TriggerClientEvent('playergoals:allGoalsCompleted', src)
    end
end)

RegisterNetEvent('playergoals:requestMenu', function()
    local src = source
    local identifier = GetIdentifier(src)

    TriggerClientEvent('playergoals:openMenu', src, {
        goals = BuildGoalStatus(identifier),
        currentPlayers = GetOnlinePlayerCount(),
        command = '/playergoal'
    })
end)

RegisterNetEvent('playergoals:claimReward', function(goalPlayers, rewardIndex)
    local src = source
    local identifier = GetIdentifier(src)
    local xPlayer = GetPlayer(src)

    if not xPlayer then return end

    local parsedGoalPlayers = tonumber(goalPlayers)
    if not parsedGoalPlayers then
        TriggerClientEvent('playergoals:claimResult', src, { success = false, message = Config.Messages.invalidGoal or 'Ongeldige goal.' })
        return
    end

    local goal = nil
    for _, g in ipairs(Config.Goals) do
        if g.players == parsedGoalPlayers then
            goal = g
            break
        end
    end

    if not goal then
        TriggerClientEvent('playergoals:claimResult', src, { success = false, message = Config.Messages.invalidGoal or 'Ongeldige goal.' })
        return
    end

    if not completedGoals[goal.players] then
        TriggerClientEvent('playergoals:claimResult', src, { success = false, message = Config.Messages.notCompleted or 'Deze goal is nog niet behaald.' })
        return
    end

    if HasClaimed(identifier, goal.players) then
        TriggerClientEvent('playergoals:claimResult', src, { success = false, message = Config.Messages.alreadyClaimed or 'Je hebt deze beloning al geclaimd.' })
        return
    end

    local reward = goal.rewards[rewardIndex]
    if not reward then
        TriggerClientEvent('playergoals:claimResult', src, { success = false, message = Config.Messages.invalidReward or 'Ongeldige reward.' })
        return
    end

    GiveReward(xPlayer, reward, src)
    MarkClaimed(identifier, goal.players)

    ShowNotification(src, Config.Messages.rewardClaimed or Config.Messages.rewardReceived or 'Beloning geclaimd!')
    TriggerClientEvent('playergoals:claimResult', src, {
        success = true,
        goalPlayers = goal.players,
        message = Config.Messages.rewardClaimed or 'Beloning geclaimd!'
    })
end)

-- Optimalisatie: Admin command
RegisterCommand('resetgoals', function(source, args, rawCommand)
    if source == 0 or IsPlayerAceAllowed(source, 'admin') then
        completedGoals = {}
        claimedRewards = {}
        currentGoal = nil
        isGoalActive = false
        lastPlayerCount = 0
        checkCounter = 0
        
        if source == 0 then
            print('[PlayerGoals] Goals gereset!')
        else
            ShowNotification(source, 'Goals gereset!')
        end
        
        CheckGoal()
    end
end, false)

-- Optimalisatie: Main loop met dynamisch interval
CreateThread(function()
    while true do
        Wait(Config.CheckInterval)
        CheckGoal()
    end
end)

-- Optimalisatie: Startup sequence
CreateThread(function()
    Wait(500)
    print('^2============================================^0')
    print('^3[Raytrix PlayerGoals]^0 ^2Community Goal System^0')
    print('^7Framework: ^5' .. (FrameworkName or 'Loading...') .. '^0 ^7| Developed by ^5Raytrix^0')
    print('^2============================================^0')
    
    CleanupOldGoals()
    Wait(200)
    LoadCompletedGoals()
    Wait(300)
    CheckGoal()
end)
