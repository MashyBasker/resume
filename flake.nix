{
  description = "A Nix-based resume setup";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs }:
    let
      # System architecture to build for
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      
      # LaTeX environment with necessary packages
      texLive = pkgs.texlive.combine {
        inherit (pkgs.texlive) 
          scheme-medium
          latexmk 
          enumitem 
          titlesec 
          biblatex 
          collection-fontsrecommended
          collection-fontsextra
          collection-fontutils
          # Choose one of the following based on your needs:
          # For pdfLaTeX (more compatible):
          # collection-latex
          # Or for LuaLaTeX (if you need advanced typography):
          luatex
          geometry
          xcolor
          fontspec
          luaotfload;
      };
      
      # A package for latexindent, needed for the pre-commit hook
      latexindent = pkgs.perl538Packages.LatexIndent;
    in
    {
      # Default package to build (the resume PDF)
      packages.${system}.default = pkgs.stdenv.mkDerivation {
        name = "resume";
        src = ./.;
        nativeBuildInputs = [
          texLive
        ];
        buildPhase = ''
          runHook preBuild
          latexmk -pdf resume.tex
          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall
          mkdir -p $out/
          cp resume.pdf $out/resume.pdf
          runHook postInstall
        '';
      };
      
      # Development shell
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          # TeX Live environment
          texLive
          # Additional tools you requested
          pkgs.gnumake
          pkgs.pre-commit
          latexindent
          # A good PDF viewer for development
          pkgs.zathura
        ];
        
        shellHook = ''
          echo "Welcome to your resume development environment!"
          echo "Run 'latexmk -pdf resume.tex' for pdfLaTeX (recommended)"
          echo "Or 'latexmk -lualatex resume.tex' for LuaLaTeX"
          echo "Add '-pvc' flag for auto-recompilation on file changes"
          echo "To set up formatting on commit, run: pre-commit install"
        '';
      };
    };
}