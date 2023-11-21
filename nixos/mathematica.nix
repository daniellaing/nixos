{ pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs.stable; [
    mathematica
  ];

  environment.variables = {
    QT_XCB_GL_INTEGRATION = "none";
  };
}
