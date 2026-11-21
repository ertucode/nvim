# macOS Utils

A native macOS utility window built with [Rune](https://github.com/anomalyco/rune) and the visual language used by [Hex](https://github.com/anomalyco/hex).

## Build and install

Installation uses the `macOS Utils Local Signing` identity from the login
keychain so macOS privacy permissions survive rebuilds. Set
`MACOS_UTILS_SIGNING_IDENTITY` to use another Code Signing identity.

```sh
./install.sh
open "$HOME/Applications/macOS Utils.app"
```

The installer puts a launcher at `~/.local/bin/macos-utils`. It sends commands to
an existing window, or starts the app through LaunchServices (not the bundle's
executable directly). This also applies to Karabiner shortcuts: direct binary
launches can lose the app's Location Services attribution.

Commands focus an existing window or launch a new one:

```sh
macos-utils            # Show the existing window without changing its pane
macos-utils show       # Same behavior; used by Option+M
macos-utils general
macos-utils processes
macos-utils tmux
macos-utils wifi
macos-utils wifi-best
macos-utils tmux-dev
macos-utils game-on
macos-utils game-auto
```

Only explicit pane commands (such as `general` or `wifi`) change the selected
pane. A per-user lock prevents concurrent launches from creating another GUI;
the control socket lives at a stable path independent of the launcher's TMPDIR.

`tmux-dev` opens tmux with the `nvim` and `opencode` windows selected. `processes` opens General at the native process picker.

## Wi-Fi permissions and the stable helper

Self-signed Keychain entries contain a **cdhash partition** as well as the
certificate requirement. Rebuilding the credential-owning executable changes
its cdhash; keeping the signing certificate alone does not preserve access.

The installer therefore builds/signs `wifi-keychain` **only on its first
installation**, at `~/Library/Application Support/macOS Utils/wifi-keychain`.
Subsequent `make install-macos-utils` runs verify and keep that exact executable:
they never rebuild, copy over, or re-sign it. It is outside the GUI app bundle.

The helper owns a separate login Keychain cache. For each secured network,
click **Authorize saved password once…** once to initialize its access. This
one-time migration from the old GUI-owned cache can require macOS approval.
GUI rebuilds then do not change the credential owner's hash or access.
Ordinary connections disable Keychain interaction and never automatically
request approval. A locked Keychain, revoked access, or a missing entry produces
an error rather than a prompt. Open networks need no cached password.

The helper performs the join itself using `networksetup`, passing the password
through stdin, never command-line arguments. It returns status only; the GUI
does not read, receive, or log the password. Location access for signal scanning
remains with the GUI. The helper does not need location access or root.

If the helper itself must be upgraded, treat that as an explicit credential
owner migration: authorization may be needed again. Normal GUI installation
intentionally does not upgrade it. Code-signing private-key approval during a
build is separate from Wi-Fi access; allow `/usr/bin/codesign` persistently in
Keychain Access if desired, rather than removing application signing.
