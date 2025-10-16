# FiveM Fingerprint Scanner

A simple and realistic fingerprint scanner script for FiveM. Works with ESX, ND_Core, and standalone setups. Features a handheld prop, NUI display, and Discord logging.

---

## Features

- Handheld fingerprint tablet prop
- Compatible with **ESX**, **ND_Core**, or **Standalone**
- Scans players for **name** and **date of birth (DOB)**
- Discord webhook logging of scans
- Test mode for self-scanning
- NUI display with auto-close
- Job-based access restrictions
- Easy to integrate into other scripts or menus
```TriggerEvent("fingerprint:openTablet")```

---

## Installation

1. Download or clone this repository into your `resources` folder.
2. Add the resource to your `server.cfg`:

```cfg
ensure ne_fprint
```