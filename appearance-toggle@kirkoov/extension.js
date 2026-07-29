/* exported init enable disable */

const { Gio, St } = imports.gi;

const Main = imports.ui.main;
const PanelMenu = imports.ui.panelMenu;
const PopupMenu = imports.ui.popupMenu;
const MARKER = "[Appearance Toggle]";
const TARGET = "NightLightActive";

let button = null;
let proxy = null;
let settings = null;

function init() {}

function enable() {
  settings = new Gio.Settings({
    schema: "org.gnome.desktop.interface",
  });

  button = new PanelMenu.Button(0.0, "Appearance Toggle");

  const icon = new St.Icon({
    icon_name: "display-brightness-symbolic",
    style_class: "system-status-icon",
  });

  button.add_child(icon);

  const toggleItem = new PopupMenu.PopupMenuItem("Toggle now");
  toggleItem.connect("activate", toggleAppearance);
  button.menu.addMenuItem(toggleItem);

  // button.connect("button-press-event", toggleAppearance);

  Main.panel.addToStatusArea("appearance-toggle", button);

  watchNightLight();

  log(`${MARKER} enabled`);
}

function disable() {
  if (button) {
    button.destroy();
    button = null;
  }

  settings = null;
  proxy = null;

  log(`${MARKER} disabled`);
}

function watchNightLight() {
  Gio.DBusProxy.new_for_bus(
    // Hand GNOME a function and it starts working internally ASYNCHRONOUSLY (new_for_bus, e.g. opening D-Buses, checking
    // permissions, locating services, etc.) AND return to where the call to this function originates! And in our case,
    // the calling enable() finishes out there. WHEREAS GNOME is busy still. AS IT FINISHES, it now calls me to deliver on
    // the source (the async operation) and result (the completed proxy):
    Gio.BusType.SESSION, // connect me to my user's D-Bus
    Gio.DBusProxyFlags.NONE, // no special behaviour, just create a normal proxy
    null, // supply no extra info
    "org.gnome.SettingsDaemon.Color", // the "recipient department"
    "/org/gnome/SettingsDaemon/Color", // the addressee
    "org.gnome.SettingsDaemon.Color", // "speak this protocol"
    null,

    (_source, result) => {
      try {
        //The result contains the completed asynchronous operation.
        // new_for_bus_finish() extracts the finished proxy from it.
        proxy = Gio.DBusProxy.new_for_bus_finish(result);

        log(`${MARKER} Night Light proxy created`);

        const active = proxy.get_cached_property(TARGET);

        if (active) {
          const enabled = active.unpack();
          log(`${MARKER} Initial ${TARGET} = ${enabled}`);
          setDarkTheme(enabled);
        } else log(`${MARKER} ${TARGET} property not found`);

        // The heart of it all - the subscription to a signal from the NL proxy.
        // Subscribe to Night Light property changes (via the following GLib variants
        // in need of further unpacking to see what's inside).
        // GNOME invokes this callback whenever the property changes.
        // No polling or timers are involved.
        proxy.connect(
          "g-properties-changed",
          (_proxy, changed, _invalidated) => {
            const props = changed.deepUnpack();

            if (TARGET in props) {
              const active = props[TARGET].unpack();
              log(`${MARKER} ${TARGET} = ${active}`);
              setDarkTheme(active);
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
  const current = settings.get_string("color-scheme");

  setDarkTheme(current !== "prefer-dark");
}

function setDarkTheme(useDarkTheme) {
  const next = useDarkTheme ? "prefer-dark" : "prefer-light";

  settings.set_string("color-scheme", next);

  log(`${MARKER} Appearance -> ${next}`);
}
