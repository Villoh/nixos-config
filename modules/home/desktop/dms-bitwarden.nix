{
  lib,
  rustPlatform,
  fetchgit,
  runCommandLocal,
}:

# DMS Bitwarden plugin 1.11.6-dms.2 (coldi1337/dms-bitwarden-cli), audited 2026-10-14.
#
# This release ignores bin/ and only runs helpers it finds at <crate>/target/debug/,
# which cannot be built inside the read-only store. So build the three helpers
# from the pinned source and install them at those paths.
let
  src = fetchgit {
    url = "https://github.com/coldi1337/dms-bitwarden-cli";
    rev = "9a74d8a0071d2d2ba8f56e3c9c4907cce27cb8d8";
    hash = "sha256-kWC5z7uraqqkG+4Du1rWXSBR+fq9OAnssR7hE7+Bhpg=";
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
runCommandLocal "dms-plugin-bitwarden-1.11.6-dms.2" { } ''
  cp -r ${src} $out
  chmod -R u+w $out
  # Unattested v1 binary; this release never runs it, so do not ship it.
  rm -rf $out/bin
  ${lib.concatStrings (
    lib.mapAttrsToList (crate: pkg: ''
      mkdir -p $out/${crate}/target/debug
      cp ${pkg}/bin/* $out/${crate}/target/debug/
    '') helpers
  )}
''
