{ pkgs }:

pkgs.mkShell {
  packages = with pkgs; [
    nodejs
    yarn
    npm
    pnpm
  ];

  # optional: environment tweaks
  shellHook = ''
    echo "🟢 Node.js dev shell ready!"
    echo "node version: $(node -v)"
    echo "npm version: $(npm -v)"
  '';
}

