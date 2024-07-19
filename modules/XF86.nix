{lib, ...}:
with lib; {
  options.XF86 = {
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
    modeLock = mkOption {description = "Mode Switch Lock";};

    /*
    Backlight controls.
    */
    monBrightnessUp = mkOption {description = "Monitor/panel brightness";};
    monBrightnessDown = mkOption {description = "Monitor/panel brightness";};
    kbdLightOnOff = mkOption {description = "Keyboards may be lit";};
    kbdBrightnessUp = mkOption {description = "Keyboards may be lit";};
    kbdBrightnessDown = mkOption {description = "Keyboards may be lit";};

    /*
    * Keys found on some "Internet" keyboards.
    */
    standby = mkOption {description = "System into standby mode";};
    audioLowerVolume = mkOption {description = "Volume control down";};
    audioMute = mkOption {description = "Mute sound from the system";};
    audioRaiseVolume = mkOption {description = "Volume control up";};
    audioPlay = mkOption {description = "Start playing of audio";};
    audioStop = mkOption {description = "Stop playing audio";};
    audioPrev = mkOption {description = "Previous track";};
    audioNext = mkOption {description = "Next track";};
    homePage = mkOption {description = "Display user's home page";};
    mail = mkOption {description = "Invoke user's mail program";};
    start = mkOption {description = "Start application";};
    search = mkOption {description = "Search";};
    audioRecord = mkOption {description = "Record audio application";};

    /*
    These are sometimes found on PDA's (e.g. Palm, PocketPC or elsewhere)
    */
    calculator = mkOption {description = "Invoke calculator program";};
    memo = mkOption {description = "Invoke Memo taking program";};
    toDoList = mkOption {description = "Invoke To Do List program";};
    calendar = mkOption {description = "Invoke Calendar program";};
    powerDown = mkOption {description = "Deep sleep the system";};
    contrastAdjust = mkOption {description = "Adjust screen contrast";};
    rockerUp = mkOption {description = "Rocker switches exist up";};
    rockerDown = mkOption {description = "and down";};
    rockerEnter = mkOption {description = "and let you press them";};

    /*
    Some more "Internet" keyboard symbols
    */
    back = mkOption {description = "Like back on a browser";};
    forward = mkOption {description = "Like forward on a browser";};
    stop = mkOption {description = "Stop current operation";};
    refresh = mkOption {description = "Refresh the page";};
    powerOff = mkOption {description = "Power off system entirely";};
    wakeUp = mkOption {description = "Wake up system from sleep";};
    eject = mkOption {description = "Eject device (e.g. DVD)";};
    screenSaver = mkOption {description = "Invoke screensaver";};
    WWW = mkOption {description = "Invoke web browser";};
    sleep = mkOption {description = "Put system to sleep";};
    favorites = mkOption {description = "Show favorite locations";};
    audioPause = mkOption {description = "Pause audio playing";};
    audioMedia = mkOption {description = "Launch media collection app";};
    myComputer = mkOption {description = ''Display "My Computer" window'';};
    vendorHome = mkOption {description = "Display vendor home web site";};
    lightBulb = mkOption {description = "Light bulb keys exist";};
    shop = mkOption {description = "Display shopping web site";};
    history = mkOption {description = "Show history of web surfing";};
    openURL = mkOption {description = "Open selected URL";};
    addFavorite = mkOption {description = "Add URL to favorites list";};
    hotLinks = mkOption {description = ''Show "hot" links'';};
    brightnessAdjust = mkOption {description = "Invoke brightness adj. UI";};
    finance = mkOption {description = "Display financial site";};
    community = mkOption {description = "Display user's community";};
    audioRewind = mkOption {description = ''"rewind" audio track'';};
    backForward = mkOption {description = "???";};
    launch0 = mkOption {description = "Launch Application";};
    launch1 = mkOption {description = "Launch Application";};
    launch2 = mkOption {description = "Launch Application";};
    launch3 = mkOption {description = "Launch Application";};
    launch4 = mkOption {description = "Launch Application";};
    launch5 = mkOption {description = "Launch Application";};
    launch6 = mkOption {description = "Launch Application";};
    launch7 = mkOption {description = "Launch Application";};
    launch8 = mkOption {description = "Launch Application";};
    launch9 = mkOption {description = "Launch Application";};
    launchA = mkOption {description = "Launch Application";};
    launchB = mkOption {description = "Launch Application";};
    launchC = mkOption {description = "Launch Application";};
    launchD = mkOption {description = "Launch Application";};
    launchE = mkOption {description = "Launch Application";};
    launchF = mkOption {description = "Launch Application";};

    applicationLeft = mkOption {description = "switch to application, left";};
    applicationRight = mkOption {description = "switch to application, right";};
    book = mkOption {description = "Launch bookreader";};
    cD = mkOption {description = "Launch CD/DVD player";};
    calculater = mkOption {description = "Launch Calculater";};
    clear = mkOption {description = "Clear window, screen";};
    close = mkOption {description = "Close window";};
    copy = mkOption {description = "Copy selection";};
    cut = mkOption {description = "Cut selection";};
    display = mkOption {description = "Output switch key";};
    dOS = mkOption {description = "Launch DOS (emulation)";};
    documents = mkOption {description = "Open documents window";};
    excel = mkOption {description = "Launch spread sheet";};
    explorer = mkOption {description = "Launch file explorer";};
    game = mkOption {description = "Launch game";};
    go = mkOption {description = "Go to URL";};
    ITouch = mkOption {description = "Logitch iTouch- don't use";};
    logOff = mkOption {description = "Log off system";};
    market = mkOption {description = "??";};
    meeting = mkOption {description = "enter meeting in calendar";};
    menuKB = mkOption {description = "distingush keyboard from PB";};
    menuPB = mkOption {description = "distinuish PB from keyboard";};
    mySites = mkOption {description = "Favourites";};
    new = mkOption {description = "New (folder, document...";};
    news = mkOption {description = "News";};
    officeHome = mkOption {description = "Office home (old Staroffice)";};
    open = mkOption {description = "Open";};
    option = mkOption {description = "??";};
    paste = mkOption {description = "Paste";};
    phone = mkOption {description = "Launch phone; dial number";};
    q = mkOption {description = "Compaq's Q - don't use";};
    reply = mkOption {description = "Reply e.g., mail";};
    reload = mkOption {description = "Reload web page, file, etc.";};
    rotateWindows = mkOption {description = "Rotate windows e.g. xrandr";};
    rotationPB = mkOption {description = "don't use";};
    rotationKB = mkOption {description = "don't use";};
    save = mkOption {description = "Save (file, document, state";};
    scrollUp = mkOption {description = "Scroll window/contents up";};
    scrollDown = mkOption {description = "Scrool window/contentd down";};
    scrollClick = mkOption {description = "Use XKB mousekeys instead";};
    send = mkOption {description = "Send mail, file, object";};
    spell = mkOption {description = "Spell checker";};
    splitScreen = mkOption {description = "Split window or screen";};
    support = mkOption {description = "Get support (??)";};
    taskPane = mkOption {description = "Show tasks";};
    terminal = mkOption {description = "Launch terminal emulator";};
    tools = mkOption {description = "toolbox of desktop/app.";};
    travel = mkOption {description = "??";};
    userPB = mkOption {description = "??";};
    user1KB = mkOption {description = "??";};
    user2KB = mkOption {description = "??";};
    video = mkOption {description = "Launch video player";};
    wheelButton = mkOption {description = "button from a mouse wheel";};
    word = mkOption {description = "Launch word processor";};
    xfer = mkOption {description = "??";};
    zoomIn = mkOption {description = "zoom in view, map, etc.";};
    zoomOut = mkOption {description = "zoom out view, map, etc.";};

    away = mkOption {description = "mark yourself as away";};
    messenger = mkOption {description = "as in instant messaging";};
    webCam = mkOption {description = "Launch web camera app.";};
    mailForward = mkOption {description = "Forward in mail";};
    pictures = mkOption {description = "Show pictures";};
    music = mkOption {description = "Launch music application";};

    battery = mkOption {description = "Display battery information";};
    bluetooth = mkOption {description = "Enable/disable Bluetooth";};
    wLAN = mkOption {description = "Enable/disable WLAN";};
    uWB = mkOption {description = "Enable/disable UWB";};

    audioForward = mkOption {description = "fast-forward audio track";};
    audioRepeat = mkOption {description = "toggle repeat mode";};
    audioRandomPlay = mkOption {description = "toggle shuffle mode";};
    subtitle = mkOption {description = "cycle through subtitle";};
    audioCycleTrack = mkOption {description = "cycle through audio tracks";};
    cycleAngle = mkOption {description = "cycle through angles";};
    frameBack = mkOption {description = "video: go one frame back";};
    frameForward = mkOption {description = "video: go one frame forward";};
    time = mkOption {description = "display, or shows an entry for time seeking";};
    select = mkOption {description = "Select button on joypads and remotes";};
    view = mkOption {description = "Show a view options/properties";};
    topMenu = mkOption {description = "Go to a top-level menu in a video";};

    red = mkOption {description = "Red button";};
    green = mkOption {description = "Green button";};
    yellow = mkOption {description = "Yellow button";};
    blue = mkOption {description = "Blue button";};

    suspend = mkOption {description = "Sleep to RAM";};
    hibernate = mkOption {description = "Sleep to disk";};
    touchpadToggle = mkOption {description = "Toggle between touchpad/trackstick";};
    touchpadOn = mkOption {description = "The touchpad got switched on";};
    touchpadOff = mkOption {description = "The touchpad got switched off";};

    audioMicMute = mkOption {description = "Mute the Mic from the system";};

    keyboard = mkOption {description = "User defined keyboard related action";};

    WWAN = mkOption {description = "Toggle WWAN (LTE, UMTS, etc.) radio";};
    RFKill = mkOption {description = "Toggle radios on/off";};

    audioPreset = mkOption {description = "Select equalizer preset, e.g. theatre-mode";};

    /*
    Keys for special action keys (hot keys)
    */
    /*
    Virtual terminals on some operating systems
    */
    switchVT1 = mkOption {description = "Virtual terminal 1";};
    switchVT2 = mkOption {description = "Virtual terminal 2";};
    switchVT3 = mkOption {description = "Virtual terminal 3";};
    switchVT4 = mkOption {description = "Virtual terminal 4";};
    switchVT5 = mkOption {description = "Virtual terminal 5";};
    switchVT6 = mkOption {description = "Virtual terminal 6";};
    switchVT7 = mkOption {description = "Virtual terminal 7";};
    switchVT8 = mkOption {description = "Virtual terminal 8";};
    switchVT9 = mkOption {description = "Virtual terminal 9";};
    switchVT10 = mkOption {description = "Virtual terminal 10";};
    switchVT11 = mkOption {description = "Virtual terminal 11";};
    switchVT12 = mkOption {description = "Virtual terminal 12";};

    ungrab = mkOption {description = "force ungrab";};
    clearGrab = mkOption {description = "kill application with grab";};
    nextVMode = mkOption {description = "next video mode available";};
    prevVMode = mkOption {description = "prev. video mode available";};
    logWindowTree = mkOption {description = "print window tree to log";};
    logGrabInfo = mkOption {description = "print all active grabs to log";};
  };
}
