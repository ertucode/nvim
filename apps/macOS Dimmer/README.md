# macOS Dimmer

A minimal combined brightness controller for macOS. It lowers the built-in
display's hardware brightness to its first notch, then places a click-through
black overlay over every display for further dimming. The software dimming
level is stored between launches.

The macOS setup script builds and installs the app at:

```text
~/Applications/macOS Dimmer.app
```

## Commands

Commands are sent through the app's URL scheme:

```sh
open 'macos-dimmer://decrease'
open 'macos-dimmer://increase'
open 'macos-dimmer://reset'
open 'macos-dimmer://quit'
```

`decrease` lowers hardware brightness in normal macOS steps until the first
notch, then darkens the displays in 20% software steps. `increase` removes the
software dimming first, then raises hardware brightness. The app caps overlay
opacity at 90% so the desktop cannot become completely invisible.

A centered dark, translucent HUD uses the macOS sun symbol and a 16-segment
brightness bar. Hardware brightness maps directly to the bar, while software
dimming partially drains the first notch below the hardware minimum. The
dimming windows stay above the macOS app switcher and remain click-through.

The Karabiner shortcuts fall back to macOS's fine system-brightness keys if the
URL scheme cannot be opened.

Holding a brightness shortcut performs one adjustment immediately, waits 400
milliseconds, then repeats every 150 milliseconds until the key is released.
