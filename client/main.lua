local ESX = exports['es_extended']:getSharedObject()

local uiVisible = false
local currentGoalData = nil
local playerPreference = true -- Speler wil de goal standaard zien
local menuOpen = false

-- Optimalisatie: Cache SendNUIMessage calls
local function SendNUI(data)
    SendNUIMessage(data)
end

-- Functie om UI te tonen (geoptimaliseerd)
local function ShowUI()
    if not uiVisible and playerPreference then
        SendNUI({action = 'show'})
        uiVisible = true
    end
end

-- Functie om UI te verbergen (geoptimaliseerd)
local function HideUI()
    if uiVisible then
        SendNUI({action = 'hide'})
        uiVisible = false
    end
end

-- Functie om UI te updaten (geoptimaliseerd)
local function UpdateUI(data)
    SendNUI({action = 'update', data = data})
end

-- Toggle UI met mooie animatie
local function ToggleUI()
    playerPreference = not playerPreference
    
    if playerPreference then
        -- Speler wil de goal weer zien
        SendNUI({action = 'toggleOn'})
        uiVisible = true
        
        -- Update met huidige data als die er is
        if currentGoalData then
            UpdateUI(currentGoalData)
        end
        
        -- Toon notificatie
        ESX.ShowNotification('De playergoal is succesvol ingeschakeld!')
    else
        -- Speler wil de goal verbergen
        SendNUI({action = 'toggleOff'})
        uiVisible = false
        
        -- Toon notificatie
        ESX.ShowNotification('De playergoal is succesvol uitgeschakeld!')
    end
end

local function CloseMenu()
    if menuOpen then
        SetNuiFocus(false, false)
        SendNUI({action = 'closeMenu'})
        menuOpen = false
    end
end

-- Event: Update goal informatie (geoptimaliseerd)
RegisterNetEvent('playergoals:updateGoal', function(data)
    currentGoalData = data
    ShowUI()
    UpdateUI(data)
end)

-- Event: Goal completed (geoptimaliseerd)
RegisterNetEvent('playergoals:goalCompleted', function(goal)
    SendNUI({action = 'goalCompleted', goal = goal, command = '/playergoal'})
end)

-- Event: Alle goals completed (geoptimaliseerd)
RegisterNetEvent('playergoals:allGoalsCompleted', function()
    SendNUI({action = 'allCompleted'})
end)

-- Event: Toon reward notificatie (geoptimaliseerd)
RegisterNetEvent('playergoals:showRewardNotification', function(goal)
    SendNUI({action = 'showRewards', rewards = goal.rewards})
end)

RegisterNetEvent('playergoals:announceCommand', function()
    SendNUI({action = 'commandHint', command = '/playergoal'})
end)

RegisterNetEvent('playergoals:openMenu', function(payload)
    SendNUI({action = 'openMenu', data = payload})
    SetNuiFocus(true, true)
    menuOpen = true
end)

RegisterNetEvent('playergoals:claimResult', function(data)
    SendNUI({action = 'claimResult', data = data})

    if data and data.message then
        ESX.ShowNotification(data.message)
    end

    if data and data.success then
        -- Kleine bevestiging in UI
        SendNUI({action = 'toast', kind = 'success'})
    end
end)

-- Event: Verberg/Toon UI wanneer andere menus openen (dpemotes, etc.)
RegisterNetEvent('playergoals:hideForMenu', function(hide)
    if hide then
        -- Verberg tijdelijk de playergoal
        if uiVisible then
            SendNUI({action = 'hide'})
        end
    else
        -- Toon weer als de speler het wil zien
        if playerPreference and currentGoalData then
            SendNUI({action = 'show'})
            UpdateUI(currentGoalData)
        end
    end
end)

-- Request update bij resource start (1x) en toon UI direct
CreateThread(function()
    Wait(1000)
    TriggerServerEvent('playergoals:requestUpdate')
    
    -- Zorg dat UI zichtbaar is als speler het wil
    if playerPreference then
        ShowUI()
    end
end)

-- Command om player goal UI te togglen (persoonlijk)
RegisterCommand('toggleplayergoal', function()
    ToggleUI()
end, false)

-- Alternatieve command naam (korter)
RegisterCommand('togglegoal', function()
    ToggleUI()
end, false)

-- Nog een alternatief (super kort)
RegisterCommand('tgoal', function()
    ToggleUI()
end, false)

-- Nieuw: Open het claim-menu met /playergoal
RegisterCommand('playergoal', function()
    TriggerServerEvent('playergoals:requestMenu')
end, false)

RegisterNUICallback('closeMenu', function(_, cb)
    CloseMenu()
    cb('ok')
end)

RegisterNUICallback('claimReward', function(data, cb)
    if data and data.goalPlayers and data.rewardIndex then
        TriggerServerEvent('playergoals:claimReward', data.goalPlayers, data.rewardIndex)
    end
    cb('ok')
end)
