use std::collections::HashMap;

use rune::{El, ScrollSpec, col, el, row, text};
use rune_kit::{Button, ButtonVariant, ControlSize};

use crate::{AppState, run, ui, wifi_agent};

const NETWORK_SETUP: &str = "/usr/sbin/networksetup";

struct Network {
    name: String,
    rssi: Option<isize>,
    connected: bool,
    requires_password: bool,
}

#[derive(Default)]
pub(crate) struct State {
    device: Option<String>,
    networks: Vec<Network>,
    signal_available: bool,
    waiting_for_location: bool,
    signal_retries: u8,
    connection_attempt: u64,
    connecting: Option<(u64, String)>,
    password_access_needed: Option<String>,
}

impl State {
    pub(crate) fn refresh(&mut self) -> Result<(), String> {
        let device = wifi_device()?;
        let known = known_networks(&device)?;
        let (scan, scan_error) = match scan_networks() {
            Ok(scan) => (scan, None),
            Err(error) => (HashMap::new(), Some(error)),
        };
        let current = current_network(&device);
        self.device = Some(device);
        self.signal_available = scan_error.is_none();
        self.waiting_for_location = scan_error.is_some() && !location_authorized();
        if self.signal_available {
            self.signal_retries = 0;
        }
        self.networks = known
            .into_iter()
            .map(|name| {
                let result = scan.get(&name);
                Network {
                    requires_password: result.is_none_or(|result| result.requires_password),
                    rssi: result.map(|result| result.rssi),
                    connected: result.is_some_and(|result| result.connected)
                        || current.as_ref() == Some(&name),
                    name,
                }
            })
            .collect();
        self.networks.sort_by_key(|network| {
            (
                std::cmp::Reverse(network.connected),
                std::cmp::Reverse(network.rssi),
            )
        });
        scan_error.map_or(Ok(()), Err)
    }

    pub(crate) fn location_permission_granted(&self) -> bool {
        self.waiting_for_location && location_authorized()
    }

    pub(crate) fn retry_signal_scan(&mut self) -> bool {
        // A newly launched process can have an authorized CLLocationManager
        // before CoreWLAN stops redacting SSIDs. Do not leave that first
        // transient scan error on screen forever, or scan endlessly on errors.
        if !self.signal_available && location_authorized() && self.signal_retries < 3 {
            self.signal_retries += 1;
            return true;
        }
        false
    }

    pub(crate) fn refresh_connection(&mut self) -> bool {
        let Some(device) = self.device.as_deref() else {
            return false;
        };
        let current = current_network(device);
        let mut changed = false;
        for network in &mut self.networks {
            let connected = current.as_ref() == Some(&network.name);
            changed |= network.connected != connected;
            network.connected = connected;
        }
        changed
    }

    fn strongest_alternative(&self) -> Option<&Network> {
        let current_rssi = self
            .networks
            .iter()
            .find(|network| network.connected)
            .and_then(|network| network.rssi);
        self.networks
            .iter()
            .filter(|network| !network.connected)
            .filter(|network| {
                network
                    .rssi
                    .is_some_and(|rssi| current_rssi.is_none_or(|current| rssi > current))
            })
            .max_by_key(|network| network.rssi)
    }
}

fn begin_connect(app: &mut AppState, name: String, quit_after_success: bool) {
    let Some(device) = app.wifi.device.clone() else {
        app.status = Some(("Wi-Fi interface is unavailable".to_owned(), true));
        return;
    };
    let Some(handle) = app.handle.clone() else {
        app.status = Some(("Could not start the Wi-Fi connection".to_owned(), true));
        return;
    };
    app.wifi.connection_attempt = app.wifi.connection_attempt.wrapping_add(1);
    let attempt = app.wifi.connection_attempt;
    app.wifi.connecting = Some((attempt, name.clone()));
    app.wifi.password_access_needed = None;
    app.status = Some((format!("Connecting to {name}…"), false));
    let requires_password = app
        .wifi
        .networks
        .iter()
        .find(|network| network.name == name)
        .is_none_or(|network| network.requires_password);
    std::thread::spawn(move || {
        let result = wifi_agent::connect(&device, &name, requires_password);
        let password_access_needed = result
            .as_ref()
            .is_err_and(|error| error.needs_authorization);
        let mut current = current_network(&device);
        if result.is_ok() {
            for _ in 0..20 {
                if current.as_ref() == Some(&name) {
                    break;
                }
                std::thread::sleep(std::time::Duration::from_millis(500));
                current = current_network(&device);
            }
        }
        let status = match result {
            Err(error) => (
                format!("Could not connect to {name}: {}", error.message),
                true,
            ),
            Ok(_) if current.as_ref() == Some(&name) => (format!("Connected to {name}"), false),
            Ok(_) => {
                let detail = current.map_or_else(
                    || "no Wi-Fi network is connected".to_owned(),
                    |ssid| format!("still connected to {ssid}"),
                );
                (format!("Could not connect to {name}: {detail}"), true)
            }
        };
        handle.update(move |app, tx| {
            if !matches!(app.wifi.connecting.as_ref(), Some((id, target)) if *id == attempt && target == &name)
            {
                return;
            }
            app.wifi.connecting = None;
            app.wifi.password_access_needed = password_access_needed.then_some(name.clone());
            app.wifi.refresh_connection();
            let succeeded = !status.1;
            app.status = Some(status);
            if succeeded && quit_after_success {
                tx.quit();
            }
        });
    });
}

