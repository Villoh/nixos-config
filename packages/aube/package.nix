{
  lib,
  fetchFromGitHub,
  rustPlatform,
  cacert,
  aws-lc,
  zstd,
  cmake,
  pkg-config,
  gitMinimal,
  writableTmpDirAsHomeHook,
  nodejs,
  versionCheckHook,
  nix-update-script,
}:

# Copied from nixpkgs (pkgs/by-name/au/aube, with "aube: add missing dependencies"):
# nixpkgs runs behind upstream. Built from source, so it waits for a binary cache; meanwhile
# the system uses aube-bin (packages/prebuilt/aube). To switch, uncomment `aube` in
# ../default.nix and swap the lines marked "PENDING: cache" in
# modules/home/development/packages.nix; drop this directory once nixpkgs catches up.
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "aube";
  version = "2.10.0";

  src = fetchFromGitHub {
    owner = "aubepkg";
    repo = "aube";
    tag = "v${finalAttrs.version}";
    hash = "sha256-rPEDoDNhyxQKZYyG1xMYku71YzOAyqTj62FFw0fS7F8=";
  };

  cargoHash = "sha256-3uYVdgGgKTCfX8Lf+4CCVM7qbzYBMBxYDmi/l9DNVrk=";

  buildInputs = [
    aws-lc
    zstd
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
  ]; # libz-ng-sys

  nativeCheckInputs = [
    gitMinimal
    writableTmpDirAsHomeHook
    nodejs # the e2e tests (2.x) run node on the installed tree
  ];

  postInstall = ''
    rm -f $out/bin/generate-{error-codes,settings}-docs
  '';

  checkFlags = [
    # failed on x86_64-linux
    "--skip=concurrency::tests::floor_and_ceiling_inclusive"
    "--skip=http::ticket_cache::tests::max_per_host_evicts_oldest"
    "--skip=http::ticket_cache::tests::invalidate_removes_all_for_host"
    # require network access
    "--skip=http::ticket_cache::tests::roundtrip_persists_across_open"
    # failed at 2.10.0 in the sandbox: the clap conflict test expects another message,
    # the popularity corpus is not in the source tarball, and the shim test needs a
    # native target it cannot find
    "--skip=cli_spec_tests::add_rejects_deny_build_with_dangerously_allow_all_builds"
    "--skip=commands::add_supply_chain::tests::bundled_corpus_detects_common_package_typo"
    "--skip=commands::exec::tests::bin_command_executes_native_target_behind_generated_shim"
    # run /bin/echo, which the build sandbox does not have
    "--skip=sys::tests::bound_node_leaves_other_interpreters_and_native_bins_alone"
    "--skip=spawn_program_tests::spawn_program_runs_the_program_with_its_args"
  ];

  __darwinAllowLocalNetworking = true;

  env.SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  passthru.updateScript = nix-update-script { extraArgs = [ "--use-github-releases" ]; };

  __structuredAttrs = true;

  meta = {
    description = "Fast Node.js package manager";
    homepage = "https://github.com/aubepkg/aube";
    changelog = "https://github.com/aubepkg/aube/blob/${finalAttrs.src.tag}/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "aube";
  };
})
