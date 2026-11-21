//! The credential owner is installed once, separately from the rebuilt GUI.
//! Its protocol returns status only, never a Wi-Fi password.
use std::path::PathBuf;
use std::process::Command;

pub(crate) struct Error {
    pub(crate) message: String,
    pub(crate) needs_authorization: bool,
}

fn invoke(args: &[&str]) -> Result<(), Error> {
    let path = PathBuf::from(std::env::var_os("HOME").unwrap_or_default())
        .join("Library/Application Support/macOS Utils/wifi-keychain");
    let output = Command::new(path)
        .args(args)
        .output()
        .map_err(|error| Error {
            message: format!("Wi-Fi helper is unavailable; run make install-macos-utils: {error}"),
            needs_authorization: false,
        })?;
    if output.status.success() {
        return Ok(());
    }
    let message = String::from_utf8_lossy(&output.stderr).trim().to_owned();
    Err(Error {
        message: if message.is_empty() {
            "Wi-Fi helper failed".to_owned()
        } else {
            message
        },
        needs_authorization: output.status.code() == Some(2),
    })
}

pub(crate) fn connect(device: &str, name: &str, requires_password: bool) -> Result<(), Error> {
    invoke(&[
        if requires_password {
            "connect"
        } else {
            "connect-open"
        },
        device,
        name,
    ])
}

pub(crate) fn authorize(name: &str) -> Result<(), String> {
    invoke(&["authorize", name]).map_err(|error| error.message)
}
