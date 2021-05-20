class XUIConfigManager {

    static bool reloaderEnable = true; // configuration avec reloader

    static bool verboseXUIEngine = false;
    static bool verboseTree = false;
    static bool verboseTreeImpl = false;
    static bool verboseSlotInfo = false;
    static bool verboseGetXUIComponent = false;
    static bool verboseChange = false;
    static bool verboseEditor = false;
    static bool verboseReloader = false;
    static bool forceSlotInfo = false;  // pour la generation du template de json

    static printc(Object object)
    {
        print("==>> "+object);
    }
}