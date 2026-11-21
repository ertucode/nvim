mod panes;
mod ui;
mod wifi_agent;

use std::fs;
use std::io::{Read, Write};
use std::os::fd::AsRawFd;
use std::os::unix::fs::{DirBuilderExt, OpenOptionsExt};
use std::os::unix::net::{UnixListener, UnixStream};
use std::path::PathBuf;
use std::process::Command;

use panes::{general, processes, tmux, wifi};
use rune::{AppSpec, Cx, El, col, icon, row, text};
use rune_theme_opencode::icons;

const WINDOW_SIZE: (f32, f32) = (900.0, 650.0);
const SIDEBAR_WIDTH: f32 = 210.0;
pub(crate) const GAME_POLICY: &str =
    "/Applications/Xcode.app/Contents/Developer/usr/bin/gamepolicyctl";

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Pane {
    General,
    Processes,
    Tmux,
    Wifi,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Route {
    Show,
    Quit,
    General,
    Processes,
    Tmux,
    TmuxDev,
    Wifi,
    WifiBest,
    GameOn,
    GameAuto,
}

impl Route {
    fn parse(value: &str) -> Option<Self> {
        match value.trim_start_matches('-') {
            "show" => Some(Self::Show),
            "quit" => Some(Self::Quit),
            "general" => Some(Self::General),
            "processes" | "kill-processes" => Some(Self::Processes),
            "tmux" | "tmux-all" => Some(Self::Tmux),
            "tmux-dev" | "tmux-on" => Some(Self::TmuxDev),
            "wifi" | "wi-fi" => Some(Self::Wifi),
            "wifi-best" | "wifi-strongest" => Some(Self::WifiBest),
            "game-on" => Some(Self::GameOn),
            "game-auto" => Some(Self::GameAuto),
            _ => None,
        }
    }

    fn command(self) -> &'static str {
        match self {
            Self::Show => "show",
            Self::Quit => "quit",
            Self::General => "general",
            Self::Processes => "processes",
            Self::Tmux => "tmux",
            Self::TmuxDev => "tmux-dev",
            Self::Wifi => "wifi",
            Self::WifiBest => "wifi-best",
            Self::GameOn => "game-on",
            Self::GameAuto => "game-auto",
        }
    }
}

pub(crate) struct AppState {
    pane: Pane,
    pub(crate) general: general::State,
    pub(crate) processes: processes::State,
    pub(crate) tmux: tmux::State,
    pub(crate) wifi: wifi::State,
    pub(crate) status: Option<(String, bool)>,
    pub(crate) handle: Option<rune::AppHandle<AppState>>,
}

impl AppState {
    fn new(route: Route, handle: Option<rune::AppHandle<AppState>>) -> Self {
        let mut state = Self {
            pane: Pane::General,
            general: general::State::new(),
            processes: processes::State::default(),
            tmux: tmux::State::default(),
            wifi: wifi::State::default(),
            status: None,
            handle,
        };
        state.apply_route(route);
        state
    }

    fn apply_route(&mut self, route: Route) {
        if route == Route::Show {
            return;
        }
        self.status = None;
        match route {
            Route::Show => unreachable!(),
            Route::Quit => {
                if let Some(handle) = &self.handle {
                    handle.quit();
                }
            }
            Route::General => self.select_pane(Pane::General),
            Route::Processes => {
                self.pane = Pane::Processes;
                self.processes.refresh();
            }
            Route::Tmux => {
                self.pane = Pane::Tmux;
                self.tmux.clear_selection();
                self.tmux.refresh();
            }
            Route::TmuxDev => {
                self.pane = Pane::Tmux;
                self.tmux.refresh();
                self.tmux.select_dev_windows();
            }
            Route::Wifi => self.select_pane(Pane::Wifi),
            Route::WifiBest => {
                self.pane = Pane::Wifi;
                self.status = self.wifi.refresh().err().map(|error| (error, true));
                if self.status.is_none() {
                    wifi::connect_strongest(self, true);
                }
            }
            Route::GameOn => {
                self.pane = Pane::General;
                self.status = set_game_mode(true).err().map(|error| (error, true));
                if self.status.is_none() {
                    self.status = self.general.refresh().err().map(|error| (error, true));
                }
            }
            Route::GameAuto => {
                self.pane = Pane::General;
                self.status = set_game_mode(false).err().map(|error| (error, true));
                if self.status.is_none() {
                    self.status = self.general.refresh().err().map(|error| (error, true));
                }
            }
        }
    }

    fn select_pane(&mut self, pane: Pane) {
        self.pane = pane;
        self.status = None;
        match pane {
            Pane::General => {
                self.status = self.general.refresh().err().map(|error| (error, true));
            }
            Pane::Processes if self.processes.is_empty() => self.processes.refresh(),
            Pane::Tmux => self.tmux.refresh(),
            Pane::Wifi => {
                self.status = self.wifi.refresh().err().map(|error| (error, true));
            }
            Pane::Processes => {}
        }
    }
}