pub(crate) fn connect_strongest(app: &mut AppState, quit_after_success: bool) {
    if let Some(name) = app
        .wifi
        .strongest_alternative()
        .map(|network| network.name.clone())
    {
        begin_connect(app, name, quit_after_success);
    } else {
        app.status = Some((
            "The current network already has the strongest signal".to_owned(),
            false,
        ));
        if quit_after_success
            && app.wifi.networks.iter().any(|network| network.connected)
            && let Some(handle) = app.handle.clone()
        {
            handle.quit();
        }
    }
}

pub(crate) fn view(app: &AppState, k: &'static rune_kit::Kit, hair: f32) -> El {
    let strongest = app.wifi.strongest_alternative();
    let action_label = if strongest.is_some() {
        "Switch to strongest"
    } else {
        "Already on strongest"
    };
    let strongest_action = Button::new(action_label)
        .variant(ButtonVariant::Submit)
        .control_size(ControlSize::Large)
        .disabled(strongest.is_none())
        .on_press(|app: &mut AppState| {
            connect_strongest(app, false);
        })
        .build(k);
    let refresh = Button::new("Refresh")
        .variant(ButtonVariant::GhostMuted)
        .control_size(ControlSize::Large)
        .on_press(|app: &mut AppState| {
            app.status = app.wifi.refresh().err().map(|error| (error, true));
        })
        .build(k);
    let header = row()
        .h(36.0)
        .center_y()
        .child(ui::section_label(k, "Known networks").grow(1.0))
        .child(refresh)
        .child(strongest_action.ml(8.0));

    let mut list = col().key("wifi-list");
    for (index, network) in app.wifi.networks.iter().enumerate() {
        if index > 0 {
            list = list.child(ui::separator(k, hair));
        }
        let name = network.name.clone();
        let signal = if !app.wifi.signal_available {
            "Signal unavailable".to_owned()
        } else {
            network.rssi.map_or_else(
                || "Out of range".to_owned(),
                |rssi| format!("{}%  ({rssi} dBm)", signal_percent(rssi)),
            )
        };
        let strength = network.rssi.map(signal_percent).unwrap_or_default() as f32 / 100.0;
        let meter = row()
            .w(64.0)
            .h(4.0)
            .mr(12.0)
            .radius(2.0)
            .fill(k.c.border_weak)
            .child(
                el().w(64.0 * strength)
                    .h_full()
                    .radius(2.0)
                    .fill(k.c.success.fg),
            )
            .a11y_hidden();
        list = list.child(
            row()
                .key(format!("wifi-{name}"))
                .role("button")
                .label(format!("Double-click to connect to {name}"))
                .h(52.0)
                .px(16.0)
                .center_y()
                .hover(if network.connected {
                    rune::Color::TRANSPARENT
                } else {
                    k.c.hover
                })
                .press(if network.connected {
                    rune::Color::TRANSPARENT
                } else {
                    k.c.pressed
                })
                .focusable(!network.connected)
                .on_double_press(move |app: &mut AppState| {
                    if !app
                        .wifi
                        .networks
                        .iter()
                        .any(|item| item.name == name && item.connected)
                    {
                        begin_connect(app, name.clone(), false);
                    }
                })
                .child(meter)
                .child(
                    col()
                        .grow(1.0)
                        .shrink()
                        .gap(2.0)
                        .child(
                            text(network.name.clone())
                                .font(k.ty.ui_medium)
                                .color(k.c.text_base)
                                .truncate(),
                        )
                        .children(
                            network
                                .connected
                                .then(|| text("Connected").font(k.ty.small).color(k.c.success.fg)),
                        ),
                )
                .child(
                    text(signal)
                        .font(k.ty.small)
                        .color(if network.rssi.is_some() {
                            k.c.text_muted
                        } else {
                            k.c.text_faint
                        }),
                ),
        );
    }
    if app.wifi.networks.is_empty() {
        list = list.child(
            row().h(100.0).center().child(
                text("No known Wi-Fi networks")
                    .font(k.ty.ui)
                    .color(k.c.text_faint),
            ),
        );
    }
    let status = ui::status(app.status.as_ref(), k).map(|banner| {
        if !app.wifi.waiting_for_location {
            banner
        } else {
            banner
                .role("button")
                .label("Open Location Services settings")
                .focusable(true)
                .hover(k.c.hover)
                .press(k.c.pressed)
                .on_press(|app: &mut AppState| {
                    if let Err(error) = open_location_settings() {
                        app.status = Some((
                            format!("Could not open Location Services settings: {error}"),
                            true,
                        ));
                    }
                })
        }
    });
    // Import is deliberately separate from connecting. System Wi-Fi secrets
    // may require authentication once; ordinary switches must never ask.
    let authorize = app.wifi.password_access_needed.as_ref().map(|name| {
        let name = name.clone();
        Button::new("Authorize saved password once…")
            .variant(ButtonVariant::GhostMuted)
            .on_press(move |app: &mut AppState| {
                let Some(handle) = app.handle.clone() else {
                    return;
                };
                let name = name.clone();
                app.wifi.password_access_needed = None;
                app.status = Some(("Waiting for your Keychain approval…".to_owned(), false));
                std::thread::spawn(move || {
                    let result = wifi_agent::authorize(&name);
                    handle.update(move |app, _| match result {
                        Ok(()) => begin_connect(app, name, false),
                        Err(error) => app.status = Some((error, true)),
                    });
                });
            })
            .build(k)
    });

    ui::page(k)
        .gap(8.0)
        .child(header)
        .child(
            ui::card(k, list, hair)
                .grow(1.0)
                .min_h(0.0)
                .scroll(ScrollSpec {
                    stick_bottom: false,
                }),
        )
        .children(status)
        .children(authorize)
}

