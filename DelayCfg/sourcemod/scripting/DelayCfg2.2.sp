#include <sourcemod>

// --- 変数の宣言 ---
ConVar g_cvarEnable;
ConVar g_cvarTime;
ConVar g_cvarCommand;
ConVar g_cvarMessage;
ConVar g_cvarMode; 
bool g_bHasExecutedThisMap = false;
bool g_bHasExecutedThisRound = false; // ← 【追加】ラウンド毎のロック用フラグ

public Plugin myinfo = 
{
    name = "DelayCfg2.2",
    author = "coah & GoogleAI",
    description = "Executes a .cfg file X seconds after a player spawns.",
    version = "2.2", // バージョンを少し上げました
    url = ""
};

// --- ここから下がプラグインのメインの仕組みだよ ---
public void OnPluginStart()
{
    g_cvarEnable  = CreateConVar("sm_delayexec_enable", "1", "プラグインの有効(1)/無効(0)切り替え", _, true, 0.0, true, 1.0);
    g_cvarTime    = CreateConVar("sm_delayexec_time", "3.0", "スポーンから実行までの遅延秒数", _, true, 0.1);
    g_cvarCommand = CreateConVar("sm_delayexec_command", "exec DelayCfgExample", "実行するコマンドまたは.cfgファイル名");
    g_cvarMessage = CreateConVar("sm_delayexec_message", "0", "実行時にチャットで通知する(1)/しない(0)", _, true, 0.0, true, 1.0);
    g_cvarMode    = CreateConVar("sm_delayexec_mode", "1", "0=無効, 1=マップ毎に1回, 2=ラウンド毎に1回", _, true, 0.0, true, 2.0); // ← 説明を変更

    AutoExecConfig(true, "DelayCfg2.2");
    
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("round_start", Event_RoundStart); // ← 【追加】ラウンド開始イベントを監視
}

public void OnMapStart()
{
    g_bHasExecutedThisMap = false;
    g_bHasExecutedThisRound = false;
}

// 【追加】新しくラウンドが始まったらロックを解除するよ
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    g_bHasExecutedThisRound = false;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int mode = g_cvarMode.IntValue;
    if (mode == 0 || !g_cvarEnable.BoolValue) return;
    if (mode == 1 && g_bHasExecutedThisMap) return;
    if (mode == 2 && g_bHasExecutedThisRound) return; // ← 【追加】モード2の時はラウンド中2回目以降ならスルー

    int client = GetClientOfUserId(event.GetInt("userid"));

    // 人間かどうかの厳密なチェック ＆ 生存チェックを追加してさらに安全に
    if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client))
    {
        // 実行確定なのでフラグを立ててロックする
        if (mode == 1)
        {
            g_bHasExecutedThisMap = true;
        }
        else if (mode == 2)
        {
            g_bHasExecutedThisRound = true; // ← 【追加】ラウンド内での実行済みロックをかける
        }

        float delayTime = g_cvarTime.FloatValue;
        
        // Exec .cfg X seconds after player spawn
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