use std::collections::BTreeSet;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

use rune::{El, ScrollSpec, col, el, icon, row, text};
use rune_kit::{Button, ButtonVariant, Checkbox, ControlSize};
use rune_theme_opencode::icons;

use crate::{AppState, libc_getuid, ui};

struct Session {
    name: String,
    windows: usize,
    attached: usize,
}

struct Window {
    id: String,
    session: String,
    index: usize,
    name: String,
}

#[derive(Default)]
pub(crate) struct State {
    sessions: Vec<Session>,
    windows: Vec<Window>,
    selected_sessions: BTreeSet<String>,
    selected_windows: BTreeSet<String>,
    socket: Option<PathBuf>,
    error: Option<String>,
}

impl State {
    pub(crate) fn refresh(&mut self) {
        match list() {
            Ok((sessions, windows, socket)) => {
                self.sessions = sessions;
                self.windows = windows;
                self.socket = socket;
                self.error = None;
            }
            Err(error) => {
                self.sessions.clear();
                self.windows.clear();
                self.socket = None;
                self.error = Some(error);
            }
        }
        self.selected_sessions
            .retain(|name| self.sessions.iter().any(|session| &session.name == name));
        self.selected_windows
            .retain(|id| self.windows.iter().any(|window| &window.id == id));
    }

    pub(crate) fn clear_selection(&mut self) {
        self.selected_sessions.clear();
        self.selected_windows.clear();
    }

    pub(crate) fn select_dev_windows(&mut self) {
        self.selected_sessions.clear();
        self.selected_windows = self
            .windows
            .iter()
            .filter(|window| matches!(window.name.as_str(), "nvim" | "opencode"))
            .map(|window| window.id.clone())
            .collect();
    }

    fn kill(&mut self) -> (String, bool) {
        let sessions: Vec<String> = self.selected_sessions.iter().cloned().collect();
        let windows: Vec<String> = self
            .selected_windows
            .iter()
            .filter(|id| {
                self.windows
                    .iter()
                    .find(|window| &window.id == *id)
                    .is_some_and(|window| !self.selected_sessions.contains(&window.session))
            })
            .cloned()
            .collect();
        let mut failed = 0;
        for name in &sessions {
            if run_on(self.socket.as_deref(), &["kill-session", "-t", name]).is_err() {
                failed += 1;
            }
        }
        for id in &windows {
            if run_on(self.socket.as_deref(), &["kill-window", "-t", id]).is_err() {
                failed += 1;
            }
        }
        let count = sessions.len() + windows.len();
        self.clear_selection();
        self.refresh();
        if failed == 0 {
            (
                format!("Killed {} tmux target{}", count, ui::plural(count)),
                false,
            )
        } else {
            (
                format!(
                    "Could not kill {} tmux target{}",
                    failed,
                    ui::plural(failed)
                ),
                true,
            )
        }
    }
}

pub(crate) fn view(app: &AppState, k: &'static rune_kit::Kit, hair: f32) -> El {
    let selected = app.tmux.selected_sessions.len() + app.tmux.selected_windows.len();
    let action = Button::new(if selected == 0 {
        "Kill selected".to_owned()
    } else {
        format!("Kill selected ({selected})")
    })
    .variant(ButtonVariant::Danger)
    .control_size(ControlSize::Large)
    .disabled(selected == 0)
    .on_press(|app: &mut AppState| app.status = Some(app.tmux.kill()))
    .build(k);
    let refresh = Button::new("Refresh")
        .variant(ButtonVariant::GhostMuted)
        .control_size(ControlSize::Large)
        .on_press(|app: &mut AppState| app.tmux.refresh())
        .build(k);
    let header = row()
        .h(36.0)
        .center_y()
        .child(ui::section_label(k, "Sessions").grow(1.0))
        .child(refresh)
        .child(action.ml(8.0));
    let mut list = col().key("tmux-list");
    let mut row_index = 0;
    for session in &app.tmux.sessions {
        if row_index > 0 {
            list = list.child(ui::separator(k, hair));
        }
        row_index += 1;
        let name = session.name.clone();
        let checked = app.tmux.selected_sessions.contains(&name);
        list = list.child(
            row()
                .key(format!("session-{name}"))
                .h(44.0)
                .px(14.0)
                .gap(12.0)
                .center_y()
                .hover(k.c.hover)
                .on_press({
                    let name = name.clone();
                    move |app: &mut AppState| {
                        ui::toggle(&mut app.tmux.selected_sessions, name.clone())
                    }
                })
                .child(
                    Checkbox::new(checked)
                        .label(name.clone())
                        .hide_label()
                        .on_toggle({
                            let name = name.clone();
                            move |app: &mut AppState| {
                                ui::toggle(&mut app.tmux.selected_sessions, name.clone())
                            }
                        })
                        .build(k),
                )
                .child(icon(&icons::SERVER, 16.0).color(k.c.icon_muted))
                .child(
                    text(name.clone())
                        .font(k.ty.ui_medium)
                        .color(k.c.text_base)
                        .grow(1.0)
                        .truncate(),
                )
                .child(
                    text(format!("{} windows", session.windows))
                        .font(k.ty.small)
                        .color(k.c.text_faint),
                )
                .child(
                    text(format!("{} attached", session.attached))
                        .font(k.ty.small)
                        .color(k.c.text_faint)
                        .w(70.0),
                ),
        );
        for window in app
            .tmux
            .windows
            .iter()
            .filter(|window| window.session == session.name)
        {
            list = list.child(ui::separator(k, hair).ml(42.0));
            let id = window.id.clone();
            let checked = app.tmux.selected_windows.contains(&id)
                || app.tmux.selected_sessions.contains(&session.name);
            let disabled = app.tmux.selected_sessions.contains(&session.name);
            list = list.child(
                row()
                    .key(format!("window-{}", window.id))
                    .h(40.0)
                    .pl(42.0)
                    .pr(14.0)
                    .gap(12.0)
                    .center_y()
                    .hover(if disabled {
                        rune::Color::TRANSPARENT
                    } else {
                        k.c.hover
                    })
                    .on_press({
                        let id = id.clone();
                        move |app: &mut AppState| {
                            if !disabled {
                                ui::toggle(&mut app.tmux.selected_windows, id.clone())
                            }
                        }
                    })
                    .child(
                        Checkbox::new(checked)
                            .label(window.name.clone())
                            .hide_label()
                            .disabled(disabled)
                            .on_toggle({
                                let id = id.clone();
                                move |app: &mut AppState| {
                                    ui::toggle(&mut app.tmux.selected_windows, id.clone())
                                }
                            })
                            .build(k),
                    )
                    .child(
                        text(format!("{}: {}", window.index, window.name))
                            .font(k.ty.ui)
                            .color(if disabled {
                                k.c.text_faint
                            } else {
                                k.c.text_muted
                            })
                            .grow(1.0)
                            .truncate(),
                    ),
            );
        }
    }
    if let Some(error) = &app.tmux.error {
        list = list.child(
            el().h(120.0).center().px(20.0).child(
                text(error.clone())
                    .font(k.ty.ui)
                    .color(k.c.danger.fg)
                    .wrap(),
            ),
        );
    } else if app.tmux.sessions.is_empty() {
        list = list.child(
            el().h(120.0)
                .center()
                .child(text("No tmux sessions").font(k.ty.ui).color(k.c.text_faint)),
        );
    }
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
        .children(ui::status(app.status.as_ref(), k))
}

