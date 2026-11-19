{ inputs, ... }:

# Acid Boot, patched to relayout when a display appears after the splash starts.
#
# Plymouth keeps one canvas as large as the largest display and updates
# Window.GetWidth()/GetHeight() whenever a display is added. The theme reads them
# once at load, but the eGPU monitors (4K) show up seconds after the laptop panel
# (2880x1800), so everything stayed placed for the smaller canvas. The shutdown
# splash starts with all displays present and was fine.
#
# The script is patched by appending a block (no fork, no anchors to break): it wraps
# the refresh callback, and when the canvas size changes it redoes the logo and the
# positions that depend on it. Imports the module from the patched copy, so it
# replaces `inputs.acid-boot.nixosModules.default` in the host (the copy is built
# at evaluation time).
#
# shortcut: text size keeps the narrowest-display fit of the first layout, which is
# right while the laptop panel is the smallest display; redo it if a narrower display
# can show up later.
let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;

  patched = pkgs.runCommand "acid-boot-egpu" { } ''
    cp -r ${inputs.acid-boot} $out
    chmod -R u+w $out
    cat >> $out/theme/acid-nix.script <<'EOF'

    #------------------------------------------------ relayout on canvas change
    #
    # Plymouth resizes the canvas when a display is added; everything above was
    # placed for the size at load. Redo what depends on it (see the Nix module).

    canvas.w = screen.w;
    canvas.h = screen.h;

    fun relayout_apply() {
      screen.w = Window.GetWidth();
      screen.h = Window.GetHeight();
      min_dim = screen.w;
      if (screen.h < min_dim)
        min_dim = screen.h;

      logo.box = Math.Int(min_dim * 0.26);
      @logoPicker@
      logo.src = Image(logo.file);
      logo.sw = logo.src.GetWidth();
      logo.sh = logo.src.GetHeight();
      if (logo.sw >= logo.sh) {
        logo.w = logo.box;
        logo.h = Math.Int(logo.box * logo.sh / logo.sw);
      } else {
        logo.h = logo.box;
        logo.w = Math.Int(logo.box * logo.sw / logo.sh);
      }
      logo.image = logo.src.Scale(logo.w, logo.h);
      logo.sprite.SetImage(logo.image);
      logo.x = screen.w / 2 - logo.w / 2;
      logo.y = Math.Int(screen.h * 0.36) - logo.h / 2;
      logo.sprite.SetPosition(logo.x, logo.y, 1);

      apply_scale();
      log.x = Math.Int((screen.w - log.w) / 2);
      log_redraw();

      # A passphrase prompt already on screen is placed from the same values.
      if (state.dialog_up) {
        build_dialog();
        sync_slots(0);
        caps_update();
      }
    }

    fun relayout_refresh() {
      if (Window.GetWidth() != canvas.w || Window.GetHeight() != canvas.h) {
        canvas.w = Window.GetWidth();
        canvas.h = Window.GetHeight();
        relayout_apply();
      }
      refresh_callback();
    }

    # Needs the refresh loop, so it is off without acidBoot.animations.
    if (anim.enabled)
      Plymouth.SetRefreshFunction(relayout_refresh);
    EOF
  '';
in
{
  imports = [ (import "${patched}/module.nix") ];
}
