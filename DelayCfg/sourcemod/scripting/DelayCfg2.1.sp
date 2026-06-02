#include <sourcemod>

// --- 変数の宣言 ---
ConVar g_cvarEnable;
ConVar g_cvarTime;
ConVar g_cvarCommand;
ConVar g_cvarMessage;
ConVar g_cvarMode; 
bool g_bHasExecutedThisMap = false;

public Plugin myinfo = 
{
    name = "DelayCfg",
    author = "coah & GoogleAI",
    description = "A Cvar-configurable player spawn delay execution plugin",
    version = "2.1",
    url = ""
};

// --- ここから下がプラグインのメインの仕組みだよ ---
public void OnPluginStart()
{
    // 設定（Cvar）を登録するよ。説明文入りだから自動で.cfgが作られるよ！
    g_cvarEnable  = CreateConVar("sm_delayexec_enable", "1", "プラグインの有効(1)/無効(0)切り替え", _, true, 0.0, true, 1.0);
    g_cvarTime    = CreateConVar("sm_delayexec_time", "3.0", "スポーンから実行までの遅延秒数", _, true, 0.1);
    g_cvarCommand = CreateConVar("sm_delayexec_command", "exec DelayCfgExample", "実行するコマンドまたは.cfgファイル名");
    g_cvarMessage = CreateConVar("sm_delayexec_message", "0", "実行時にチャットで通知する(1)/しない(0)", _, true, 0.0, true, 1.0);
    g_cvarMode    = CreateConVar("sm_delayexec_mode", "1", "0=無効, 1=マップ毎に1回, 2=毎スポーン実行", _, true, 0.0, true, 2.0);

    // 設定ファイル(cfg/sourcemod/DelayCfg.cfg)を自動生成！
    AutoExecConfig(true, "DelayCfg");
    
    HookEvent("player_spawn", Event_PlayerSpawn);
}

public void OnMapStart()
{
    g_bHasExecutedThisMap = false;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int mode = g_cvarMode.IntValue;
    if (mode == 0 || !g_cvarEnable.BoolValue) return;
    if (mode == 1 && g_bHasExecutedThisMap) return;

    int client = GetClientOfUserId(event.GetInt("userid"));

    // 人間かどうかの厳密なチェック
    if (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client))
    {
        if (mode == 1)
        {
            g_bHasExecutedThisMap = true;
        }

        float delayTime = g_cvarTime.FloatValue;
        CreateTimer(delayTime, Timer_ExecuteCommand);
    }
}

public Action Timer_ExecuteCommand(Handle timer)
{
    char commandString[256];
    g_cvarCommand.GetString(commandString, sizeof(commandString));

    if (strlen(commandString) > 0)
    {
        ServerCommand("%s", commandString);
        LogMessage("[DelayExec] Executed: %s", commandString);
        
        if (g_cvarMessage.BoolValue)
        {
            PrintToChatAll("\x01[\x04DelayExec\x01] Executed: \x03%s", commandString);
        }
    }
    return Plugin_Stop;
}