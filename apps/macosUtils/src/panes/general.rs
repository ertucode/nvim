use rune::El;
use rune_kit::SegmentedControl;

use crate::{AppState, GAME_POLICY, run, ui};

pub(crate) struct State {
    pub(crate) game_on: bool,
}

impl State {
    pub(crate) fn new() -> Self {
        Self {
            game_on: read_policy().unwrap_or(false),
        }
    }

    pub(crate) fn refresh(&mut self) -> Result<(), String> {
        self.game_on = read_policy()?;
        Ok(())
    }

    fn set(&mut self, on: bool) -> Result<(), String> {
        run(
            GAME_POLICY,
            &["game-mode", "set", if on { "on" } else { "auto" }],
        )?;
        self.refresh()
    }
}

fn read_policy() -> Result<bool, String> {
    let output = run(GAME_POLICY, &["game-mode", "status"])?;
    if output.contains("forced always on") {
        return Ok(true);
    }
    if output.contains("enablement policy is currently automatic") {
        return Ok(false);
    }
    Err("Could not read Game Mode policy".to_owned())
}

pub(crate) fn view(app: &AppState, k: &'static rune_kit::Kit, hair: f32) -> El {
    let game = SegmentedControl::new(&["Auto", "On"], Some(app.general.game_on as usize))
        .label("Game Mode")
        .width(Some(180.0))
        .on_pick(|app: &mut AppState, selected, _| {
            app.status = app
                .general
                .set(selected == 1)
                .err()
                .map(|error| (error, true));
        })
        .build(k);
    let game_row = ui::setting_row(k, "Game Mode", game);
    ui::page(k)
        .child(ui::section(
            k,
            "game-mode",
            "Game Performance",
            vec![game_row],
            hair,
        ))
        .children(ui::status(app.status.as_ref(), k))
}
