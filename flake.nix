{
  description = "Simulacrum Game Environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        # Libraries required for software rendering and windowing
        libPath = pkgs.lib.makeLibraryPath [
          pkgs.libGL
          pkgs.libGLU
          pkgs.mesa
          pkgs.xorg.libX11
          pkgs.xorg.libXcursor
          pkgs.xorg.libXrandr
          pkgs.xorg.libXinerama
          pkgs.xorg.libXi
          pkgs.xorg.libXext
          pkgs.xorg.libXfixes
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [ 
            pkgs.godot_4 
            pkgs.mesa 
            pkgs.xvfb-run
          ];
          
          LD_LIBRARY_PATH = libPath;
          
          shellHook = ''
            echo "Simulacrum development environment loaded."
            echo "Run 'godot4' to open the editor or run the game."
            export LIBGL_ALWAYS_SOFTWARE=1
          '';
        };

        apps.default = {
          type = "app";
          program = "${pkgs.writeShellScript "run-simulacrum" ''
            export LIBGL_ALWAYS_SOFTWARE=1
            export LD_LIBRARY_PATH=${libPath}:$LD_LIBRARY_PATH
            
            # If no display is detected, warn the user or try xvfb
            if [ -z "$DISPLAY" ]; then
              echo "No display detected. Running with xvfb-run (headless virtual display)..."
              ${pkgs.xvfb-run}/bin/xvfb-run ${pkgs.godot_4}/bin/godot4 --rendering-driver opengl3 --path . "$@"
            else
              ${pkgs.godot_4}/bin/godot4 --rendering-driver opengl3 --path . "$@"
            fi
          ''}";
        };
      }
    );
}
