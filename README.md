# MangUI — Make Combat Information Part of Your UI

MangUI brings unit frames, combat tracking, and everyday utilities together in one customizable World of Warcraft addon. Metallic borders, glass textures, and animated effects give it a distinctive look, while keeping character status, target information, and important alerts close at hand.

## Distinctive Unit Frames

Frames for your player, target, pet, focus, target of target, party, and bosses bring together health, resources, casts, and auras. Customize portraits, borders, textures, fonts, and colors, with rotating inner rings, light sweeps, and animated class resources to complete your layout.

## Flexible Combat Tracking

- **Class Skill Tracking:** Track ability cooldowns and debuffs you apply to your target, with optional keybind labels.
- **Equipment Procs & Other Effects:** Track buffs, debuffs, and equipment effects, with configurable glow and sound alerts.
- **Cooldown Tracking:** Automatically display ability and item cooldowns within your chosen duration range, with a blacklist to exclude unwanted entries.
- **Group Status Alerts:** Track missing raid buffs, weapon enhancements, selected buffs received from teammates, and missing target debuffs.
- **Range & Threat Indicators:** View target range and threat information, with configurable range thresholds for each class.

Class skill and equipment tracking lists are saved separately by character and talent setup, switching automatically when your setup changes. Advanced users can extend tracking conditions with custom Lua code.

## Visual Layout Editing

Preview modules in the settings window, drag elements into place, and adjust scale, fonts, colors, opacity, and textures. A unified movement mode makes arranging your overall layout easier, with support for undo, per-module resets, and configuration import and export.

Enable modules individually and combine them into a layout that suits your playstyle.

## Everyday Utilities

Keep useful tools within reach: item and equipment buttons, item counts and cooldowns, chat shortcuts, game menu shortcuts, an experience bar, a mouse highlight, and text or sound notifications when entering or leaving combat.

## 11 Interface Languages

MangUI supports:

- English
- German — Deutsch
- French — Français
- Spanish (Europe) — Español (EU)
- Spanish (Latin America) — Español (LatAm)
- Portuguese (Brazil) — Português (BR)
- Italian — Italiano
- Russian — Русский
- Korean — 한국어
- Simplified Chinese — 简体中文
- Traditional Chinese — 繁體中文

The interface automatically matches your game client’s language when you log in. You can also switch languages in the addon settings for the current session.

Russian and Korean use dedicated fonts for readable text and appropriate character spacing. Buttons and other controls with limited space use concise translations and adaptive text sizing to keep labels within their borders.

## Getting Started

After installation, type **`/mui`** or click the minimap button to open settings. Adjust your layout while out of combat.

MangUI runs independently and does not require WeakAuras. SharedMedia is optional and provides additional status bar textures. Feature availability varies by game version and the APIs available in your client.

Author: **Nc**

## Screenshot Gallery

Explore the in-game layout and the settings available for each module. Click any image to view it at full resolution.

### 01. Interface Overview

MangUI in game, with player and target frames positioned near the character, tracking icons arranged around them, and guide lines connecting supporting information. This overview shows how the modules fit together in a complete layout.

![MangUI — Interface Overview](Screenshots/01-MangUI-Interface-Overview.png)

### 02. Unlock Movement Mode

Unlock movement mode to reposition modules using colored drag areas and a screen grid. Labels identify the different elements so you can arrange unit frames, tracking rows, and utilities as one layout.

![MangUI — Unlock Movement Mode](Screenshots/02-MangUI-Unlock-Movement-Mode.png)

### 03. Interface Overview in Combat

A view of MangUI during combat, showing player and target status alongside active tracking icons. Health, resources, casts, and supporting combat information remain grouped around the action.

![MangUI — Interface Overview in Combat](Screenshots/03-MangUI-Interface-Overview-in-Combat.png)

### 04. Player and Target Frames

Customize the main player and target frames with a live preview of the combined layout. Adjust overall scale, portrait scale, and outer ring scale, then choose from the available portrait border styles.

![MangUI — Player and Target Frames](Screenshots/04-MangUI-Player-and-Target-Frames.png)

### 05. Player Cast Bar

Configure the player cast bar with adjustable scale, spell icon size, bar color, and cast text settings. Separate options control the melee and ranged attack progress indicators shown alongside casting information.

![MangUI — Player Cast Bar](Screenshots/05-MangUI-Player-Cast-Bar.png)

### 06. Pet Frame

Give the pet frame its own scale, portrait position, bar texture, and colors. Name offsets and font controls let you place its label precisely, while visibility options can hide the pet name or power bar.

![MangUI — Pet Frame](Screenshots/06-MangUI-Pet-Frame.png)

### 07. Target of Target Frame

Style the target of target frame with an adjustable portrait, health bar texture, colors, and name placement. Its preview and guide line settings help position this secondary target information beside your main frames.

![MangUI — Target of Target Frame](Screenshots/07-MangUI-Target-of-Target-Frame.png)

### 08. Focus Frame

Keep an eye on your focus using a dedicated frame with customizable portrait scale, health bar styling, and name text. Cast bar offsets provide additional control over where focus casting information appears.

