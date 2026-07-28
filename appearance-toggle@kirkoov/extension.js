/* exported init enable disable */

const { Gio, St } = imports.gi;

const Main = imports.ui.main;
const PanelMenu = imports.ui.panelMenu;

let button = null;
let proxy = null;

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

  watchNightLight();

  log("[Appearance Toggle] enabled");
}

function disable() {
  if (button) {
    button.destroy();
    button = null;
  }

  log("[Appearance Toggle] disabled");
}

function watchNightLight() {
  Gio.DBusProxy.new_for_bus(
    Gio.BusType.SESSION,
    Gio.DBusProxyFlags.NONE,
    null,
    "org.gnome.SettingsDaemon.Color",
    "/org/gnome/SettingsDaemon/Color",
    "org.gnome.SettingsDaemon.Color",
    null,

    (source, result) => {
      try {
        proxy = Gio.DBusProxy.new_for_bus_finish(result);

        log("[Appearance Toggle] Night Light proxy created");

        let active = proxy.get_cached_property("NightLightActive");

        if (active) {
          // log(
          //   `[Appearance Toggle] Initial NightLightActive = ${active.unpack()}`,
          // );
          const enabled = active.unpack();
          log(`[Appearance Toggle] Initial NightLightActive = ${enabled}`);
          setAppearance(enabled);
        } else log("[Appearance Toggle] NightLightActive property not found");

        proxy.connect(
          "g-properties-changed",
          (_proxy, changed, _invalidated) => {
            let props = changed.deepUnpack();

            if ("NightLightActive" in props) {
              // log(
              //   `[Appearance Toggle] NightLightActive = ${props["NightLightActive"].unpack()}`,
              // );
              const active = props["NightLightActive"].unpack();
              log(`[Appearance Toggle] NightLightActive = ${active}`);
              setAppearance(active);
            }
          },
        );
      } catch (e) {
        logError(e);
      }
    },
  );
}

function toggleAppearance() {
  const settings = new Gio.Settings({
    schema: "org.gnome.desktop.interface",
  });

  const current = settings.get_string("color-scheme");

  setAppearance(current !== "prefer-dark");
}

function setAppearance(dark) {
  const settings = new Gio.Settings({
    schema: "org.gnome.desktop.interface",
  });

  const next = dark ? "prefer-dark" : "prefer-light";

  settings.set_string("color-scheme", next);

  log(`[Appearance Toggle] Appearance -> ${next}`);
}
