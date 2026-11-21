//! Stable, non-exporting credential helper. Never replace this executable as
//! part of an ordinary GUI build: self-signed Keychain partitions use cdhash.
use std::ffi::{CStr, c_char, c_void};
use std::io::Write;
use std::process::{Command, Stdio};

type Id = *mut c_void;
type Sel = *mut c_void;
const SERVICE: &[u8] = b"codes.ertu.macosUtils.wifi-helper-password";

#[link(name = "Security", kind = "framework")]
unsafe extern "C" {
    fn SecKeychainSetUserInteractionAllowed(allowed: u8) -> i32;
    fn SecKeychainFindGenericPassword(
        keychain: Id,
        service_len: u32,
        service: *const c_char,
        account_len: u32,
        account: *const c_char,
        length: *mut u32,
        data: *mut *mut c_void,
        item: *mut Id,
    ) -> i32;
    fn SecKeychainAddGenericPassword(
        keychain: Id,
        service_len: u32,
        service: *const c_char,
        account_len: u32,
        account: *const c_char,
        length: u32,
        data: *const c_void,
        item: *mut Id,
    ) -> i32;
    fn SecKeychainItemModifyAttributesAndData(
        item: Id,
        attributes: Id,
        length: u32,
        data: *const c_void,
    ) -> i32;
    fn SecKeychainItemFreeContent(attributes: Id, data: *mut c_void) -> i32;
}
#[link(name = "CoreWLAN", kind = "framework")]
unsafe extern "C" {
    fn CWKeychainFindWiFiPassword(domain: isize, ssid: Id, password: *mut Id) -> i32;
}
#[link(name = "Foundation", kind = "framework")]
unsafe extern "C" {}
#[link(name = "CoreFoundation", kind = "framework")]
unsafe extern "C" {
    fn CFRelease(object: Id);
}
#[link(name = "objc")]
unsafe extern "C" {
    fn objc_getClass(name: *const c_char) -> Id;
    fn sel_registerName(name: *const c_char) -> Sel;
    fn objc_msgSend();
}

struct Secret(Vec<u8>);
impl Drop for Secret {
    fn drop(&mut self) {
        for byte in &mut self.0 {
            unsafe { std::ptr::write_volatile(byte, 0) };
        }
    }
}

// The helper is short-lived and single-threaded. All ordinary commands disable
// interaction before accessing any keychain, including locked/missing items.
fn cached_password(name: &str) -> Result<Secret, String> {
    unsafe {
        let status = SecKeychainSetUserInteractionAllowed(0);
        if status != 0 {
            return Err(format!("Could not disable Keychain prompts ({status})"));
        }
        let mut length = 0;
        let mut data = std::ptr::null_mut();
        let status = SecKeychainFindGenericPassword(
            std::ptr::null_mut(),
            SERVICE.len() as u32,
            SERVICE.as_ptr().cast(),
            name.len() as u32,
            name.as_ptr().cast(),
            &mut length,
            &mut data,
            std::ptr::null_mut(),
        );
        if status != 0 || data.is_null() {
            return Err(format!(
                "Authorize this network once for the stable Wi-Fi helper (Keychain {status}). No authentication was requested."
            ));
        }
        let password =
            Secret(std::slice::from_raw_parts(data.cast::<u8>(), length as usize).to_vec());
        SecKeychainItemFreeContent(std::ptr::null_mut(), data);
        Ok(password)
    }
}

unsafe fn send_id(object: Id, name: &'static [u8]) -> Id {
    let f: unsafe extern "C" fn(Id, Sel) -> Id =
        unsafe { std::mem::transmute(objc_msgSend as *const ()) };
    unsafe { f(object, sel_registerName(name.as_ptr().cast())) }
}

// Invoked only by the explicit approval button, never by connect/check/build.
fn authorize(name: &str) -> Result<(), String> {
    unsafe {
        let pool = send_id(
            send_id(objc_getClass(c"NSAutoreleasePool".as_ptr()), b"alloc\0"),
            b"init\0",
        );
        let result = authorize_in_pool(name);
        let drain: unsafe extern "C" fn(Id, Sel) = std::mem::transmute(objc_msgSend as *const ());
        drain(pool, sel_registerName(c"drain".as_ptr()));
        result
    }
}

