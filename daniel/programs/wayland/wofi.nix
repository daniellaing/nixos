{
  config,
  pkgs,
  ...
}:
with config.colorScheme.palette; {
  programs.wofi = {
    enable = true;
    settings = {
      mode = "drun";
      allow_images = true;
      image_size = 40;
      insensitive = true;
      location = "center";
      no_actions = true;
      prompt = "Search";
      term = "${config.programs.terminal}";
    };

    style = ''
      * {
          font-family: JetBrainsMono Nerd Font, FontAwesome;
          font-size: 17px;
          border-radius: 10px;
          border: none;
      }

      window {
          margin: 0px;
          background: #${base00};
          color: #${base06};
      	  border-radius: 15px;
          border-color: #${base01}
      }

      #outer-box {
          margin: 0px;
          border-radius: 0px;
      }

      #input {
          background-color: #${base03};
          color: #${base06};
          margin: 15px;
          padding: 10px;
          border: none;
      }

      #inner-box {
          margin: 20px;
          padding: 0px;
          border-radius: 0px;
          background: transparent;
      }

      #scroll {
          margin: 0px;
          padding: 0px;
          border: none;
      }

      #text {
          margin-left: 15px;
          margin-right: 15px;
      }

      #entry {
          border: none;
          padding: 10px;
          margin: 0px;
      }

      #entry:selected {
          background: #${base0F};
          color: #${base00};
      }
    '';
  };
}
