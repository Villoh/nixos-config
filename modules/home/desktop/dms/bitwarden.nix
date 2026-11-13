{
  lib,
  rustPlatform,
  fetchgit,
  runCommandLocal,
}:

# DMS Bitwarden plugin 1.11.6-dms.7 (coldi1337/dms-bitwarden-cli), audited 2026-11-12
# (diff vs 1.11.6-dms.6: QML/JS/docs/tests only; the three Rust crates are byte-identical).
# dms.7 opens pinentry a tick later, which also stops a Dux 2.x crash: hiding the
# panel while its popout window was being created (quickshell#620).
#
# This release ignores bin/ and only runs helpers it finds at <crate>/target/debug/,
# which cannot be built inside the read-only store. So build the three helpers
# from the pinned source and install them at those paths.
let
  src = fetchgit {
    url = "https://github.com/coldi1337/dms-bitwarden-cli";
    rev = "d449d6575e7f396361b2439cda65f2a70928923c";
    hash = "sha256-ia9d2XXIGLvThN89f4X3fAitWmdwXEezpwNLwKppB1k=";
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
runCommandLocal "dms-plugin-bitwarden-1.11.6-dms.7" { } ''
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
