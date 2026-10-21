# Custom Qtile build used by ./policy-session.nix, which provides separate sessions
# and a dedicated per-user configuration directory. Import that session package
# with the system's pkgs and add it to services.displayManager.sessionPackages.
# qtileLocal should be a path flake input with flake = false. After source changes,
# update its lock entry and run nixos-rebuild boot to stage the package.
{ pkgs }:
let
  qtile = import ./qtile.nix {
    inherit pkgs;
    self.shortRev = "screenpolicy";
  };
  release = builtins.head (
    builtins.filter (line: pkgs.lib.hasPrefix "Qtile " line) (
      pkgs.lib.splitString "\n" (builtins.readFile ../CHANGELOG)
    )
  );
  version = "${builtins.head (builtins.match "Qtile ([0-9.]+), released .*" release)}+screenpolicy";
in
qtile.overrideAttrs {
  # Retain new local files while leaving VCS metadata and build results out of
  # the immutable source snapshot stored by Nix.
  src = pkgs.lib.cleanSourceWith {
    src = pkgs.lib.cleanSource ./..;
    filter =
      path: type:
      let
        name = builtins.baseNameOf path;
        generatedDirectories = [
          "__pycache__"
          ".pytest_cache"
          ".ruff_cache"
          ".mypy_cache"
          ".venv"
          "build"
          "dist"
        ];
      in
      !(
        type == "directory"
        && (builtins.elem name generatedDirectories || pkgs.lib.hasSuffix ".egg-info" name)
      )
      && !(pkgs.lib.hasSuffix ".pyc" name);
  };
  inherit version;
  name = "qtile-${version}";
  postInstall = qtile.postInstall + ''
    substituteInPlace $out/share/wayland-sessions/qtile.desktop \
      --replace-fail 'Exec=qtile ' 'Exec=${placeholder "out"}/bin/qtile '
  '';
}
