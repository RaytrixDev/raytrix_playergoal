# 🎯 Raytrix PlayerGoals

Een community goal systeem waarbij spelers samen werken om doelen te bereiken en beloningen kunnen claimen.

## ✨ Features

- **Community Goals**: Spelers werken samen om doelen te behalen (online tijd, politie arresten, etc.)
- **Manual Claim System**: Spelers claimen hun eigen beloningen via `/playergoal`
- **Multi-Framework**: Ondersteunt ESX, QBCore, OX Core en Standalone
- **Real-time Progress**: Live progress tracking met moderne UI
- **Automatic Rotation**: Goals resetten automatisch na verloop tijd
- **Coin & Money Rewards**: Keuze uit verschillende beloningen per goal

## 📦 Installatie

1. Plaats de resource in je resources folder
2. Voeg `ensure raytrix_playergoal` toe aan je server.cfg
3. Importeer `playergoals.sql` in je database
4. Configureer `config.lua` naar wens
5. Herstart je server

## 🎮 Commands

- `/playergoal` - Open het claim menu om je beloningen te kiezen

## 🛠️ Admin Commands

- `/resetgoals` - Reset alle actieve goals en progress (alleen voor admins)

## ⚙️ Configuratie

Alle instellingen zijn aan te passen in `config.lua`:
- Goal types (online tijd, politie arresten, etc.)
- Reward amounts (coins & geld)
- Check intervals
- Progress thresholds
- En meer...

## 🎨 UI Theme

- Modern light blue/white design
- Semi-transparante widget rechts op het scherm
- Responsive hover effecten
- Custom scrollbar styling

## 📝 Gemaakt door Raytrix Scripts

Voor vragen of support, neem contact op via onze Discord.