# Zed Editor Flake

This repository provides a Nix flake for the [Zed Editor](https://zed.dev/), a high-performance, multiplayer code editor from the creators of Atom and Tree-sitter.

## Available Packages

This flake provides the following packages:

- `zed-editor`: Built from source version of the latest stable release
- `zed-editor-bin`: Pre-built binaries from upstream of the latest stable release
- `zed-editor-fhs`: FHS-compatible environment for `zed-editor`
- `zed-editor-bin-fhs`: FHS-compatible environment for `zed-editor-bin`
- `zed-editor-preview`: Built from source version of the latest preview release
- `zed-editor-preview-bin`: Pre-built binaries from upstream of the latest preview release
- `zed-editor-preview-fhs`: FHS-compatible environment for `zed-editor-preview`
- `zed-editor-preview-bin-fhs`: FHS-compatible environment for `zed-editor-preview-bin`

## Usage

### Running with Nix Run

You can run the editor directly without installing it:

```sh
# Latest stable release (built from source)
nix run github:shekhirin/zed-editor-flake

# Latest stable release (pre-built binary)
nix run github:shekhirin/zed-editor-flake#zed-editor-bin

# Latest stable release in an FHS environment
nix run github:shekhirin/zed-editor-flake#zed-editor-fhs

# Latest preview release (built from source)
nix run github:shekhirin/zed-editor-flake#zed-editor-preview

# Latest preview release (pre-built binary)
nix run github:shekhirin/zed-editor-flake#zed-editor-preview-bin
```

### Adding to Your Configuration

In your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    zed-editor-flake.url = "github:shekhirin/zed-editor-flake";
  };

  outputs = { self, nixpkgs, zed-editor-flake, ... }:
  let
    # Example for a single system
    system = "x86_64-linux"; # Or "aarch64-linux", "x86_64-darwin", "aarch64-darwin"
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    # Example for NixOS configuration
    nixosConfigurations.yourHostname = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ({ config, pkgs, ... }: {
          environment.systemPackages = [
            zed-editor-flake.packages.${system}.zed-editor # Or zed-editor-bin, zed-editor-preview, etc.
          ];
        })
      ];
    };

    # Example for home-manager configuration
    homeConfigurations.yourUsername = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        {
          home.packages = [
            zed-editor-flake.packages.${system}.zed-editor # Or zed-editor-bin, zed-editor-preview, etc.
          ];
        }
      ];
    };
  };
}
```

## Automated Updates

This repository uses GitHub Actions to automatically check for new Zed Editor releases (both stable and preview) and update the corresponding Nix packages.

### Update Workflow

The automated update workflow performs the following steps:

1.  **Checks for new releases:** On a schedule (Monday and Thursday at 12:00 UTC) or when manually triggered, the workflow checks the Zed Editor GitHub repository for the latest stable and preview releases.
2.  **Updates package versions:** If new versions are found, the `version` attribute is updated in the `default.nix` files for:
    *   `zed-editor` and `zed-editor-bin` (for stable releases)
    *   `zed-editor-preview` and `zed-editor-preview-bin` (for preview releases)
3.  **Updates source hashes:** The source tarball hash (`hash`) is updated for:
    *   `zed-editor` (for stable releases)
    *   `zed-editor-preview` (for preview releases)
4.  **Updates binary hashes:** The pre-built binary hashes (`sha256`) for each supported system are updated for:
    *   `zed-editor-bin` (for stable releases)
    *   `zed-editor-preview-bin` (for preview releases)
5.  **Updates Cargo hashes:** The `cargoHash` (for vendored dependencies) is updated for:
    *   `zed-editor` (for stable releases)
    *   `zed-editor-preview` (for preview releases)
6.  **Updates flake lock file:** `nix flake update` is run to refresh the `flake.lock` file.
7.  **Creates a pull request:** A pull request is automatically created with all the changes, detailing the versions updated and the new hashes.

### Manual Trigger

You can manually trigger the update workflow through the GitHub Actions interface:

1.  Navigate to the "Actions" tab in the repository.
2.  Select the "Update Zed Editor Packages" workflow from the sidebar.
3.  Click the "Run workflow" dropdown button.
4.  Optionally, you can:
    *   Specify a **Specific stable version to update to** (e.g., `0.180.0`).
    *   Specify a **Specific preview version to update to** (e.g., `0.181.0-pre`).
    *   Check **Force check for updates** to run the update process even if the latest fetched version matches the current version in the flake (useful for re-calculating hashes if a release asset was changed upstream).
5.  Click "Run workflow".

## Contributing

Contributions are welcome! If you find any issues or have suggestions for improvements, please open an issue or submit a pull request. Please feel free to submit a pull request.