fn open_location_settings() -> Result<(), String> {
    run(
        "/usr/bin/open",
        &["x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices"],
    )?;
    Ok(())
}

fn wifi_device() -> Result<String, String> {
    let output = run(NETWORK_SETUP, &["-listallhardwareports"])?;
    let mut wifi = false;
    for line in output.lines() {
        if let Some(port) = line.strip_prefix("Hardware Port: ") {
            wifi = port == "Wi-Fi" || port == "AirPort";
        } else if wifi && let Some(device) = line.strip_prefix("Device: ") {
            return Ok(device.to_owned());
        }
    }
    Err("No Wi-Fi interface was found".to_owned())
}

fn known_networks(device: &str) -> Result<Vec<String>, String> {
    let output = run(NETWORK_SETUP, &["-listpreferredwirelessnetworks", device])?;
    Ok(output
        .lines()
        .skip(1)
        .map(|line| line.strip_prefix('\t').unwrap_or(line))
        .filter(|name| !name.is_empty())
        .map(str::to_owned)
        .collect())
}

fn current_network(device: &str) -> Option<String> {
    run("/usr/sbin/ipconfig", &["getsummary", device])
        .ok()?
        .lines()
        .find_map(|line| line.trim_start().strip_prefix("SSID : ").map(str::to_owned))
}

fn signal_percent(rssi: isize) -> isize {
    ((rssi + 100) * 2).clamp(0, 100)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn signal_percentage_is_bounded() {
        assert_eq!(signal_percent(-120), 0);
        assert_eq!(signal_percent(-75), 50);
        assert_eq!(signal_percent(-40), 100);
    }

    #[test]
    fn strongest_requires_a_strictly_better_visible_network() {
        let mut state = State::default();
        state.networks = vec![
            Network {
                name: "current".into(),
                requires_password: true,
                rssi: Some(-60),
                connected: true,
            },
            Network {
                name: "equal".into(),
                requires_password: true,
                rssi: Some(-60),
                connected: false,
            },
            Network {
                name: "unknown".into(),
                requires_password: true,
                rssi: None,
                connected: false,
            },
        ];
        assert!(state.strongest_alternative().is_none());
        state.networks.push(Network {
            name: "better".into(),
            requires_password: true,
            rssi: Some(-50),
            connected: false,
        });
        assert_eq!(state.strongest_alternative().unwrap().name, "better");
    }
}

