/* exported init enable disable */

const { Gio, St } = imports.gi;

const ExtensionUtils = imports.misc.extensionUtils;
const Main = imports.ui.main;
const PanelMenu = imports.ui.panelMenu;
const PopupMenu = imports.ui.popupMenu;
const MARKER = "[Appearance Toggle]";
const TARGET = "NightLightActive";

let button = null;
let proxy = null;
// let settings = null;
// let followNightLight = true;
let interfaceSettings = null;
let extensionSettings = null;

const Me = ExtensionUtils.getCurrentExtension();

const schemaSource = Gio.SettingsSchemaSource.new_from_directory(
  Me.dir.get_child("schemas").get_path(),
  Gio.SettingsSchemaSource.get_default(),
  false,
);

const schema = schemaSource.lookup(
  "org.gnome.shell.extensions.appearance-toggle",
  false,
);

if (!schema) throw new Error("Extension settings schema not found");

extensionSettings = new Gio.Settings({
  settings_schema: schema,
});

function init() {}

function enable() {
  // settings = new Gio.Settings({
  //   schema: "org.gnome.desktop.interface",
  // });
  interfaceSettings = new Gio.Settings({
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

  const followNightLight = extensionSettings.get_boolean("follow-night-light");

  // const followItem = new PopupMenu.PopupSwitchMenuItem(
  //   "Follow Night Light",
  //   followNightLight,
  // );
  const followItem = new PopupMenu.PopupSwitchMenuItem(
    "Follow Night Light",
    followNightLight,
  );

  followItem.connect("toggled", (_item, state) => {
    // followNightLight = state;
    extensionSettings.set_boolean("follow-night-light", state);
    log(`${MARKER} Follow Night Light = ${state}`);
  });

  button.menu.addMenuItem(followItem);

  Main.panel.addToStatusArea("appearance-toggle", button);

  watchNightLight();

  log(`${MARKER} enabled`);
}

function disable() {
  if (button) {
    button.destroy();
    button = null;
  }

  interfaceSettings = null;
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
          // if (followNightLight) setDarkTheme(enabled);
          if (extensionSettings.get_boolean("follow-night-light"))
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
              // if (followNightLight) setDarkTheme(active);
              if (extensionSettings.get_boolean("follow-night-light"))
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
  // const current = settings.get_string("color-scheme");
  const current = interfaceSettings.get_string("color-scheme");

  setDarkTheme(current !== "prefer-dark");
}

function setDarkTheme(useDarkTheme) {
  const next = useDarkTheme ? "prefer-dark" : "prefer-light";

  // settings.set_string("color-scheme", next);
  interfaceSettings.set_string("color-scheme", next);

  log(`${MARKER} Appearance -> ${next}`);
}
