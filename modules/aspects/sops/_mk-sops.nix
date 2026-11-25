{
  lib,
  root,
  ...
}: let
  not = f: !f;
  isIgnored = f:
    lib.pipe f [
      toString
      (f: (lib.hasInfix "/." f) || (lib.hasInfix "/_" f))
      not
    ];
  filterPaths = l: lib.filter isIgnored l;
  toRelativePath = lib.removePrefix (toString root + "/");
  splitPath = lib.splitString "/";
  readPathToAttrs = p:
    lib.setAttrByPath
    (lib.pipe p [
      toString
      toRelativePath
      splitPath
    ])
    (lib.fileContents p);
  # 6;
  concatPathsToAttrs = l: lib.foldl' lib.recursiveUpdate {} (map readPathToAttrs l);
in (lib.pipe root [
  lib.filesystem.listFilesRecursive
  filterPaths
  concatPathsToAttrs
  lib.toJSON
])
