{ pkgs }:
let
  qtile = import ./local-package.nix { inherit pkgs; };
  launcher = pkgs.writeShellScriptBin "qtile-screen-policy" ''
    qtile_policy_config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}"
    exec ${qtile}/bin/qtile start \
      -c "$qtile_policy_config_dir/qtile-screen-policy/config.py" "$@"
  '';
  x11Session = pkgs.writeTextDir "share/xsessions/qtile-screen-policy.desktop" ''
    [Desktop Entry]
    Name=Qtile (workspace preferences)
    Comment=Qtile with configurable monitor workspace preferences
    Exec=${launcher}/bin/qtile-screen-policy -b x11
    Type=Application
    Keywords=wm;tiling
  '';
  waylandSession = pkgs.writeTextDir "share/wayland-sessions/qtile-screen-policy-wayland.desktop" ''
    [Desktop Entry]
    Name=Qtile (workspace preferences, Wayland)
    Comment=Qtile with configurable monitor workspace preferences
    Exec=${launcher}/bin/qtile-screen-policy -b wayland
    Type=Application
    Keywords=wm;tiling
  '';
in
pkgs.symlinkJoin {
  name = "qtile-screen-policy-${qtile.version}";
  paths = [
    launcher
    x11Session
    waylandSession
  ];
  passthru = {
    inherit qtile;
    providedSessions = [
      "qtile-screen-policy"
      "qtile-screen-policy-wayland"
    ];
  };
  meta = {
    description = "Qtile sessions with monitor workspace preferences and a dedicated configuration";
    mainProgram = "qtile-screen-policy";
    platforms = pkgs.lib.platforms.linux;
  };
}