![MangUI — Focus Frame](Screenshots/08-MangUI-Focus-Frame.png)

### 09. Party Frames

Arrange party frames with adjustable vertical spacing and a separate offset for the player frame. Shared bar textures, colors, and name fonts keep the group consistent, with visibility options for raids, party numbers, and self.

![MangUI — Party Frames](Screenshots/09-MangUI-Party-Frames.png)

### 10. Boss Frames

Customize boss health and cast bars through a dedicated preview. Texture and color selectors, health percentage offsets, font settings, and portrait visibility let you fit encounter information into your layout.

![MangUI — Boss Frames](Screenshots/10-MangUI-Boss-Frames.png)

### 11. Class Skill Tracking

Build a tracking list for selected ability cooldowns and target debuffs, with optional shortcut labels and individual label colors. Choose an arrangement direction and drag entries into the order you want to see in combat.

![MangUI — Class Skill Tracking](Screenshots/11-MangUI-Class-Skill-Tracking.png)

### 12. Equipment Procs and Other Tracking

Monitor equipment effects and other triggers with individually configured glow colors and sound alerts. Equipment slot selectors and display conditions let you tailor each entry, while the preview shows the resulting icon row.

![MangUI — Equipment Procs and Other Tracking](Screenshots/12-MangUI-Equipment-Procs-and-Other-Tracking.png)

### 13. Cooldown Tracking

Automatically display spell and item cooldowns within your chosen minimum and maximum duration. Use the exclusion list to remove entries you do not want, and adjust the module scale to fit the surrounding layout.

![MangUI — Cooldown Tracking](Screenshots/13-MangUI-Cooldown-Tracking.png)

### 14. Teammate Buff Tracking

Track selected buffs received from teammates in an adjustable icon row. Each configured effect can have its own sound alert, and drag sorting lets you put the most useful notifications first.

![MangUI — Teammate Buff Tracking](Screenshots/14-MangUI-Teammate-Buff-Tracking.png)

### 15. Raid Vulnerability Tracking

Configure target debuff and player buff checks used by the raid vulnerability module. Alternative spell entries, class loading controls, and drag sorting help organize the effects you want the module to check.

![MangUI — Raid Vulnerability Tracking](Screenshots/15-MangUI-Raid-Vulnerability-Tracking.png)

### 16. Missing Raid Buff Tracking

Show reminders when configured raid buffs are missing. Alternative buff entries and class loading controls let you tailor the checks, while arrangement and raid-only visibility settings control how the reminder row appears.

![MangUI — Missing Raid Buff Tracking](Screenshots/16-MangUI-Missing-Raid-Buff-Tracking.png)

### 17. Common Item Tracking

Keep commonly used items in a configurable tracking row with optional creation spell entries. Class loading controls determine which entries apply to a character, and drag sorting sets their display order.

![MangUI — Common Item Tracking](Screenshots/17-MangUI-Common-Item-Tracking.png)

### 18. Range Tracking

Combine a numeric target range estimate with configurable distance warnings. Set class-specific spell or manual range checks, then adjust the text font, size, color, and friendly-target visibility to suit your setup.

![MangUI — Range Tracking](Screenshots/18-MangUI-Range-Tracking.png)

### 19. Threat Tracking

View target threat as a color-coded percentage with configurable font and size. Optional dungeon and raid visibility, guide line lengths, opacity, and label settings help place the indicator where it is easy to read.

![MangUI — Threat Tracking](Screenshots/19-MangUI-Threat-Tracking.png)

### 20. Chat and Utility Buttons

Bring chat channels and group utilities together in a compact button row. Adjust icon size, spacing, label font, and text offset, and configure the custom channel name and pull countdown duration.

![MangUI — Chat and Utility Buttons](Screenshots/20-MangUI-Chat-and-Utility-Buttons.png)

### 21. System Menu

Access a themed row of game shortcuts by moving the cursor to the top of the screen. The system menu module provides its own scale control so the shortcut icons can match the rest of your interface.

![MangUI — System Menu](Screenshots/21-MangUI-System-Menu.png)

### 22. Experience Bar

Follow level progress and rested experience with a slim experience bar and accompanying text. Adjust its scale, bar height, and font to keep leveling information visible without taking up a large area.

![MangUI — Experience Bar](Screenshots/22-MangUI-Experience-Bar.png)

### 23. Mouse Highlight

Make the cursor easier to locate with independently colored outer, inner, and global cooldown rings. Optional guide lines, text, and font controls let you match the mouse highlight to nearby interface elements.

![MangUI — Mouse Highlight](Screenshots/23-MangUI-Mouse-Highlight.png)

### 24. Combat Entry and Exit Alerts

Display a notification when entering or leaving combat, with adjustable module scale and optional sound alerts. The preview shows how the combat status message will appear within your layout.

![MangUI — Combat Entry and Exit Alerts](Screenshots/24-MangUI-Combat-Entry-and-Exit-Alerts.png)

### 25. General Settings

Choose the interface language and configure minimap access, display preferences, UI scaling, and font settings. The same page provides configuration import and export controls for transferring or sharing your setup.

![MangUI — General Settings](Screenshots/25-MangUI-General-Settings.png)
