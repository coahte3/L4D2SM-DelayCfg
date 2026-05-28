#include <sourcemod>

// Variables to store Cvars (4 total)
ConVar g_cvarEnable;
ConVar g_cvarTime;
ConVar g_cvarCommand;
ConVar g_cvarMessage;

public Plugin myinfo = 
{
    name = "DelayCfg",
    author = "coah & GoogleAI",
    description = "A Cvar-configurable map launch delay execution plugin (with messaging functionality)",
    version = "1.7",
    url = ""
};

public void OnPluginStart()
{
    // Create and register the 4 Cvars
    g_cvarEnable  = CreateConVar("sm_delayexec_enable", "1", "Enable (1) / Disable (0) the plugin", _, true, 0.0, true, 1.0);
    g_cvarTime    = CreateConVar("sm_delayexec_time", "3.0", "Number of seconds to delay execution after map start", _, true, 0.1);
    
    // ★ Changed default value to "exec DelayCfgExample"
    g_cvarCommand = CreateConVar("sm_delayexec_command", "exec DelayCfgExample", "The command or .cfg file name to execute");
    
    g_cvarMessage = CreateConVar("sm_delayexec_message", "0", "Show (1) / Hide (0) notification message in chat on execution", _, true, 0.0, true, 1.0);

    // Automatically generate the plugin config (cfg/sourcemod/DelayCfg.cfg)
    AutoExecConfig(true, "DelayCfg");
}

public void OnMapStart()
{
    // Do nothing if the plugin is disabled
    if (!g_cvarEnable.BoolValue)
    {
        return;
    }

    // Read the delay time from the Cvar and start the timer
    float delayTime = g_cvarTime.FloatValue;
    CreateTimer(delayTime, Timer_ExecuteCommand);
}

public Action Timer_ExecuteCommand(Handle timer)
{
    // Re-check if the plugin is still enabled at the time of execution
    if (!g_cvarEnable.BoolValue)
    {
        return Plugin_Stop;
    }

    // Read the command string to be executed from the Cvar
    char commandString[256];
    g_cvarCommand.GetString(commandString, sizeof(commandString));

    // Execute the command
    if (strlen(commandString) > 0)
    {
        ServerCommand("%s", commandString);
        
        // Record into the server-side log
        LogMessage("[DelayExec] Executed command: %s", commandString);
        
        // Send a notification to all players in chat only when the message Cvar is set to "1"
        if (g_cvarMessage.BoolValue)
        {
            PrintToChatAll("\x01[\x04DelayExec\x01] %.1f seconds have passed since map start. Executed the following command: \x03%s", g_cvarTime.FloatValue, commandString);
        }
    }
    
    return Plugin_Stop;
}