fn set_game_mode(on: bool) -> Result<(), String> {
    run(
        GAME_POLICY,
        &["game-mode", "set", if on { "on" } else { "auto" }],
    )?;
    Ok(())
}

pub(crate) fn run(program: &str, args: &[&str]) -> Result<String, String> {
    let output = Command::new(program)
        .args(args)
        .output()
        .map_err(|error| error.to_string())?;
    if output.status.success() {
        return Ok(String::from_utf8_lossy(&output.stdout).trim().to_owned());
    }
    let stderr = String::from_utf8_lossy(&output.stderr).trim().to_owned();
    let stdout = String::from_utf8_lossy(&output.stdout).trim().to_owned();
    Err(if stderr.is_empty() { stdout } else { stderr })
}

fn socket_path() -> PathBuf {
    // LaunchServices and Karabiner need not inherit the same TMPDIR.
    PathBuf::from(std::env::var_os("HOME").expect("HOME is not set"))
        .join("Library/Caches/codes.ertu.macosUtils/control.sock")
}

fn instance_lock() -> std::io::Result<fs::File> {
    let path = socket_path();
    fs::DirBuilder::new()
        .recursive(true)
        .mode(0o700)
        .create(path.parent().unwrap())?;
    let file = fs::OpenOptions::new()
        .create(true)
        .truncate(false)
        .read(true)
        .write(true)
        .mode(0o600)
        .open(path.with_extension("lock"))?;
    // LOCK_EX | LOCK_NB. Keep this descriptor alive for the entire GUI lifetime.
    if unsafe { c_flock(file.as_raw_fd(), 2 | 4) } != 0 {
        return Err(std::io::Error::last_os_error());
    }
    Ok(file)
}

unsafe extern "C" {
    #[link_name = "getuid"]
    fn c_getuid() -> u32;
    #[link_name = "flock"]
    fn c_flock(fd: i32, operation: i32) -> i32;
}

pub(crate) fn libc_getuid() -> u32 {
    unsafe { c_getuid() }
}

fn send_to_running(route: Route) -> bool {
    let Ok(mut stream) = UnixStream::connect(socket_path()) else {
        return false;
    };
    stream.write_all(route.command().as_bytes()).is_ok()
}

fn setup(state: &mut AppState, _: rune::Waker) {
    let Some(handle) = state.handle.clone() else {
        return;
    };
    let wifi_handle = handle.clone();
    std::thread::spawn(move || {
        loop {
            std::thread::sleep(std::time::Duration::from_secs(2));
            wifi_handle.update_if(|state, _| {
                if state.pane != Pane::Wifi {
                    return false;
                }
                if state.wifi.location_permission_granted() || state.wifi.retry_signal_scan() {
                    state.status = state.wifi.refresh().err().map(|error| (error, true));
                    return true;
                }
                state.wifi.refresh_connection()
            });
        }
    });
    let path = socket_path();
    let _ = fs::remove_file(&path);
    let Ok(listener) = UnixListener::bind(path) else {
        return;
    };
    std::thread::spawn(move || {
        for mut stream in listener.incoming().flatten() {
            let mut command = String::new();
            if stream.read_to_string(&mut command).is_ok()
                && let Some(route) = Route::parse(command.trim())
            {
                handle.update(move |state, tx| {
                    state.apply_route(route);
                    tx.settle();
                });
                handle.open();
            }
        }
    });
}

fn view(state: &AppState, cx: &mut Cx<AppState>) -> El {
    let k = rune_theme_opencode::kit(cx.system_dark());
    let hair = 1.0 / cx.env().scale;
    let title = match state.pane {
        Pane::General => "General",
        Pane::Processes => "Processes",
        Pane::Tmux => "tmux",
        Pane::Wifi => "Wi-Fi",
    };
    let body = match state.pane {
        Pane::General => general::view(state, k, hair),
        Pane::Processes => processes::view(state, k, hair),
        Pane::Tmux => tmux::view(state, k, hair),
        Pane::Wifi => wifi::view(state, k, hair),
    };
    let panel = col()
        .key("panel")
        .role("main")
        .grow(1.0)
        .shrink()
        .h_full()
        .min_h(0.0)
        .mt(8.0)
        .mr(8.0)
        .mb(8.0)
        .radius(k.radius.lg)
        .fill(k.c.bg_base)
        .border(hair, k.c.border_weak)
        .padding(hair)
        .clip_soft(0.0)
        .child(header(k, title))
        .child(body);
    row()
        .key("window")
        .role("none")
        .w_full()
        .h_full()
        .fill(k.c.bg_deep)
        .child(sidebar(state, k))
        .child(panel)
}

fn header(k: &'static rune_kit::Kit, title: &str) -> El {
    row()
        .key("pane-header")
        .h(52.0)
        .px(32.0)
        .center_y()
        .window_drag()
        .child(
            text(title)
                .role("heading")
                .level(1)
                .font(k.ty.body_medium)
                .color(k.c.text_base),
        )
}

