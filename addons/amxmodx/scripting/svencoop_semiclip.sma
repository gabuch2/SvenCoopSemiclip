#include <amxmodx>
#include <orpheu>
#include <orpheu_advanced>
#include <fakemeta>

#define PLUGIN_NAME             "Sven Co-op Semiclip"
#define PLUGIN_VERSION          "1.3-dev"
#define PLUGIN_AUTHOR           "gabuch2"

#define CALLIBRATION            2 //do not change this unless you know what are you doing

#pragma semicolon 1

//functions
new OrpheuFunction:g_hShouldBypassEntityFunction, OrpheuFunction:g_hPlayerMoveFunction, OrpheuFunction:g_hTestEntityPositionFunction;

//cvars
new g_cvarEnabled, g_cvarPassthroughSpeed;

//cached cvars
new Float:g_fPassthroughSpeed;

//misc
new g_iOriginalGroupInfo[MAX_PLAYERS+1] = -1;
new g_iPluginFlags;

public plugin_init()
{
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);

    g_cvarEnabled = register_cvar("amx_semiclip_enabled", "1");
    g_cvarPassthroughSpeed = register_cvar("amx_semiclip_passthrough_speed", "500.0");
    register_cvar("amx_semiclip_version", PLUGIN_VERSION, FCVAR_SERVER);

    g_iPluginFlags = plugin_flags();
}

public plugin_cfg()
{
    if(g_iPluginFlags & AMX_FLAG_DEBUG)
        server_print("[Sven Co-op Semiclip Debug] Going through plugin_cfg().");
    g_hShouldBypassEntityFunction = OrpheuGetFunction("SC_ShouldBypassEntity");
    g_hTestEntityPositionFunction = OrpheuGetFunction("SV_TestEntityPosition");
    g_hPlayerMoveFunction = OrpheuGetFunction("PM_GetPlayerMove");

    if(get_pcvar_bool(g_cvarEnabled))
        semiclip_enable();
}

public semiclip_enable()
{
    OrpheuRegisterHook(g_hShouldBypassEntityFunction,"SC_ShouldBypassEntityPre");
    OrpheuRegisterHook(g_hTestEntityPositionFunction,"EntityPositionPre");
    OrpheuRegisterHook(g_hTestEntityPositionFunction,"EntityPositionPost", OrpheuHookPost);

    register_forward(FM_AddToFullPack, "AddToFullPack_Post", true);
    register_forward(FM_PlayerPreThink, "Player_PreThink");
    register_forward(FM_PlayerPostThink, "Player_PostThink");

    g_fPassthroughSpeed = get_pcvar_float(g_cvarPassthroughSpeed);
}

public EntityPositionPre(iOther)
{
    // proto
    // it should be more efficient
    // but sadly, when applying this only to
    // iOther doesn't work, you're welcome to try to fix it!
    // pull requests are open
    for(new iClient=1; iClient <= MaxClients; iClient++)
    {
        if(is_user_alive(iClient))
        {
            // we need to save the player's original groupinfo 
            // in cases where a custom map might be also manipulating it
            // for example: they hunger cutscenes
            g_iOriginalGroupInfo[iClient] = pev(iClient, pev_groupinfo); 
            set_pev(iClient, pev_groupinfo, PlayerIdToBit(iClient));
        }
    }
}

public EntityPositionPost(iOther)
{ 
    // ditto
    for(new iClient=1; iClient <= MaxClients; iClient++)
    {
        if(is_user_alive(iClient))
        {
            set_pev(iClient, pev_groupinfo, g_iOriginalGroupInfo[iClient]);
            g_iOriginalGroupInfo[iClient] = -1;
        }
    }
}

public Player_PreThink(iClient)
{
    // we need to make the player not solid on a player prethink
    // to fix a bug where a player isn't able to stand up if they're crouched
    // inside another player
    new Float:fClientAbsMin[3], Float:fOtherAbsMax[3];
    pev(iClient, pev_absmin, fClientAbsMin);
    if(pev(iClient, pev_flags) & FL_DUCKING && ((pev(iClient, pev_button) & IN_DUCK) == 0)/*  && pev(id, pev_oldbuttons) & IN_DUCK */)
    {
        for(new iOther=1; iOther <= MaxClients; iOther++)
        {
            if(iClient == iOther)
                continue;

            if(is_user_alive(iOther) && IsColliding(iClient, iOther))
            {
                pev(iOther, pev_absmax, fOtherAbsMax);
                if(fClientAbsMin[2]+CALLIBRATION < fOtherAbsMax[2])
                    set_pev(iOther, pev_solid, SOLID_NOT);
            }
        }
    }
}

