use tauri::{AppHandle, Manager, PhysicalPosition, WebviewUrl, WebviewWindowBuilder, WindowEvent};

#[tauri::command]
fn focus_main_window(app: AppHandle) -> Result<(), String> {
    if let Some(main_win) = app.get_webview_window("main") {
        let _ = main_win.show();
        let _ = main_win.unminimize();
        // Temporarily set always on top then revert to force X11/Mutter to raise window above all others
        let _ = main_win.set_always_on_top(true);
        let _ = main_win.set_focus();
        let _ = main_win.set_always_on_top(false);
        Ok(())
    } else {
        // If main window was closed or not yet created, recreate and show it
        let win = WebviewWindowBuilder::new(
            &app,
            "main",
            WebviewUrl::default()
        )
        .title("TESS — Personal AI Companion")
        .inner_size(1140.0, 780.0)
        .min_inner_size(850.0, 600.0)
        .resizable(true)
        .center()
        .build()
        .map_err(|e| format!("Failed to create main window: {}", e))?;
        let _ = win.set_always_on_top(true);
        let _ = win.set_focus();
        let _ = win.set_always_on_top(false);
        Ok(())
    }
}

#[tauri::command]
fn toggle_mascot_window(app: AppHandle, visible: bool) -> Result<(), String> {
    if let Some(mascot_win) = app.get_webview_window("mascot") {
        if visible {
            let _ = mascot_win.show();
        } else {
            let _ = mascot_win.hide();
        }
        Ok(())
    } else {
        Err("Mascot window not found".into())
    }
}

#[tauri::command]
fn set_mascot_position(app: AppHandle, x: i32, y: i32) -> Result<(), String> {
    if let Some(mascot_win) = app.get_webview_window("mascot") {
        let _ = mascot_win.set_position(PhysicalPosition::new(x, y));
        Ok(())
    } else {
        Err("Mascot window not found".into())
    }
}

#[tauri::command]
fn get_mascot_position(app: AppHandle) -> Result<(i32, i32), String> {
    if let Some(mascot_win) = app.get_webview_window("mascot") {
        let pos = mascot_win.outer_position().map_err(|e| e.to_string())?;
        Ok((pos.x, pos.y))
    } else {
        Err("Mascot window not found".into())
    }
}

#[tauri::command]
fn get_desktop_platform() -> String {
    std::env::consts::OS.to_string()
}

pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_notification::init())
        .invoke_handler(tauri::generate_handler![
            focus_main_window,
            toggle_mascot_window,
            set_mascot_position,
            get_mascot_position,
            get_desktop_platform
        ])
        .on_window_event(|window, event| {
            if let WindowEvent::CloseRequested { api, .. } = event {
                if window.label() == "main" {
                    // Prevent destroying the main window so the mascot can re-focus it immediately
                    api.prevent_close();
                    let _ = window.hide();
                }
            }
        })
        .setup(|app| {
            if let Some(mascot_win) = app.get_webview_window("mascot") {
                let monitor_opt = mascot_win.current_monitor().ok().flatten()
                    .or_else(|| mascot_win.primary_monitor().ok().flatten());
                if let Some(monitor) = monitor_opt {
                    let size = monitor.size();
                    let scale = monitor.scale_factor();
                    // Position strictly in bottom-right workspace (x >= 320 to avoid left sidebar)
                    let x = (((size.width as f64) - (200.0 * scale)) as i32).max((320.0 * scale) as i32);
                    let y = (((size.height as f64) - (260.0 * scale)) as i32).max((100.0 * scale) as i32);
                    let _ = mascot_win.set_position(PhysicalPosition::new(x, y));
                }
            }
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running TESS desktop application");
}

