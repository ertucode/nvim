use std::collections::{BTreeSet, HashMap};
use std::process::Command;

use rune::{El, ScrollSpec, col, row, text};
use rune_kit::{Button, ButtonVariant, Checkbox, ControlSize};

use crate::{AppState, run, ui};

pub(crate) struct ProcessInfo {
    pid: i32,
    physical_footprint_kb: u64,
    display_name: String,
    command: String,
    args: String,
    open_files: Vec<String>,
}

#[derive(Default)]
pub(crate) struct State {
    items: Vec<ProcessInfo>,
    selected: BTreeSet<i32>,
}

impl State {
    pub(crate) fn is_empty(&self) -> bool {
        self.items.is_empty()
    }

    pub(crate) fn refresh(&mut self) {
        self.items = list();
        self.selected
            .retain(|pid| self.items.iter().any(|process| process.pid == *pid));
    }

    fn kill(&mut self) -> (String, bool) {
        let selected: Vec<i32> = self.selected.iter().copied().collect();
        let mut failed = Vec::new();
        for pid in &selected {
            if run("/bin/kill", &["-9", &pid.to_string()]).is_err() {
                failed.push(*pid);
            }
        }
        self.selected.clear();
        self.refresh();
        if failed.is_empty() {
            (
                format!(
                    "Killed {} process{}",
                    selected.len(),
                    ui::plural(selected.len())
                ),
                false,
            )
        } else {
            (
                format!(
                    "Could not kill {} process{}",
                    failed.len(),
                    ui::plural(failed.len())
                ),
                true,
            )
        }
    }
}

