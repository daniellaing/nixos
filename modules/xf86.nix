{lib, ...}: let
  capitalise = str: (lib.toUpper (lib.substring 0 1 str)) + (lib.substring 1 (-1) str);
in {
  modules.xf86 = {
    config.home-manager.sharedModules = [
      {
        options.xf86 =
          lib.mapAttrs (name: description:
            lib.mkOption {
              inherit description;
              type = lib.types.submodule {
                options = {
                  cmd = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = null;
                    description = "Command to run.";
                  };

                  keycode = lib.mkOption {
                    type = lib.types.str;
                    readOnly = true;
                    default = "XF86${capitalise name}";
                    description = "XF86 keycode for ${name}.";
                  };
                };
              };
            })
          {
            /*
            * XFree86 vendor specific keysyms.
            *
            * The XFree86 keysym range is 0x10080001 - 0x1008FFFF.
            *
            * X.Org will not be adding to the XF86 set of keysyms, though they have
            * been adopted and are considered a "standard" part of X keysym definitions.
            * XFree86 never properly commented these keysyms, so we have done our
            * best to explain the semantic meaning of these keys.
            *
            * XFree86 has removed their mail archives of the period, that might have
            * shed more light on some of these definitions. Until/unless we resurrect
            * these archives, these are from memory and usage.
            */

            /*
            * ModeLock
            *
            * This one is old, and not really used any more since XKB offers this
            * functionality.
            */
            modeLock = "Mode Switch Lock";

            /*
            Backlight controls.
            */
            monBrightnessUp = "Monitor/panel brightness";
            monBrightnessDown = "Monitor/panel brightness";
            kbdLightOnOff = "Keyboards may be lit";
            kbdBrightnessUp = "Keyboards may be lit";
            kbdBrightnessDown = "Keyboards may be lit";

            /*
            * Keys found on some "Internet" keyboards.
            */
            standby = "System into standby mode";
            audioLowerVolume = "Volume control down";
            audioMute = "Mute sound from the system";
            audioRaiseVolume = "Volume control up";
            audioPlay = "Start playing of audio";
            audioStop = "Stop playing audio";
            audioPrev = "Previous track";
            audioNext = "Next track";
            homePage = "Display user's home page";
            mail = "Invoke user's mail program";
            start = "Start application";
            search = "Search";
            audioRecord = "Record audio application";

            /*
            These are sometimes found on PDA's (e.g. Palm, PocketPC or elsewhere)
            */
            calculator = "Invoke calculator program";
            memo = "Invoke Memo taking program";
            toDoList = "Invoke To Do List program";
            calendar = "Invoke Calendar program";
            powerDown = "Deep sleep the system";
            contrastAdjust = "Adjust screen contrast";
            rockerUp = "Rocker switches exist up";
            rockerDown = "and down";
            rockerEnter = "and let you press them";

            /*
            Some more "Internet" keyboard symbols
            */
            back = "Like back on a browser";
            forward = "Like forward on a browser";
            stop = "Stop current operation";
            refresh = "Refresh the page";
            powerOff = "Power off system entirely";
            wakeUp = "Wake up system from sleep";
            eject = "Eject device (e.g. DVD)";
            screenSaver = "Invoke screensaver";
            WWW = "Invoke web browser";
            sleep = "Put system to sleep";
            favorites = "Show favorite locations";
            audioPause = "Pause audio playing";
            audioMedia = "Launch media collection app";
            myComputer = ''Display "My Computer" window'';
            vendorHome = "Display vendor home web site";
            lightBulb = "Light bulb keys exist";
            shop = "Display shopping web site";
            history = "Show history of web surfing";
            openURL = "Open selected URL";
            addFavorite = "Add URL to favorites list";
            hotLinks = ''Show "hot" links'';
            brightnessAdjust = "Invoke brightness adj. UI";
            finance = "Display financial site";
            community = "Display user's community";
            audioRewind = ''"rewind" audio track'';
            backForward = "???";
            launch0 = "Launch Application";
            launch1 = "Launch Application";
            launch2 = "Launch Application";
            launch3 = "Launch Application";
            launch4 = "Launch Application";
            launch5 = "Launch Application";
            launch6 = "Launch Application";
            launch7 = "Launch Application";
            launch8 = "Launch Application";
            launch9 = "Launch Application";
            launchA = "Launch Application";
            launchB = "Launch Application";
            launchC = "Launch Application";
            launchD = "Launch Application";
            launchE = "Launch Application";
            launchF = "Launch Application";

            applicationLeft = "switch to application, left";
            applicationRight = "switch to application, right";
            book = "Launch bookreader";
            cD = "Launch CD/DVD player";
            calculater = "Launch Calculater";
            clear = "Clear window, screen";
            close = "Close window";
            copy = "Copy selection";
            cut = "Cut selection";
            display = "Output switch key";
            dOS = "Launch DOS (emulation)";
            documents = "Open documents window";
            excel = "Launch spread sheet";
            explorer = "Launch file explorer";
            game = "Launch game";
            go = "Go to URL";
            ITouch = "Logitch iTouch- don't use";
            logOff = "Log off system";
            market = "??";
            meeting = "enter meeting in calendar";
            menuKB = "distingush keyboard from PB";
            menuPB = "distinuish PB from keyboard";
            mySites = "Favourites";
            new = "New (folder, document...";
            news = "News";
            officeHome = "Office home (old Staroffice)";
            open = "Open";
            option = "??";
            paste = "Paste";
            phone = "Launch phone; dial number";
            q = "Compaq's Q - don't use";
            reply = "Reply e.g., mail";
            reload = "Reload web page, file, etc.";
            rotateWindows = "Rotate windows e.g. xrandr";
            rotationPB = "don't use";
            rotationKB = "don't use";
            save = "Save (file, document, state";
            scrollUp = "Scroll window/contents up";
            scrollDown = "Scrool window/contentd down";
            scrollClick = "Use XKB mousekeys instead";
            send = "Send mail, file, object";
            spell = "Spell checker";
            splitScreen = "Split window or screen";
            support = "Get support (??)";
            taskPane = "Show tasks";
            terminal = "Launch terminal emulator";
            tools = "toolbox of desktop/app.";
            travel = "??";
            userPB = "??";
            user1KB = "??";
            user2KB = "??";
            video = "Launch video player";
            wheelButton = "button from a mouse wheel";
            word = "Launch word processor";
            xfer = "??";
            zoomIn = "zoom in view, map, etc.";
            zoomOut = "zoom out view, map, etc.";

            away = "mark yourself as away";
            messenger = "as in instant messaging";
            webCam = "Launch web camera app.";
            mailForward = "Forward in mail";
            pictures = "Show pictures";
            music = "Launch music application";

            battery = "Display battery information";
            bluetooth = "Enable/disable Bluetooth";
            wLAN = "Enable/disable WLAN";
            uWB = "Enable/disable UWB";

            audioForward = "fast-forward audio track";
            audioRepeat = "toggle repeat mode";
            audioRandomPlay = "toggle shuffle mode";
            subtitle = "cycle through subtitle";
            audioCycleTrack = "cycle through audio tracks";
            cycleAngle = "cycle through angles";
            frameBack = "video: go one frame back";
            frameForward = "video: go one frame forward";
            time = "display, or shows an entry for time seeking";
            select = "Select button on joypads and remotes";
            view = "Show a view options/properties";
            topMenu = "Go to a top-level menu in a video";

            red = "Red button";
            green = "Green button";
            yellow = "Yellow button";
            blue = "Blue button";

            suspend = "Sleep to RAM";
            hibernate = "Sleep to disk";
            touchpadToggle = "Toggle between touchpad/trackstick";
            touchpadOn = "The touchpad got switched on";
            touchpadOff = "The touchpad got switched off";

            audioMicMute = "Mute the Mic from the system";

            keyboard = "User defined keyboard related action";

            WWAN = "Toggle WWAN (LTE, UMTS, etc.) radio";
            RFKill = "Toggle radios on/off";

            audioPreset = "Select equalizer preset, e.g. theatre-mode";

            /*
            Keys for special action keys (hot keys)
            */
            /*
            Virtual terminals on some operating systems
            */
            switchVT1 = "Virtual terminal 1";
            switchVT2 = "Virtual terminal 2";
            switchVT3 = "Virtual terminal 3";
            switchVT4 = "Virtual terminal 4";
            switchVT5 = "Virtual terminal 5";
            switchVT6 = "Virtual terminal 6";
            switchVT7 = "Virtual terminal 7";
            switchVT8 = "Virtual terminal 8";
            switchVT9 = "Virtual terminal 9";
            switchVT10 = "Virtual terminal 10";
            switchVT11 = "Virtual terminal 11";
            switchVT12 = "Virtual terminal 12";

            ungrab = "force ungrab";
            clearGrab = "kill application with grab";
            nextVMode = "next video mode available";
            prevVMode = "prev. video mode available";
            logWindowTree = "print window tree to log";
            logGrabInfo = "print all active grabs to log";
          };
      }
    ];
  };
}