struct ScanResult {
    rssi: isize,
    connected: bool,
    requires_password: bool,
}

#[cfg(target_os = "macos")]
fn scan_networks() -> Result<HashMap<String, ScanResult>, String> {
    corewlan::scan()
}

#[cfg(target_os = "macos")]
fn location_authorized() -> bool {
    corewlan::location_authorized()
}

#[cfg(not(target_os = "macos"))]
fn scan_networks() -> Result<HashMap<String, ScanResult>, String> {
    Ok(HashMap::new())
}

#[cfg(not(target_os = "macos"))]
fn location_authorized() -> bool {
    false
}

#[cfg(target_os = "macos")]
mod corewlan {
    use std::collections::HashMap;
    use std::ffi::{CStr, c_char, c_void};
    use std::sync::atomic::{AtomicPtr, Ordering};

    use super::ScanResult;

    type Id = *mut c_void;
    type Sel = *mut c_void;

    #[link(name = "CoreWLAN", kind = "framework")]
    unsafe extern "C" {}

    #[link(name = "CoreLocation", kind = "framework")]
    unsafe extern "C" {}

    #[link(name = "objc")]
    unsafe extern "C" {
        fn objc_getClass(name: *const c_char) -> Id;
        fn sel_registerName(name: *const c_char) -> Sel;
        fn objc_msgSend();
    }

    unsafe fn selector(name: &'static [u8]) -> Sel {
        unsafe { sel_registerName(name.as_ptr().cast()) }
    }

    unsafe fn send_id(object: Id, selector: Sel) -> Id {
        let function: unsafe extern "C" fn(Id, Sel) -> Id =
            unsafe { std::mem::transmute(objc_msgSend as *const ()) };
        unsafe { function(object, selector) }
    }

    unsafe fn send_void(object: Id, selector: Sel) {
        let function: unsafe extern "C" fn(Id, Sel) =
            unsafe { std::mem::transmute(objc_msgSend as *const ()) };
        unsafe { function(object, selector) }
    }

    unsafe fn send_usize(object: Id, selector: Sel) -> usize {
        let function: unsafe extern "C" fn(Id, Sel) -> usize =
            unsafe { std::mem::transmute(objc_msgSend as *const ()) };
        unsafe { function(object, selector) }
    }

    unsafe fn send_index(object: Id, selector: Sel, index: usize) -> Id {
        let function: unsafe extern "C" fn(Id, Sel, usize) -> Id =
            unsafe { std::mem::transmute(objc_msgSend as *const ()) };
        unsafe { function(object, selector, index) }
    }

    unsafe fn send_scan(object: Id, selector: Sel, error: *mut Id) -> Id {
        let function: unsafe extern "C" fn(Id, Sel, Id, *mut Id) -> Id =
            unsafe { std::mem::transmute(objc_msgSend as *const ()) };
        unsafe { function(object, selector, std::ptr::null_mut(), error) }
    }

    unsafe fn send_isize(object: Id, selector: Sel) -> isize {
        let function: unsafe extern "C" fn(Id, Sel) -> isize =
            unsafe { std::mem::transmute(objc_msgSend as *const ()) };
        unsafe { function(object, selector) }
    }

    unsafe fn send_i32(object: Id, selector: Sel) -> i32 {
        let function: unsafe extern "C" fn(Id, Sel) -> i32 =
            unsafe { std::mem::transmute(objc_msgSend as *const ()) };
        unsafe { function(object, selector) }
    }

    unsafe fn string(object: Id) -> Option<String> {
        if object.is_null() {
            return None;
        }
        let pointer = unsafe { send_id(object, selector(b"UTF8String\0")) } as *const c_char;
        (!pointer.is_null()).then(|| {
            unsafe { CStr::from_ptr(pointer) }
                .to_string_lossy()
                .into_owned()
        })
    }

    static LOCATION_MANAGER: AtomicPtr<c_void> = AtomicPtr::new(std::ptr::null_mut());