pub(crate) fn view(app: &AppState, k: &'static rune_kit::Kit, hair: f32) -> El {
    let count = app.processes.selected.len();
    let action = Button::new(if count == 0 {
        "Kill selected".to_owned()
    } else {
        format!("Kill selected ({count})")
    })
    .variant(ButtonVariant::Danger)
    .control_size(ControlSize::Large)
    .disabled(count == 0)
    .on_press(|app: &mut AppState| app.status = Some(app.processes.kill()))
    .build(k);
    let refresh = Button::new("Refresh")
        .variant(ButtonVariant::GhostMuted)
        .control_size(ControlSize::Large)
        .on_press(|app: &mut AppState| app.processes.refresh())
        .build(k);
    let header = row()
        .h(36.0)
        .center_y()
        .child(ui::section_label(k, "Processes").grow(1.0))
        .child(refresh)
        .child(action.ml(8.0));
    let mut list = col().key("process-list");
    for (index, process) in app.processes.items.iter().enumerate() {
        if index > 0 {
            list = list.child(ui::separator(k, hair));
        }
        let pid = process.pid;
        let checked = app.processes.selected.contains(&pid);
        let memory = format_memory(process.physical_footprint_kb);
        let command = if process.args.is_empty() {
            process.command.clone()
        } else {
            process.args.clone()
        };
        let files = process.open_files.join("  ·  ");
        let row_height = if files.is_empty() { 60.0 } else { 76.0 };
        list = list.child(
            row()
                .key(format!("process-{pid}"))
                .h(row_height)
                .px(14.0)
                .gap(12.0)
                .center_y()
                .hover(k.c.hover)
                .on_press(move |app: &mut AppState| ui::toggle(&mut app.processes.selected, pid))
                .child(
                    Checkbox::new(checked)
                        .label(process.display_name.clone())
                        .hide_label()
                        .on_toggle(move |app: &mut AppState| {
                            ui::toggle(&mut app.processes.selected, pid)
                        })
                        .build(k),
                )
                .child(
                    col()
                        .grow(1.0)
                        .shrink()
                        .gap(3.0)
                        .child(
                            row()
                                .child(
                                    text(process.display_name.clone())
                                        .font(k.ty.ui_medium)
                                        .color(k.c.text_base)
                                        .grow(1.0)
                                        .truncate(),
                                )
                                .child(
                                    text(format!("{memory} footprint"))
                                        .font(k.ty.small)
                                        .color(k.c.text_muted),
                                )
                                .child(
                                    text(format!("pid {}", process.pid))
                                        .font(k.ty.mono)
                                        .color(k.c.text_faint)
                                        .ml(12.0),
                                ),
                        )
                        .child(
                            text(shorten(&command, 150))
                                .font(k.ty.mono)
                                .color(k.c.text_faint)
                                .truncate(),
                        )
                        .children((!files.is_empty()).then(|| {
                            text(shorten(&files, 150))
                                .font(k.ty.small)
                                .color(k.c.text_faint)
                                .truncate()
                        })),
                ),
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

fn list() -> Vec<ProcessInfo> {
    let Ok(ps_output) = run("/bin/ps", &["-axo", "pid=,comm=,args="]) else {
        return Vec::new();
    };
    let top_output = run(
        "/usr/bin/top",
        &["-l", "1", "-o", "mem", "-stats", "pid,mem,command"],
    )
    .unwrap_or_default();
    let mut memory_by_pid = HashMap::new();
    let mut display_name_by_pid = HashMap::new();
    for line in top_output.lines() {
        let mut fields = line.split_whitespace();
        let Some(pid) = fields.next().and_then(|value| value.parse::<i32>().ok()) else {
            continue;
        };
        let Some(memory) = fields.next() else {
            continue;
        };
        memory_by_pid.insert(pid, parse_top_memory(memory));
        display_name_by_pid.insert(pid, fields.collect::<Vec<_>>().join(" "));
    }
    let own_pid = std::process::id() as i32;
    let mut processes: Vec<_> = ps_output
        .lines()
        .filter_map(|line| {
            let line = line.trim();
            let pid_end = line.find(char::is_whitespace)?;
            let pid = line[..pid_end].parse::<i32>().ok()?;
            let rest = line[pid_end..].trim_start();
            let command_end = rest.find(char::is_whitespace).unwrap_or(rest.len());
            let command = rest[..command_end].to_owned();
            let args = rest[command_end..].trim_start().to_owned();
            if pid == own_pid || command.is_empty() {
                return None;
            }
            Some(ProcessInfo {
                pid,
                physical_footprint_kb: memory_by_pid.get(&pid).copied().unwrap_or_default(),
                display_name: process_name(
                    display_name_by_pid
                        .get(&pid)
                        .map(String::as_str)
                        .unwrap_or_default(),
                    &command,
                    &args,
                ),
                command,
                args,
                open_files: Vec::new(),
            })
        })
        .collect();
    processes.sort_by_key(|process| std::cmp::Reverse(process.physical_footprint_kb));
    processes.truncate(80);
    let open_files = list_open_files(processes.iter().map(|process| process.pid).collect());
    for process in &mut processes {
        process.open_files = open_files.get(&process.pid).cloned().unwrap_or_default();
    }
    processes
}

fn parse_top_memory(value: &str) -> u64 {
    let split = value.find(|character: char| !character.is_ascii_digit() && character != '.');
    let (number, unit) = split.map_or((value, "K"), |at| value.split_at(at));
    let number = number.parse::<f64>().unwrap_or_default();
    let multiplier = match unit.chars().next().unwrap_or('K').to_ascii_uppercase() {
        'M' => 1024.0,
        'G' => 1024.0 * 1024.0,
        'T' => 1024.0 * 1024.0 * 1024.0,
        'P' => 1024.0 * 1024.0 * 1024.0 * 1024.0,
        _ => 1.0,
    };
    (number * multiplier).round() as u64
}

fn process_name(top_name: &str, command: &str, args: &str) -> String {
    let primary = if args.is_empty() { command } else { args };
    if let Some(before_contents) = primary.split(".app/").next()
        && primary.contains(".app/")
        && let Some(name) = before_contents.rsplit('/').next()
    {
        return name.to_owned();
    }
    if !top_name.is_empty() {
        return top_name.to_owned();
    }
    command.rsplit('/').next().unwrap_or(command).to_owned()
}

fn list_open_files(pids: Vec<i32>) -> HashMap<i32, Vec<String>> {
    let mut files_by_pid: HashMap<i32, Vec<String>> = HashMap::new();
    for chunk in pids.chunks(64) {
        let joined = chunk
            .iter()
            .map(i32::to_string)
            .collect::<Vec<_>>()
            .join(",");
        let Ok(output) = Command::new("/usr/sbin/lsof")
            .args(["-n", "-P", "-F", "pn", "-p", &joined])
            .output()
        else {
            continue;
        };
        let output = String::from_utf8_lossy(&output.stdout);
        let mut current_pid = None;
        for line in output.lines() {
            if let Some(value) = line.strip_prefix('p') {
                current_pid = value.parse::<i32>().ok();
                continue;
            }
            let Some(path) = line.strip_prefix('n') else {
                continue;
            };
            let Some(pid) = current_pid else { continue };
            if !path.starts_with('/') || path == "/" {
                continue;
            }
            let files = files_by_pid.entry(pid).or_default();
            if files.len() < 3 && !files.iter().any(|existing| existing == path) {
                files.push(path.to_owned());
            }
        }
    }
    files_by_pid
}

fn format_memory(kb: u64) -> String {
    let mb = kb as f64 / 1024.0;
    if mb >= 1024.0 {
        format!("{:.1} GB", mb / 1024.0)
    } else {
        format!("{mb:.0} MB")
    }
}

fn shorten(value: &str, max_chars: usize) -> String {
    if value.chars().count() <= max_chars {
        return value.to_owned();
    }
    let mut shortened: String = value.chars().take(max_chars.saturating_sub(1)).collect();
    shortened.push('…');
    shortened
}
