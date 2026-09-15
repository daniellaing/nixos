{nixpkgs, ...}: {
  default = nixpkgs.lib.composeManyExtensions [
    (final: prev: {
      mkHomeUsers = usersDir: args: users:
        prev.genAttrs
        (builtins.filter (user: prev.pathExists (usersDir + "/${user}")) users)
        (user: import (usersDir + "/${user}") args);
    })
  ];
}
