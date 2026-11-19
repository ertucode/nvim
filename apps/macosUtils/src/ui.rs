use rune::{El, col, el, row, text};

pub(crate) fn page(k: &'static rune_kit::Kit) -> El {
    col()
        .key("page")
        .grow(1.0)
        .min_h(0.0)
        .px(16.0)
        .pb(16.0)
        .gap(24.0)
        .fill(k.c.bg_base)
}

pub(crate) fn section(
    k: &'static rune_kit::Kit,
    key: &str,
    title: &str,
    rows: Vec<El>,
    hair: f32,
) -> El {
    let mut contents = col();
    for (index, item) in rows.into_iter().enumerate() {
        if index > 0 {
            contents = contents.child(separator(k, hair));
        }
        contents = contents.child(item);
    }
    col()
        .key(key)
        .gap(8.0)
        .child(section_label(k, title).mx(16.0))
        .child(card(k, contents, hair))
}

pub(crate) fn section_label(k: &'static rune_kit::Kit, title: &str) -> El {
    text(title)
        .role("heading")
        .level(2)
        .font(k.ty.ui_medium)
        .color(k.c.text_muted)
}

pub(crate) fn setting_row(k: &'static rune_kit::Kit, label: &str, control: El) -> El {
    row()
        .h(52.0)
        .px(16.0)
        .center_y()
        .child(text(label).font(k.ty.ui).color(k.c.text_base).grow(1.0))
        .child(control)
}

pub(crate) fn card(k: &'static rune_kit::Kit, content: El, hair: f32) -> El {
    let mut surface = col()
        .fill(k.c.bg_base)
        .radius(k.radius.lg)
        .border(hair, k.c.border_weak)
        .child(content);
    for shadow in &k.elevation.raised {
        surface = surface.box_shadow(*shadow);
    }
    surface
}

pub(crate) fn separator(k: &'static rune_kit::Kit, hair: f32) -> El {
    el().h(hair).mx(14.0).fill(k.c.border_weak).a11y_hidden()
}

pub(crate) fn status(status: Option<&(String, bool)>, k: &'static rune_kit::Kit) -> Option<El> {
    status.map(|(message, error)| {
        row()
            .key("status")
            .h(28.0)
            .px(10.0)
            .radius(k.radius.md)
            .fill(if *error {
                k.c.danger.bg
            } else {
                k.c.success.bg
            })
            .child(text(message.clone()).font(k.ty.small).color(if *error {
                k.c.danger.fg
            } else {
                k.c.success.fg
            }))
            .center_y()
    })
}

pub(crate) fn plural(count: usize) -> &'static str {
    if count == 1 { "" } else { "s" }
}

pub(crate) fn toggle<T: Ord>(set: &mut std::collections::BTreeSet<T>, value: T) {
    if !set.remove(&value) {
        set.insert(value);
    }
}