fn program() -> &'static str {
    if Path::new("/opt/homebrew/bin/tmux").exists() {
        "/opt/homebrew/bin/tmux"
    } else {
        "/usr/local/bin/tmux"
    }
}

fn sockets() -> Vec<PathBuf> {
    let mut sockets = Vec::new();
    if let Some(socket) = std::env::var_os("TMUX")
        .and_then(|value| value.to_str().map(str::to_owned))
        .and_then(|value| value.split(',').next().map(PathBuf::from))
        .filter(|path| path.exists())
    {
        sockets.push(socket);
    }
    let directory = PathBuf::from(format!("/private/tmp/tmux-{}", libc_getuid()));
    if let Ok(entries) = fs::read_dir(directory) {
        for path in entries.flatten().map(|entry| entry.path()) {
            if path.exists() && !sockets.contains(&path) {
                sockets.push(path);
            }
        }
    }
    sockets
}

fn run_on(socket: Option<&Path>, args: &[&str]) -> Result<String, String> {
    let mut command = Command::new(program());
    // LaunchServices does not provide LANG. In the resulting C locale tmux
    // renders the tab separators in our formats as underscores, so every row
    // is rejected by the parsers below.
    command.env("LC_ALL", "en_US.UTF-8");
    if let Some(socket) = socket {
        command.arg("-S").arg(socket);
    }
    let output = command
        .args(args)
        .output()
        .map_err(|error| error.to_string())?;
    if output.status.success() {
        return Ok(String::from_utf8_lossy(&output.stdout).trim().to_owned());
    }
    let stderr = String::from_utf8_lossy(&output.stderr).trim().to_owned();
    let stdout = String::from_utf8_lossy(&output.stdout).trim().to_owned();
    let message = if stderr.is_empty() { stdout } else { stderr };
    let target = socket.map_or_else(
        || "default tmux server".to_owned(),
        |socket| socket.display().to_string(),
    );
    Err(if message.is_empty() {
        format!("{target}: command failed with {}", output.status)
    } else {
        format!("{target}: {message}")
    })
}

fn list() -> Result<(Vec<Session>, Vec<Window>, Option<PathBuf>), String> {
    let session_args = [
        "list-sessions",
        "-F",
        "#{session_name}\t#{session_windows}\t#{session_attached}",
    ];
    let mut errors = Vec::new();
    let mut source = None;
    let mut sessions_output = None;
    match run_on(None, &session_args) {
        Ok(output) if !output.is_empty() => sessions_output = Some(output),
        Ok(_) => {}
        Err(error) => errors.push(error),
    }
    if sessions_output.is_none() {
        for socket in sockets() {
            match run_on(Some(&socket), &session_args) {
                Ok(output) if !output.is_empty() => {
                    source = Some(socket);
                    sessions_output = Some(output);
                    break;
                }
                Ok(_) => {}
                Err(error) => errors.push(error),
            }
        }
    }
    let Some(sessions_output) = sessions_output else {
        if errors.is_empty() {
            return Ok((Vec::new(), Vec::new(), None));
        }
        return Err(errors.join("\n"));
    };
    let sessions = sessions_output
        .lines()
        .filter_map(|line| {
            let mut fields = line.split('\t');
            Some(Session {
                name: fields.next()?.to_owned(),
                windows: fields.next()?.parse().ok()?,
                attached: fields.next()?.parse().ok()?,
            })
        })
        .collect();
    let windows = run_on(
        source.as_deref(),
        &[
            "list-windows",
            "-a",
            "-F",
            "#{window_id}\t#{session_name}\t#{window_index}\t#{window_name}",
        ],
    )?
    .lines()
    .filter_map(|line| {
        let mut fields = line.split('\t');
        Some(Window {
            id: fields.next()?.to_owned(),
            session: fields.next()?.to_owned(),
            index: fields.next()?.parse().ok()?,
            name: fields.next()?.to_owned(),
        })
    })
    .collect();
    Ok((sessions, windows, source))
}
