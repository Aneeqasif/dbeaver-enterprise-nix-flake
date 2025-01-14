## cd YOUR_FLAKE_FOLDER/dbeaver-ee/
## Build Flake: export NIXPKGS_ALLOW_UNFREE=1 && nix build .#dbeaver-ee --impure
## Run Local Flake: ./result/bin/dbeaver
## Inspired by: https://github.com/NixOS/nixpkgs/blob/108bdac3d99b6d94d3740422af5945e510238304/pkgs/applications/misc/dbeaver/default.nix
{
  description = "A flake for DBeaver Enterprise Edition";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs =
    { self
    , nixpkgs
    ,
    }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      inherit (pkgs) stdenv fetchurl makeDesktopItem makeWrapper autoPatchelfHook fontconfig freetype glib gtk3 jdk17 lib xorg zlib;
    in
    {
      packages.x86_64-linux.dbeaver-ee = stdenv.mkDerivation rec {
        pname = "dbeaver-ee";
        version = "24.3.0";

        desktopItem = makeDesktopItem {
          name = "dbeaver-ee";
          exec = "dbeaver";
          icon = "dbeaver";
          desktopName = "dbeaver-ee";
          comment = "SQL Integrated Development Environment";
          genericName = "SQL Integrated Development Environment";
          categories = [ "Development" ];
        };

        buildInputs = [
          fontconfig
          freetype
          glib
          gtk3
          jdk17
          xorg.libX11
          xorg.libXrender
          xorg.libXtst
          zlib
        ];

        nativeBuildInputs = [
          makeWrapper
          autoPatchelfHook
        ];

        src = pkgs.fetchurl {
          url = "https://dbeaver.com/files/${version}/dbeaver-ee-${version}-linux.gtk.x86_64.tar.gz";
          sha256 = "sha256-fYzw9QfKhApa1g7awEKhPUQzUsFt/+z5t24aXzyj1Qs=";
        };

        installPhase = ''
          # Remove the bundled Java Runtime Environment as we will use our own.
          rm -rf jre

          # Create the directory where DBeaver will reside within the Nix store.
          mkdir -p $out/

          # Copy all the files from the build directory to the Nix store.
          cp -r . $out/dbeaver

          # The binaries will be automatically patched by autoPatchelfHook.
          # This adds necessary runtime dependencies to the ELF files.

          # Create a wrapper script for launching DBeaver.
          # - Sets Java path
          # - Sets library path for GTK and X11
          # - Sets GSettings schema path
          makeWrapper $out/dbeaver/dbeaver $out/bin/dbeaver \
            --prefix PATH : ${jdk17}/bin \
            --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [glib gtk3 xorg.libXtst]} \
            --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"

          # Create a directory for the desktop entry.
          mkdir -p $out/share/applications

          # Copy the generated desktop entry to the appropriate location.
          cp ${desktopItem}/share/applications/* $out/share/applications

          # Create a directory for storing the DBeaver icon.
          mkdir -p $out/share/pixmaps

          # Symlink the DBeaver icon to the standard location.
          ln -s $out/dbeaver/icon.xpm $out/share/pixmaps/dbeaver.xpm
        '';

        meta = with lib; {
          homepage = "https://dbeaver.io/";
          description = "Universal SQL Client for developers, DBA and analysts. Supports MySQL, PostgreSQL, MariaDB, SQLite, and more";
          longDescription = ''
            Multi-platform database tool for developers, SQL programmers, database
            administrators and analysts. Supports all popular databases: MySQL,
            PostgreSQL, MariaDB, SQLite, Oracle, DB2, SQL Server, Sybase, MS Access,
            Teradata, Firebird, Derby, etc.
          '';
          license = licenses.unfree;
          platforms = [ "x86_64-linux" ];
          maintainers = [ maintainers.berts83231 ];
        };
      };
    };
}
