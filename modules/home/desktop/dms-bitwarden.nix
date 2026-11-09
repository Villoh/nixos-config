{
  lib,
  rustPlatform,
  fetchgit,
  runCommandLocal,
}:

# DMS Bitwarden plugin 1.11.6-dms.6 (coldi1337/dms-bitwarden-cli), audited 2026-11-09
# (diff vs 1.11.6-dms.2: QML/JS/docs only; the three Rust crates are byte-identical).
#
# This release ignores bin/ and only runs helpers it finds at <crate>/target/debug/,
# which cannot be built inside the read-only store. So build the three helpers
# from the pinned source and install them at those paths.
let
  src = fetchgit {
    url = "https://github.com/coldi1337/dms-bitwarden-cli";
    rev = "528175fc46ec50a5b8670fdb40553c9fc18da201";
    hash = "sha256-/cL2DivIE9KPr/P+vnricT/fcb5pngszG5mkaXRYJJ0=";
  };

  helper =
    crate: bin:
    rustPlatform.buildRustPackage {
      pname = bin;
      version = "0.1.0";
      inherit src;
      sourceRoot = "${src.name}/${crate}";
      cargoLock.lockFile = "${src}/${crate}/Cargo.lock";
      # Upstream tests need ssh, bw and a keyring; the helper's own self-test
      # runs below instead.
      doCheck = false;
      doInstallCheck = true;
      installCheckPhase = ''
        $out/bin/${bin} --self-test
      '';
    };

  helpers = {
    agent = helper "agent" "qs-bitwarden-ssh-agent";
    vault = helper "vault" "qs-bitwarden-vault";
    unlock-key = helper "unlock-key" "qs-bitwarden-unlock-key";
  };
in
runCommandLocal "dms-plugin-bitwarden-1.11.6-dms.6" { } ''
  cp -r ${src} $out
  chmod -R u+w $out
  # Unattested v1 binary; this release never runs it, so do not ship it.
  rm -rf $out/bin
  ${lib.concatStrings (
    lib.mapAttrsToList (crate: pkg: ''
      mkdir -p $out/${crate}/target/debug
      cp ${pkg}/bin/* $out/${crate}/target/debug/
      # The plugin warns about helpers without a source record (since dms.3).
      bash $out/scripts/helper-source-hash.sh $out/${crate} \
        > $out/${crate}/target/debug/${pkg.pname}.source-sha256
    '') helpers
  )}
''