    unsafe fn location_manager() -> Id {
        let mut manager = LOCATION_MANAGER.load(Ordering::Acquire);
        if manager.is_null() {
            let class = unsafe { objc_getClass(c"CLLocationManager".as_ptr()) };
            let new_manager =
                unsafe { send_id(send_id(class, selector(b"alloc\0")), selector(b"init\0")) };
            match LOCATION_MANAGER.compare_exchange(
                std::ptr::null_mut(),
                new_manager,
                Ordering::AcqRel,
                Ordering::Acquire,
            ) {
                Ok(_) => manager = new_manager,
                Err(existing) => {
                    unsafe { send_void(new_manager, selector(b"release\0")) };
                    manager = existing;
                }
            }
        }
        manager
    }

    unsafe fn require_location_authorization() -> Result<(), String> {
        let manager = unsafe { location_manager() };
        let status = unsafe { send_i32(manager, selector(b"authorizationStatus\0")) };
        match status {
            3 | 4 => Ok(()),
            0 => {
                unsafe { send_void(manager, selector(b"requestAlwaysAuthorization\0")) };
                // locationd may already have a persisted grant while this
                // newly-created manager still reports not-determined. Let
                // CoreWLAN perform the authoritative access check.
                Ok(())
            }
            _ => Err("Location Access is disabled. Click here to open Location Services and enable macOS Utils"
                .to_owned()),
        }
    }

    pub(super) fn location_authorized() -> bool {
        unsafe {
            // The instance value is initially cached as not-determined while
            // locationd registers the process. The class query reflects the
            // persisted authorization once registration completes.
            let class = objc_getClass(c"CLLocationManager".as_ptr());
            matches!(send_i32(class, selector(b"authorizationStatus\0")), 3 | 4)
        }
    }

    pub(super) fn scan() -> Result<HashMap<String, ScanResult>, String> {
        unsafe {
            let pool_class = objc_getClass(c"NSAutoreleasePool".as_ptr());
            let pool = send_id(
                send_id(pool_class, selector(b"alloc\0")),
                selector(b"init\0"),
            );
            if let Err(error) = require_location_authorization() {
                send_void(pool, selector(b"drain\0"));
                return Err(error);
            }
            let client_class = objc_getClass(c"CWWiFiClient".as_ptr());
            let client = send_id(client_class, selector(b"sharedWiFiClient\0"));
            let interface = send_id(client, selector(b"interface\0"));
            if interface.is_null() {
                send_void(pool, selector(b"drain\0"));
                return Err("No Wi-Fi interface was found".to_owned());
            }
            let current = string(send_id(interface, selector(b"ssid\0")));
            let mut error: Id = std::ptr::null_mut();
            let set = send_scan(
                interface,
                selector(b"scanForNetworksWithName:error:\0"),
                &mut error,
            );
            if set.is_null() {
                let message = if error.is_null() {
                    "Could not scan Wi-Fi networks".to_owned()
                } else {
                    string(send_id(error, selector(b"localizedDescription\0")))
                        .unwrap_or_else(|| "Could not scan Wi-Fi networks".to_owned())
                };
                send_void(pool, selector(b"drain\0"));
                return Err(message);
            }
            let items = send_id(set, selector(b"allObjects\0"));
            let mut results: HashMap<String, ScanResult> = HashMap::new();
            let mut unnamed = 0;
            for index in 0..send_usize(items, selector(b"count\0")) {
                let network = send_index(items, selector(b"objectAtIndex:\0"), index);
                let Some(name) = string(send_id(network, selector(b"ssid\0"))) else {
                    unnamed += 1;
                    continue;
                };
                let rssi = send_isize(network, selector(b"rssiValue\0"));
                let entry = results.entry(name.clone()).or_insert(ScanResult {
                    rssi,
                    connected: current.as_ref() == Some(&name),
                    requires_password: {
                        let supports: unsafe extern "C" fn(Id, Sel, isize) -> bool =
                            std::mem::transmute(objc_msgSend as *const ());
                        !supports(network, selector(b"supportsSecurity:\0"), 0)
                    },
                });
                entry.rssi = entry.rssi.max(rssi);
            }
            send_void(pool, selector(b"drain\0"));
            if results.is_empty() && unnamed > 0 {
                return Err("Location Access is required for Wi-Fi strengths. Click here to open Location Services"
                    .to_owned());
            }
            Ok(results)
        }
    }
}
