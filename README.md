# GNOME Appearance Toggle

A lightweight GNOME Shell extension that adds a panel button to switch between Light and Dark appearance, either manually (right now) or with GNOME Night Light (on a schedule). This allows all your appearance-aware apps (your browser or IDE, etc) to follow suit.

## Features

- Toggle now — manually switch between Light and Dark appearance
- Follow Night Light — optionally synchronize the appearance with GNOME Night Light
- The Follow Night Light preference is persisted across extension reloads and sessions
- Uses the native GNOME GSettings and D-Bus APIs
- Event-driven Night Light monitoring via a D-Bus proxy — no polling or timers
- Lightweight, with no external dependencies

## Technologies

- JavaScript (GJS)
- GNOME Shell Extensions
- Gio / GSettings
- D-Bus
- GNOME 42
- Ubuntu 22.04 LTS

## Roadmap

- [x] Manual Light/Dark toggle
- [x] Automatic synchronization with GNOME Night Light
- [x] Menu with Toggle Now and Follow Night Light
- [x] Persist Follow Night Light preference
- [ ] Publish on extensions.gnome.org

## Installation

Coming soon

## Licence

MIT
