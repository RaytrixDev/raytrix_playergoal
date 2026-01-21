Config = {}

-- Optimalisatie: Check interval verhoogd voor betere performance
Config.CheckInterval = 10000 -- Elke 10 seconden (was 5s)

-- Player goals configuratie
-- Elke goal heeft: spelers nodig, rewards (met bank en coins), en label
Config.Goals = {
    {
        players = 20,
        label = "20 Spelers Goal",
        rewards = {
            {type = "bank", amount = 75000, label = "€75,000 Bank"}
        }
    },
    {
        players = 30,
        label = "30 Spelers Goal",
        rewards = {
            {type = "bank", amount = 150000, label = "€150,000 Bank"}
        }
    },
    {
        players = 40,
        label = "40 Spelers Goal",
        rewards = {
            {type = "bank", amount = 200000, label = "€200,000 Bank"}
        }
    },
    {
        players = 50,
        label = "50 Spelers Goal",
        rewards = {
            {type = "bank", amount = 300000, label = "€300,000 Bank"},
            {type = "coins", amount = 1, label = "1 Coin"}
        }
    },
    {
        players = 60,
        label = "60 Spelers Goal",
        rewards = {
            {type = "bank", amount = 375000, label = "€375,000 Bank"}
        }
    },
    {
        players = 70,
        label = "70 Spelers Goal",
        rewards = {
            {type = "bank", amount = 425000, label = "€425,000 Bank"}
        }
    },
    {
        players = 75,
        label = "75 Spelers Goal",
        rewards = {
            {type = "bank", amount = 450000, label = "€450,000 Bank"},
            {type = "coins", amount = 2, label = "2 Coins"}
        }
    },
    {
        players = 80,
        label = "80 Spelers Goal",
        rewards = {
            {type = "bank", amount = 500000, label = "€500,000 Bank"}
        }
    },
    {
        players = 90,
        label = "90 Spelers Goal",
        rewards = {
            {type = "bank", amount = 750000, label = "€750,000 Bank"}
        }
    },
    {
        players = 100,
        label = "100 Spelers Goal - MEGA BONUS!",
        rewards = {
            {type = "bank", amount = 1000000, label = "€1,000,000 Bank"},
            {type = "coins", amount = 3, label = "3 Coins"}
        }
    }
}

-- UI Positie en styling
Config.UI = {
    position = "top-right", -- positie van de UI
    showAnimation = true,   -- toon animaties
    playSound = true        -- speel geluid af bij goal completion
}

-- Notificatie berichten
Config.Messages = {
    goalReached = "Player Goal bereikt! Open /playergoal om je reward te kiezen.",
    rewardReceived = "Je hebt rewards ontvangen van de Player Goal!",
    rewardClaimed = "Beloning succesvol geclaimd!",
    alreadyClaimed = "Je hebt deze goal al geclaimd.",
    invalidGoal = "Ongeldige goal.",
    invalidReward = "Kies een geldige reward.",
    notCompleted = "Deze goal is nog niet behaald.",
    goalProgress = "Player Goal: %s/%s spelers online",
    timeRemaining = "Nog %s seconden om goal te behalen",
    menuHint = "Gebruik /playergoal om je beloning te kiezen"
}