fn sidebar(state: &AppState, k: &'static rune_kit::Kit) -> El {
    col()
        .key("sidebar")
        .role("navigation")
        .w(SIDEBAR_WIDTH)
        .h_full()
        .pt(40.0)
        .pb(12.0)
        .pl(10.0)
        .pr(6.0)
        .gap(4.0)
        .window_drag()
        .child(nav_item(
            k,
            "General",
            &icons::STATUS,
            state.pane == Pane::General,
            Pane::General,
        ))
        .child(nav_item(
            k,
            "Processes",
            &icons::BULLET_LIST,
            state.pane == Pane::Processes,
            Pane::Processes,
        ))
        .child(nav_item(
            k,
            "tmux",
            &icons::TERMINAL,
            state.pane == Pane::Tmux,
            Pane::Tmux,
        ))
        .child(nav_item(
            k,
            "Wi-Fi",
            &icons::GLOBE,
            state.pane == Pane::Wifi,
            Pane::Wifi,
        ))
}

fn nav_item(
    k: &'static rune_kit::Kit,
    label: &str,
    glyph: &'static rune::Icon,
    selected: bool,
    pane: Pane,
) -> El {
    row()
        .key(label.to_lowercase())
        .role("listitem")
        .label(label)
        .focus_selected(selected)
        .h(28.0)
        .px(6.0)
        .gap(8.0)
        .center_y()
        .radius(k.radius.sm)
        .fill(if selected {
            k.c.layer_02
        } else {
            rune::Color::TRANSPARENT
        })
        .hover(k.c.hover)
        .press(k.c.pressed)
        .focusable(true)
        .on_press(move |state: &mut AppState| state.select_pane(pane))
        .child(
            icon(glyph, 16.0)
                .color(if selected {
                    k.c.icon_base
                } else {
                    k.c.icon_muted
                })
                .a11y_hidden(),
        )
        .child(
            text(label)
                .font(k.ty.ui)
                .color(if selected {
                    k.c.text_base
                } else {
                    k.c.text_muted
                })
                .a11y_hidden(),
        )
}

fn requested_route() -> Option<Route> {
    std::env::args().skip(1).find_map(|arg| Route::parse(&arg))
}

fn init() -> AppState {
    AppState::new(Route::General, None)
}

fn on_reopen(state: &mut AppState, _: bool, _: &mut rune::Tx) -> bool {
    state.status = None;
    match state.pane {
        Pane::General => {
            state.status = state.general.refresh().err().map(|error| (error, true));
        }
        Pane::Processes => state.processes.refresh(),
        Pane::Tmux => state.tmux.refresh(),
        Pane::Wifi => {
            state.status = state.wifi.refresh().err().map(|error| (error, true));
        }
    }
    false
}

fn main() {
    let requested = requested_route();
    let route = requested.unwrap_or(Route::Show);
    if std::env::args().any(|arg| arg == "--dispatch") {
        std::process::exit(if send_to_running(route) { 0 } else { 1 });
    }
    if send_to_running(route) {
        return;
    }
    if route == Route::Quit {
        return;
    }
    let _instance_lock = match instance_lock() {
        Ok(lock) => lock,
        Err(error) => {
            // Another instance may be starting and not have bound its socket
            // yet. Wait for it, never start a second GUI or unlink its socket.
            if error.kind() == std::io::ErrorKind::WouldBlock {
                for _ in 0..50 {
                    std::thread::sleep(std::time::Duration::from_millis(100));
                    if send_to_running(route) {
                        return;
                    }
                }
            }
            eprintln!("Could not contact or start macOS Utils: {error}");
            std::process::exit(1);
        }
    };
    let app = rune::App::new(AppSpec {
        fonts: rune_theme_opencode::FONTS,
        families: rune_theme_opencode::FAMILIES,
        setup: Some(setup),
        ..AppSpec::new("macOS Utils", WINDOW_SIZE, init, view)
    });
    let handle = app.handle();
    app.init(move || AppState::new(route, Some(handle)))
        .standard_menus()
        .on_reopen(on_reopen)
        .run();
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn show_preserves_the_selected_pane_and_status() {
        let mut state = AppState {
            pane: Pane::Wifi,
            general: general::State { game_on: false },
            processes: processes::State::default(),
            tmux: tmux::State::default(),
            wifi: wifi::State::default(),
            status: Some(("Keep this status".to_owned(), false)),
            handle: None,
        };
        state.apply_route(Route::Show);
        assert_eq!(state.pane, Pane::Wifi);
        assert_eq!(state.status, Some(("Keep this status".to_owned(), false)));
    }

    #[test]
    fn show_is_distinct_from_an_explicit_general_route() {
        assert_eq!(Route::parse("show"), Some(Route::Show));
        assert_eq!(Route::parse(Route::Show.command()), Some(Route::Show));
        assert_eq!(Route::parse("general"), Some(Route::General));
    }
}
