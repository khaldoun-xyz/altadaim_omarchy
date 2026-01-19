# Khaldoun's install files

At [Khaldoun](https://khaldoun.xyz),
we rely on [Omarchy](https://omarchy.org/).

The `master-install.sh` file is the installer script to complement
your Omarchy setup with files necessary for your work at Khaldoun.

## Setup

- Run `gh auth login` in your terminal and follow the instructions.
- Clone this repository and run `. master-install.sh`.

## List of features

- Create a ssh key and add it to GitHub
- Install Cursor IDE
- Check your disk space with `ncdu` in the terminal
- Crop images with `gthumb`
- Install `pixi`
- Install Brave browser. You need to set it as default yourself.
- Install Brave extensions: YouTube blocker, Vimium.
  To use Vimium, press `f` on a browser page. For shortcuts, press `?`.
- Install LazyExtras lang.markdown.
- Add Lazyvim plugin for OpenCode (OC) integration. In Lazyvim, ask OC
  with `<leader>oa`. Execute a task in OC with `<leader>ox`.
  Toggle OC with `<leader>oo`.
- Update the clock in the top bar to display the time until the end of
  the current quarter.
- Run Dwarf Fortress by typing `dwarffortress` in the terminal
- Fix a bug in Omarchy that shows no packages to install in the official menu

## Installing Omarchy

If you're on a Framework laptop, do this:

- Plug in the USB stick with the Omarchy installation.
- Reboot your system. During bootup, press `F2` repeatedly until
  you get into the BIOS setup.
  - Go to the `Security` tab. Find `Secure Boot` and set it to `Disabled`.
  - Return to the overview and select `Boot Manager`
    (or a similar wording). - Select the USB drive.
- For general directions, see the official
  [Omarchy manual](https://learn.omacom.io/2/the-omarchy-manual/50/getting-started).