public Player_PostThink(iClient)
{
    // continuation of previous function
    for(new iOther=1;iOther <= MaxClients;iOther++)
    {
        if(is_user_alive(iOther) && pev(iOther, pev_solid) == SOLID_NOT)
            set_pev(iOther, pev_solid, SOLID_SLIDEBOX);
    }
}

public OrpheuHookReturn:SC_ShouldBypassEntityPre(hFunc, hPhys)
{
    new iOther = OrpheuGetParamStructMember(2, "player");
    if(0 < iOther && iOther < MaxClients)
    {
        new OrpheuStruct:hPpMove = OrpheuGetStructFromAddress(OrpheuStructPlayerMove, OrpheuCall(g_hPlayerMoveFunction));
        new iClient = OrpheuGetStructMember(hPpMove, "player_index") + 1;
        if(!ArePlayersAllied(iClient, iOther))
            return OrpheuIgnored;

        if(0 < iClient && iClient < MaxClients)
        {
            new Float:fClientAbsMin[3], Float:fClientVelocity[3], Float:fOtherAbsMax[3];
            pev(iClient, pev_velocity, fClientVelocity);
            pev(iClient, pev_absmin, fClientAbsMin);
            pev(iOther, pev_absmax, fOtherAbsMax);
            
            if(fClientAbsMin[2]+CALLIBRATION >= fOtherAbsMax[2] && fClientVelocity[2] < g_fPassthroughSpeed)
                return OrpheuIgnored;

            OrpheuSetReturn(true);
            return OrpheuSupercede;
        }
    }
    return OrpheuIgnored;
}

public AddToFullPack_Post(hEntState, iEnt, iEdictEnt, iEdictHost, iHostFlags, iPlayer, pSet) 
{	
    if(iPlayer)
    {
        if(!ArePlayersAllied(iEdictHost, iEdictEnt))
            return FMRES_IGNORED;

        new Float:fClientAbsMin[3], Float:fClientVelocity[3], Float:fOtherAbsMax[3];
        pev(iEdictHost, pev_velocity, fClientVelocity);
        pev(iEdictHost, pev_absmin, fClientAbsMin);
        pev(iEdictEnt, pev_absmax, fOtherAbsMax);

        if(fClientAbsMin[2]+CALLIBRATION >= fOtherAbsMax[2] && fClientVelocity[2] < g_fPassthroughSpeed)
            set_es(hEntState, ES_Solid, 1);
        else
            set_es(hEntState, ES_Solid, 0);

        return FMRES_HANDLED;
    }

    return FMRES_IGNORED;
}

stock IsColliding(iEntity1, iEntity2)
{
    //thanks xPaw
    new Float:fAbsMin1[3], Float:fAbsMin2[3], Float:fAbsMax1[3], Float:fAbsMax2[3];
    
    pev(iEntity1, pev_absmin, fAbsMin1);
    pev(iEntity1, pev_absmax, fAbsMax1);
    pev(iEntity2, pev_absmin, fAbsMin2);
    pev(iEntity2, pev_absmax, fAbsMax2);
    
    if(fAbsMin1[0] > fAbsMax2[0] ||
        fAbsMin1[1] > fAbsMax2[1] ||
        fAbsMin1[2] > fAbsMax2[2] ||
        fAbsMax1[0] < fAbsMin2[0] ||
        fAbsMax1[1] < fAbsMin2[1] ||
        fAbsMax1[2] < fAbsMin2[2])
        return 0;
    
    return 1;
}

stock PlayerIdToBit(const iClient)
{
    //thanks anggaranothing
	return (1<<(iClient&31));
}

stock ArePlayersAllied(const iClient1, const iClient2)
{
    return ExecuteHam(Ham_Classify, iClient1) == ExecuteHam(Ham_Classify, iClient2);
}