unsafe fn authorize_in_pool(name: &str) -> Result<(), String> {
    unsafe {
        let data: unsafe extern "C" fn(Id, Sel, *const u8, usize) -> Id =
            std::mem::transmute(objc_msgSend as *const ());
        let ssid = data(
            objc_getClass(c"NSData".as_ptr()),
            sel_registerName(c"dataWithBytes:length:".as_ptr()),
            name.as_ptr(),
            name.len(),
        );
        let mut password = std::ptr::null_mut();
        let mut status = CWKeychainFindWiFiPassword(2, ssid, &mut password);
        if status == -25300 {
            status = CWKeychainFindWiFiPassword(1, ssid, &mut password);
        }
        if status != 0 || password.is_null() {
            return Err(format!(
                "Could not authorize the saved Wi-Fi password (Keychain {status})"
            ));
        }
        let pointer = send_id(password, b"UTF8String\0").cast::<c_char>();
        if pointer.is_null() {
            return Err("The saved Wi-Fi password is unavailable".to_owned());
        }
        let password = Secret(CStr::from_ptr(pointer).to_bytes().to_vec());
        let mut status = SecKeychainAddGenericPassword(
            std::ptr::null_mut(),
            SERVICE.len() as u32,
            SERVICE.as_ptr().cast(),
            name.len() as u32,
            name.as_ptr().cast(),
            password.0.len() as u32,
            password.0.as_ptr().cast(),
            std::ptr::null_mut(),
        );
        if status == -25299 {
            let mut item = std::ptr::null_mut();
            status = SecKeychainFindGenericPassword(
                std::ptr::null_mut(),
                SERVICE.len() as u32,
                SERVICE.as_ptr().cast(),
                name.len() as u32,
                name.as_ptr().cast(),
                std::ptr::null_mut(),
                std::ptr::null_mut(),
                &mut item,
            );
            if status == 0 && !item.is_null() {
                status = SecKeychainItemModifyAttributesAndData(
                    item,
                    std::ptr::null_mut(),
                    password.0.len() as u32,
                    password.0.as_ptr().cast(),
                );
                CFRelease(item);
            }
        }
        if status != 0 {
            return Err(format!("Could not save helper access (Keychain {status})"));
        }
        Ok(())
    }
}

fn connection_result(success: bool, stdout: &[u8], stderr: &[u8]) -> Result<(), String> {
    let stdout = String::from_utf8_lossy(stdout);
    let stderr = String::from_utf8_lossy(stderr);
    // networksetup can report a failed association with exit status zero.
    if !success
        || stdout.contains("Failed to join")
        || stdout.contains("Error:")
        || !stderr.trim().is_empty()
    {
        return Err(format!("{} {}", stdout.trim(), stderr.trim())
            .trim()
            .to_owned());
    }
    Ok(())
}

fn connect(device: &str, name: &str, password: Option<&Secret>) -> Result<(), String> {
    if !device.strip_prefix("en").is_some_and(|suffix| {
        !suffix.is_empty() && suffix.bytes().all(|byte| byte.is_ascii_digit())
    }) {
        return Err("Invalid Wi-Fi interface".to_owned());
    }
    let mut command = Command::new("/usr/sbin/networksetup");
    command
        .args(["-setairportnetwork", device, name])
        .stdout(Stdio::piped())
        .stderr(Stdio::piped());
    // '-' means read the password from stdin. It never appears in argv, logs,
    // the GUI's process, or the helper's protocol output.
    if password.is_some() {
        command.arg("-").stdin(Stdio::piped());
    } else {
        command.stdin(Stdio::null());
    }
    let mut child = command.spawn().map_err(|error| error.to_string())?;
    if let Some(password) = password {
        let mut stdin = child.stdin.take().ok_or("Could not open password input")?;
        if let Err(error) = stdin
            .write_all(&password.0)
            .and_then(|_| stdin.write_all(b"\n"))
        {
            drop(stdin);
            let _ = child.wait();
            return Err(format!("Could not send Wi-Fi credentials: {error}"));
        }
    }
    let output = child
        .wait_with_output()
        .map_err(|error| error.to_string())?;
    connection_result(output.status.success(), &output.stdout, &output.stderr)
}

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let result = match args.as_slice() {
        [command, name] if command == "authorize" => authorize(name).map_err(|error| (1, error)),
        [command, name] if command == "check" => cached_password(name)
            .map(|_| ())
            .map_err(|error| (2, error)),
        [command, device, name] if command == "connect" => match cached_password(name) {
            Ok(password) => connect(device, name, Some(&password)).map_err(|error| (1, error)),
            Err(error) => Err((2, error)),
        },
        [command, device, name] if command == "connect-open" => {
            connect(device, name, None).map_err(|error| (1, error))
        }
        _ => Err((
            1,
            "Usage: wifi-keychain connect|connect-open <device> <ssid> | authorize|check <ssid>"
                .to_owned(),
        )),
    };
    if let Err((code, error)) = result {
        eprintln!("{error}");
        std::process::exit(code);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn networksetup_zero_exit_does_not_hide_association_failure() {
        assert!(
            connection_result(true, b"Failed to join network example.\nError: -3900", b"").is_err()
        );
        assert!(connection_result(false, b"", b"permission denied").is_err());
        assert!(connection_result(true, b"", b"").is_ok());
    }
}
