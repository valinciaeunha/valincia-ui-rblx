<div align="center">

<img src="https://img.shields.io/badge/Valincia_UI-Library-6082FF?style=for-the-badge&labelColor=1a1a2e" alt="Valincia UI"/>

# Valincia UI Library

**Modern. Minimal. Powerful.**

A single-file loadstring-compatible UI library for Roblox executors, crafted with obsessive attention to detail.

[![Version](https://img.shields.io/badge/version-1.0.0-6082FF.svg?style=flat-square)](https://github.com/valinciaeunha/valincia-ui-rblx)
[![Lua](https://img.shields.io/badge/lua-5.1+-2C2D72.svg?style=flat-square&logo=lua&logoColor=white)](https://www.lua.org)
[![License](https://img.shields.io/badge/license-MIT-22c55e.svg?style=flat-square)](LICENSE)
[![Stars](https://img.shields.io/github/stars/valinciaeunha/valincia-ui-rblx?style=flat-square&color=f59e0b)](https://github.com/valinciaeunha/valincia-ui-rblx/stargazers)

---

*"Valincia was born from a simple belief: building something powerful shouldn't require something complicated.*
*Every line of this library was written so you can focus on what matters -- your script, your vision, your creation.*
*No bloat. No unnecessary abstraction. Just clean, elegant tools that get out of your way and let you build."*

**-- valinciaeunha**

</div>

---

## Why Valincia?

Most UI libraries make you choose: **simplicity** or **power**. Valincia gives you both.

| | What You Get |
|:---:|---------|
| **One File** | Single `Library.lua` -- no dependencies, no build steps, just loadstring and go |
| **Beautiful by Default** | Dark theme, smooth animations, rounded corners, and proper spacing out of the box |
| **14+ Elements** | Toggles, sliders, dropdowns, color pickers, viewports, images, videos, and more |
| **Addon System** | SaveManager for configs, ThemeManager for themes -- plug in only what you need |
| **Key System** | Built-in key validation with API support, local caching, and auto-expiry |
| **Executor Friendly** | Works across major executors with proper guards and fallbacks |
| **Resizable Windows** | Drag to resize -- your UI, your layout |
| **Smart Dropdowns** | Built-in search bar for long option lists |

---

## Quick Start

Three lines. That's all it takes.

```lua
local repo = "https://raw.githubusercontent.com/valinciaeunha/valincia-ui-rblx/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
```

Then create your first window:

```lua
local Window = Library:CreateWindow({
    Title = "My Script",
    Footer = "v1.0.0",
    Center = true,
    AutoShow = true,
})

local Tabs = {
    Main = Window:AddTab("Main"),
    Settings = Window:AddTab("Settings"),
}

local MainGroup = Tabs.Main:AddGroupbox("Features")
MainGroup:AddToggle("AutoFarm", { Text = "Auto Farm", Default = false })
MainGroup:AddSlider("Speed", { Text = "Speed", Default = 16, Min = 0, Max = 200, Rounding = 0 })

-- Save & Theme (optional)
SaveManager:SetLibrary(Library)
SaveManager:SetFolder("MyScript")
SaveManager:BuildConfigSection(Tabs.Settings)

ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder("MyScript")
ThemeManager:ApplyToTab(Tabs.Settings)

SaveManager:LoadAutoloadConfig()
```

> For the full API reference and all available elements, see **[docs.md](docs.md)**.

---

## Features at a Glance

### UI Elements

| Element | Description |
|---------|-------------|
| `AddToggle` | On/off switch with callback |
| `AddSlider` | Draggable value slider with min/max/rounding |
| `AddDropdown` | Single or multi-select dropdown with search |
| `AddInput` | Text input field with placeholder |
| `AddKeybind` | Key binding selector |
| `AddButton` | Clickable button |
| `AddButtonRow` | Multiple buttons in a row |
| `AddLabel` | Static or dynamic text |
| `AddDivider` | Visual separator |
| `AddColorPicker` | Color selection wheel |
| `AddCheckbox` | Checkbox (alias for Toggle) |
| `AddImage` | Display Roblox image assets |
| `AddVideo` | Embedded video player |
| `AddViewport` | 3D model viewer |

### Addons

| Addon | Description |
|-------|-------------|
| **SaveManager** | Save/load configurations to JSON, auto-load on startup |
| **ThemeManager** | 4 built-in themes (Dark, Light, Mocha, Ocean) + custom themes |

### Key System

| Feature | Description |
|---------|-------------|
| Multi-format | Supports JSON API, JSON array, plain text key list, and local keys |
| Auto-save | Validated keys are cached locally with timestamp |
| Configurable expiry | Set key validity duration in hours |
| Case-insensitive | `test-key` and `TEST-KEY` are treated as the same |

---

## Project Structure

```
valincia-ui-rblx/
|
|-- Library.lua              Core library (~1900 lines, single file)
|-- Example.lua              Full demo of all UI elements
|-- KeySystemExample.lua     Key system with API + auto-save
|-- docs.md                  Complete API documentation
|-- README.md                You are here
|-- LICENSE                  MIT License
|
|-- addons/
    |-- SaveManager.lua      Config save/load
    |-- ThemeManager.lua     Theme management
```

---

## Documentation

| Document | Description |
|----------|-------------|
| **[docs.md](docs.md)** | Complete API reference with code examples for every element |
| **[Example.lua](Example.lua)** | Working example script demonstrating all features |
| **[KeySystemExample.lua](KeySystemExample.lua)** | Key system implementation example |

---

## Design Philosophy

Valincia was built around three core principles:

1. **Simplicity** -- If it takes more than 3 lines to add an element, it's too complicated. Every function follows the same pattern: call, configure, done.

2. **Zero configuration** -- Load the library and it works. No setup, no initialization steps, no configuration files required. Addons are optional, never mandatory.

3. **Beauty without effort** -- The default theme, spacing, animations, and typography are carefully tuned so your UI looks professional without any custom styling.

---

## Contributing

Contributions are welcome. Whether it's a bug fix, new feature, or documentation improvement:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m "feat: add amazing feature"`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

Please keep your code consistent with the existing style. All UI elements follow the same pattern: create container, build visuals, wire events, register flag, return object.

---

## Credits

<div align="center">

**Created and maintained by** [valinciaeunha](https://github.com/valinciaeunha)

Inspired by the simplicity of LinoriaLib and the elegance of modern UI design.
Built from scratch with love for the Roblox scripting community.

Special thanks to everyone who uses, tests, and provides feedback.
Your input shapes this library into something better every day.

---

**If Valincia helped your project, consider giving it a star.**

[![Star](https://img.shields.io/github/stars/valinciaeunha/valincia-ui-rblx?style=social)](https://github.com/valinciaeunha/valincia-ui-rblx)

</div>

---

## License

This project is licensed under the **MIT License** -- see the [LICENSE](LICENSE) file for details.

You are free to use, modify, and distribute Valincia UI in your projects, commercial or otherwise. Attribution is appreciated but not required.

---

<div align="center">

**Built with precision. Designed for simplicity.**

*Valincia UI Library -- making beautiful UIs effortless.*

Copyright (c) 2025-2026 valinciaeunha. All rights reserved.

</div>
