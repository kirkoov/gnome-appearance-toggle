/* exported init enable disable */

const { Gio, St } = imports.gi;

const Main = imports.ui.main;
const PanelMenu = imports.ui.panelMenu;

let button = null;

function init() {}

function enable() {
  button = new PanelMenu.Button(0.0, "Appearance Toggle");

  const icon = new St.Icon({
    icon_name: "display-brightness-symbolic",
    style_class: "system-status-icon",
  });

  button.add_child(icon);

  button.connect("button-press-event", toggleAppearance);

  Main.panel.addToStatusArea("appearance-toggle", button);

  log("[Appearance Toggle] enabled");
}

function disable() {
  if (button) {
    button.destroy();
    button = null;
  }

  log("[Appearance Toggle] disabled");
}

function toggleAppearance() {
  const settings = new Gio.Settings({
    schema: "org.gnome.desktop.interface",
  });

  const current = settings.get_string("color-scheme");

  const next = current === "prefer-dark" ? "prefer-light" : "prefer-dark";

  settings.set_string("color-scheme", next);

  log(`[Appearance Toggle] ${current} -> ${next}`);
}
