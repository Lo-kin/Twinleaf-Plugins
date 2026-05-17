#include <amxmodx>
#include <fakemeta>	
#include <cstrike>
#include <engine>
#include <Twinleaf>
#include <sqlx>
#include <json>

new JsonObjectNames[3][] = {
    "knife",
    "usp",
    "player"
};

new CurrentPlayers[32][UserData];
new ModelStorage[ModelType][ModelStack];
new ModelStacks[512][ModelData];
new g_ModelCount = 0;

new Handle:g_SqlTuple;

public plugin_init()
{
    register_plugin("Twinleaf Menu", "1.0.0", "Tredam" /*, "github.com/Lo-kin" , "吉吉草拟"*/);

    InitModelData(-1 , 0 , "默认" , "models/ttt/v_crowbar.mdl" , "models/ttt/p_crowbar.mdl" , ModelStorage[MT_Knife][ML_Default]);
    InitModelData(-1 , 0 , "默认" , "models/v_usp.mdl" , "models/p_usp.mdl" , ModelStorage[MT_Usp][ML_Default])

    for (new i = 0; i < 32; i++)
    {
        CurrentPlayers[i][IsConnected] = false;
        UpdateUserModelDataByPos(i ,ModelStorage[MT_Usp][ML_Default] , MT_Usp);
        UpdateUserModelDataByPos(i ,ModelStorage[MT_Knife][ML_Default] , MT_Knife);
    }
}

public plugin_natives()
{
    register_native("get_user_sign_time" , "native_GetUserSignTime");
    register_native("get_user_LeafCoin" , "native_GetUserLeafCoin");
    register_native("set_user_LeafCoin" , "native_SetUserLeafCoin");
    register_native("set_user_LeafCoin_delta" , "native_SetUserLeafCoinDelta");
    
    register_native("get_model" , "native_GetModel");
    register_native("get_model_by_id" , "native_GetModelByID");
    register_native("get_model_count" , "native_GetModelCount");

    register_native("get_user_items" , "native_GetUserItems");
    register_native("add_user_item" , "native_AddUserModelItem");

    register_native("get_user_current_model" , "native_GetUserCurrentModel");
    register_native("set_user_current_model" , "native_SetUserModelPrimary");

    register_native("get_if_user_has_item" , "native_GetIfUserHasItem");
    

    register_native("user_purchase_item" , "native_PurchaseItem");
}

public plugin_precache()
{
    precache_model("models/ttt/v_crowbar.mdl");
    precache_model("models/ttt/p_crowbar.mdl");

    g_SqlTuple = SQL_MakeDbTuple("127.0.0.1" , "root" , "caibinxx" , "Twinleaf");
    new g_Error[512];
    new ErrorCode,Handle:SqlConnection = SQL_Connect(g_SqlTuple,ErrorCode,g_Error,511)
    new Handle:Queries[3]

    Queries[0] = SQL_PrepareQuery(SqlConnection,"SELECT * FROM KnifeModel")
    Queries[1] = SQL_PrepareQuery(SqlConnection,"SELECT * FROM UspModel")
    Queries[2] = SQL_PrepareQuery(SqlConnection,"SELECT * FROM PlayerModel")
   
    for(new Count;Count < 3;Count++)
    {
        if(!SQL_Execute(Queries[Count]))
        {
            // if there were any problems
            SQL_QueryError(Queries[Count],g_Error,511)
            set_fail_state(g_Error)
        }
        else
        {
            new m_id;
            new price;
            new name[255];
            new vm_path[255];
            new pm_path[255];
            new Handle:Query = Queries[Count];
            while (SQL_MoreResults(Query) != 0)
            {
                m_id = SQL_ReadResult(Query , 1);
                price = SQL_ReadResult(Query , 0);
                SQL_ReadResult(Query , 2 , name , 255);
                SQL_ReadResult(Query , 3 , vm_path , 255);
                SQL_ReadResult(Query , 4 , pm_path , 255);
                precache_model(vm_path);
                precache_model(pm_path);
                
                //Count == ModelType
                new c_count = ModelStorage[Count][ML_Count];
                ModelStorage[Count][ML_List][c_count] = g_ModelCount;
                InitModelData(m_id , price , name , vm_path , pm_path , ModelStacks[g_ModelCount]);
                g_ModelCount += 1;
                ModelStorage[Count][ML_Count] += 1;
                SQL_NextRow(Query);
            }
        }
        SQL_FreeHandle(Queries[Count]);
    }
    SQL_FreeHandle(SqlConnection);
    console_print(-1 , "%d knife, %d usp, %d player , %d total" ,ModelStorage[MT_Knife][ML_Count] , ModelStorage[MT_Usp][ML_Count], ModelStorage[MT_Player][ML_Count] , g_ModelCount);
}

public InitModelData(md_id , md_price , md_name[] , md_v_model[] , md_p_model[] , out[ModelData])
{
    out[MD_ID] = md_id;
    out[MD_Price] = md_price;
    copy(out[MD_Name] , 32 , md_name);
    copy(out[MD_V_Model] , 128 , md_v_model);
    copy(out[MD_P_Model] , 128 , md_p_model);
}

public CopyModelData(dest[] , source[])
{
    dest[MD_ID] = source[MD_ID];
    dest[MD_Price] = source[MD_Price];
    copy(dest[MD_Name] , 32 , source[MD_Name]);
    copy(dest[MD_V_Model] , 128 , source[MD_V_Model])
    copy(dest[MD_P_Model] , 128 , source[MD_P_Model])
}

public UpdateUserModelData(id , data[ModelData] , modeltype)
{
    UpdateUserModelDataByPos(GetUserPosition(id) , data , modeltype);
}

public UpdateUserModelDataByPos(pos , data[ModelData] , modeltype)
{
    if (pos >= 0 && pos < 32)
    {
        CopyModelData(CurrentPlayers[pos][UserKnifeData + modeltype * ModelData] , data);
    }
}


//Native Start
public native_SetUserLeafCoin(plugin, params)
{
    if (params == 2)
    {
        SetLeafCoin(get_param(1) , get_param(2));
        return true;
    }
    return false;
}

public native_SetUserLeafCoinDelta(plugin, params)
{
    if (params == 2)
    {
        DeltaLeafCoin(get_param(1) , get_param(2));
        return true;
    }
    return false;
}

public native_GetUserSignTime(plugin, params)
{
    new defaultout[255] = "NULL";
    if (params == 1)
    {
        new pos =  GetUserPosition(get_param(1));
        if (pos != -1)
        {
            copy(defaultout , 255 , CurrentPlayers[pos][SignInTime]);
        }
    }
    return defaultout;
}

public native_GetUserLeafCoin(plugin, params)
{
    if (params == 1)
    {
        new pos =  GetUserPosition(get_param(1));
        if (pos == -1)
        {
            return -1;
        }
        else
        {
            return CurrentPlayers[pos][LeafCoin];
        }
    }
    return -1;
}

public native_GetUserItems(plugin, params)
{
    if (params == 3)
    {
        new id = get_param(1);
        new mt = get_param(3)
        new model_list[256];
        new model_count;
        model_count = GetUserItems(id , model_list , mt);
        set_array(2 , model_list , 256);
        return model_count;
    }
    return -1;
}


public native_GetModel(plugin, params)
{
    if (params == 3)
    {
        new pos = get_param(1);
        new mt = get_param(3);
        set_array(2 , ModelStacks[ModelStorage[mt][ML_List][pos]] , ModelData);
        return true;
    }
    return false;
}

public native_GetModelByID(plugin, params)
{
    if (params == 3)
    {
        new id = get_param(1);
        new mt = get_param(3);
        new pos = GetModelPos(id , mt);
        if (pos != -1)
        {
            set_array(2 , ModelStacks[ModelStorage[mt][ML_List][pos]] , ModelData);
            return true;
        }
    }
    return false;
}

public native_GetModelCount(plugin, params)
{
    if (params == 1)
    {
        new mt = get_param(1);
        return ModelStorage[mt][ML_Count];
    }
    return -1;
}

public native_GetUserCurrentModel(plugin, params)
{
    if (params == 3)
    {
        new id = get_param(1);
        new mt = get_param(3);
        new pos = GetUserPosition(id);
        if (pos != -1)
        {
            set_array(2 , CurrentPlayers[pos][mt * ModelData + UserKnifeData] , 256);
        }
        return true;
    }
    return false;
}

public native_AddUserModelItem(plugin, params)
{
    if (params == 3)
    {
        new id = get_param(1);
        new mt = get_param(3);
        new model_id = get_param(2);
        AddUserModelItem(id , model_id , mt);
    }
}

public native_SetUserModelPrimary(plugin, params)
{
    if (params == 3)
    {
        new id = get_param(1);
        new model_id = get_param(2);
        new mt = get_param(3);
        SetUserModelPrimary(id , model_id , mt);
    }
}

public native_GetIfUserHasItem(plugin, params)
{
    if (params == 3)
    {
        new id = get_param(1);
        new mdid = get_param(2);
        new mt = get_param(3);
        return GetIfUserHasItem(id , mdid , mt);
    }
    return false;
}

public native_PurchaseItem(plugin, params)
{
    if (params == 3)
    {
        new id = get_param(1);
        new mdid = get_param(2);
        new mt = get_param(3);
        return PurchaseItem(id , mdid , mt);
    }
    return false;
}
//Native End

public GetItemPos(id , mt)
{
    for (new i = 0 ;i < ModelStorage[mt][ML_Count];i ++)
    {
        if (ModelStacks[ModelStorage[mt][ML_List][i]][MD_ID] == id)
        {
            return i;
        }
    }
    return -1;
}

public GetUserPosition(id)
{
    new steamid[256];
    get_user_authid(id , steamid , 256);
    for (new i = 0; i < 32; i++)
    {
        if (equali(steamid , CurrentPlayers[i][SteamID]) == true)
        {
            return i;
        }
    }
    return -1;
}

public GetEmptyPosition(id)
{
    for (new i = 0; i < 32; i++)
    {
        //console_print(-1 , "%d : is %d" , i , CurrentPlayers[i][IsConnected]);
        if (CurrentPlayers[i][IsConnected] == false)
        {
            return i;
        }
    }
    return -1;
}

public client_connect(id)
{
    new pos = GetEmptyPosition(id);
    new steamid[256];
    get_user_authid(id , steamid , 256);
    new name[32];
    get_user_name(id , name , 32);
    client_print_color(0 , id , "^4[OMO] ^3%s ^2加入了游戏......" , name)
    GetUserData(id);
    if (pos != -1)
    {
        copy(CurrentPlayers[pos][SteamID] , 32 , steamid); 
        CurrentPlayers[pos][IsConnected] = true;
    }
}

public client_disconnected(id)
{
    new steamid[256];
    get_user_authid(id , steamid , 256);
    new name[32];
    get_user_name(id , name , 32);
    new pos = GetUserPosition(id);
    if (pos != -1)
    {
        CurrentPlayers[pos][IsConnected] = true;
        for (new mt = 0;mt < ModelType;mt ++)
        {
            UpdateUserModelDataByPos(pos ,ModelStorage[mt][ML_Default] , mt);
        }
    }
    client_print_color(0 , id , "^4[TWT] ^3%s ^2离开了我们......" , name)
}

public LoadUserInfo(Handle:Query , id)
{
    if (SQL_MoreResults(Query) == 0)
    {
        console_print(-1 , "Load User Info Failed.");
    }
    else
    {
        new steamid[128];
        //new userip[128];
        new signtime[256];
        new itemdata[2048];
        new onlinetime;
        new lm;
        SQL_ReadResult(Query , 0 , steamid , 128);
        //SQL_ReadResult(Query , 2 , userip , 128);
        lm = SQL_ReadResult(Query , 4);
        SQL_ReadResult(Query , 5 , signtime , 256);
        onlinetime = SQL_ReadResult(Query , 6);
        SQL_ReadResult(Query , 8 , itemdata , 2048);
        new players[32];
        new playercount;
        get_players(players , playercount);
        new pos = GetUserPosition(id);
        if (pos != -1)
        {
            CurrentPlayers[pos][LeafCoin] = lm;
            copy(CurrentPlayers[pos][SignInTime] , 256 , signtime);
            copy(CurrentPlayers[pos][StorageItems] , 2048 , itemdata);
            LoadUserPrimary(id , itemdata);            
        }
    }
}

public PurchaseItem(id , mdid , mt)
{
    new item_data[ModelData];
    get_model(mdid , item_data , mt);
	new name[32];
	get_user_name(id , name , 32);
	if (GetIfUserHasItem(id , item_data[MD_ID] , mt) == true)
	{
		SetUserModelPrimary(id , item_data[MD_ID] , mt);
        return true;
	}
	else
	{
		new userLeaf = GetLeafCoin(id);
		if (userLeaf > item_data[MD_Price])
		{
			DeltaLeafCoin(id , -item_data[MD_Price]);
			AddUserModelItem(id , item_data[MD_ID] , mt);
			SetUserModelPrimary(id , item_data[MD_ID] , mt);
			client_print_color(0 , id , "^4[雙葉]:^1富哥 ^3%s ^1花了 ^4%d ^1购买了 ^4%s" , name , item_data[MD_Price] , item_data[MD_Name]);
            return true;
		}
		else
		{
			client_print_color(id ,id , "^4[雙葉]:^1你的钱似乎不够买这个 ^4(%d/%d) (切)" , userLeaf ,item_data[MD_Price]);
            return false;
		}
	}
    return false;
}

public SetLeafCoin(id , value)
{
    new pos = GetUserPosition(id);
    if (pos != -1)
    {
        CurrentPlayers[pos][LeafCoin] = value;
        SetUserData(id , value);
    }
}

public DeltaLeafCoin(id , delta)
{
    new pos = GetUserPosition(id);
    if (pos != -1)
    {
        CurrentPlayers[pos][LeafCoin] += delta;
        SetUserData(id , CurrentPlayers[pos][LeafCoin]);
    }
}

public GetLeafCoin(id)
{
    new pos = GetUserPosition(id);
    if (pos != -1)
    {
        return CurrentPlayers[pos][LeafCoin];
    }
    return -1;
}

public Register(id)
{
    new steamid[128];
    new gamename[32];
    new password[32] = "test";
    new userip[128];
    get_user_authid(id ,steamid ,128);
    get_user_name(id , gamename , 32);
    get_user_ip(id , userip ,128);
    new QueryCache[512];
    formatex(QueryCache , 512 , "INSERT INTO UserInfo (SteamID, GameName, Pwd , LogIP , OnlineTime , OnlineState) VALUES ('%s','%s','%s','%s',%d,%d);" , steamid , gamename , password , userip , 0 , 0);
    SQL_ThreadQuery(g_SqlTuple ,"SetUserInfoHandle" ,QueryCache);
}

public GetUserData(id)
{
    new steamid[128];
    get_user_authid(id ,steamid ,128);
    new QueryCache[512];
    formatex(QueryCache , 512 , "SELECT * FROM UserInfo WHERE SteamID='%s'", steamid);
    new userid[4];
    formatex(userid , 4 , "%d" , id);
    SQL_ThreadQuery(g_SqlTuple ,"GetUserInfoHandle" ,QueryCache , userid , 4);
}

public SetUserData(id , value)
{
    new steamid[128];
    get_user_authid(id ,steamid ,128);
    new QueryCache[512];
    formatex(QueryCache , 512 , "UPDATE UserInfo SET LeafCoin=%d WHERE SteamID='%s'",value, steamid);
    SQL_ThreadQuery(g_SqlTuple ,"SetUserInfoHandle" ,QueryCache);
}

public SetUserItemData(id , value[])
{
    new steamid[128];
    get_user_authid(id ,steamid ,128);
    new QueryCache[1024];
    formatex(QueryCache , 1024 , "UPDATE UserInfo SET StorageItems='%s' WHERE SteamID='%s'",value, steamid);
    SQL_ThreadQuery(g_SqlTuple ,"SetUserInfoHandle" ,QueryCache);
}

public SetUserInfoHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
    if (CheckFail(FailState , Error , Errcode) == false)
    {
        return PLUGIN_CONTINUE;
    }
    return PLUGIN_CONTINUE;
}

public GetUserInfoHandle(FailState,Handle:Query,Error[],Errcode,Data[],DataSize)
{
    if (CheckFail(FailState , Error , Errcode) == false)
    {
        return PLUGIN_CONTINUE;
    }
    if (SQL_MoreResults(Query) == 0)
    {
        Register(str_to_num(Data));
    }
    else
    {
        LoadUserInfo(Query , str_to_num(Data));
    }
    return PLUGIN_CONTINUE;
}

public CheckFail(FailState , Error[] , Errcode)
{
    if(FailState == TQUERY_CONNECT_FAILED)
    {
        console_print(-1 , "Could not connect to SQL database.");
        return false;
    }
    else if(FailState == TQUERY_QUERY_FAILED)
    {
        console_print(-1 , "Query failed.");
        return false;
    }
    if(Errcode)
    {
        console_print(-1 , "Error on query: %s",Error);
        return false;
    }
    return true;
}

//JSON 库存
public GetUserCurrentModel(id , mt)
{
    new pos = GetUserPosition(id);
    new num;
    if (pos != -1)
    {
        new JSON:Root = json_parse(CurrentPlayers[pos][StorageItems] , false);
        if (CheckUserStorageVaild(id , Root) == true)
        {
            new object_name[32] = "";
            format(object_name , 32 , "current_%s" , JsonObjectNames[mt]);
            num = json_object_get_number(Root , object_name);
        }
        json_free(Root);
    }
    return num;
}

public GetUserItems(id , item[] , mt)
{
    new pos = GetUserPosition(id);
    new count = -1;
    new JSON:Root = json_parse(CurrentPlayers[pos][StorageItems] , false);
    if (CheckUserStorageVaild(id , Root) == false)
    {
        return count;
    }
	else
	{
        new JSON:model_origin = json_object_get_value(Root ,JsonObjectNames[mt]);
        if (model_origin != Invalid_JSON)
		{
            count = json_array_get_count(model_origin);
            for (new i = 0; i < count;i ++)
            {
                item[i] = json_array_get_number(model_origin , i);
            }
        }
        json_free(model_origin);
        json_free(Root);
    }
    return count;
}

public AddUserModelItem(id , item , mt)
{
    new pos = GetUserPosition(id);
    new JSON:Root = json_parse(CurrentPlayers[pos][StorageItems] , false);
    if (CheckUserStorageVaild(id , Root) == false)
    {
        return PLUGIN_CONTINUE;
    }
	else
	{
        new JSON:model_origin = json_object_get_value(Root , JsonObjectNames[mt]);
        json_array_append_number(model_origin , item);
        json_object_set_value(Root , JsonObjectNames[mt] , model_origin);

        json_serial_to_string(Root , CurrentPlayers[pos][StorageItems] , 2048);
		json_free(model_origin);
        json_free(Root);
        SetUserItemData(id ,CurrentPlayers[pos][StorageItems]);
	}
    return PLUGIN_CONTINUE;
}

public SetUserModelPrimary(id , wp_id , mt)
{
    new pos =  GetUserPosition(id);
    if (pos != -1)
    {
        new JSON:Root = json_parse(CurrentPlayers[pos][StorageItems] , false);
        if (CheckUserStorageVaild(id , Root) == false)
        {
            return PLUGIN_CONTINUE;
        }
        else
        {
            new object_name[32] = "";
            format(object_name , 32 , "current_%s" , JsonObjectNames[mt]);
            json_object_set_number(Root , object_name , wp_id);
            json_serial_to_string(Root , CurrentPlayers[pos][StorageItems] , 2048);
            json_free(Root);
            SetUserItemData(id ,CurrentPlayers[pos][StorageItems]);
            new wp_pos = GetModelPos(wp_id , mt);
            UpdateUserModelDataByPos(pos ,ModelStacks[ModelStorage[mt][ML_List][wp_pos]] , mt);
            client_print_color(id ,id , "^4[雙葉]: ^3%s ^1给你装备好了" , ModelStacks[ModelStorage[mt][ML_List][wp_pos]][MD_Name]);
        }
    }
    return PLUGIN_CONTINUE;
}

public LoadUserPrimary(id , buffer[])
{
    new pos =  GetUserPosition(id);
    if (pos != -1)
    {
        new JSON:Root = json_parse(buffer , false);
        if (CheckUserStorageVaild(id , Root) == false)
        {
            return false;
        }
        else
        {
            for (new mt = 0; mt < ModelType;mt ++)
            {
                new object_name[32];
                format(object_name , 32 , "current_%s" , JsonObjectNames[mt]);
                new md_id = json_object_get_number(Root , object_name);
                new md_pos = GetModelPos(md_id , mt);
                UpdateUserModelDataByPos(pos ,ModelStacks[ModelStorage[mt][ML_List][md_pos]] , mt);
                client_print_color(id ,id , "^4[雙葉]: ^3%s ^1给你装备好了" , ModelStacks[ModelStorage[mt][ML_List][md_pos]][MD_Name]);
            }
            json_free(Root);
        }
    }
    return true;
}

public GetModelPos(mdid , mt)
{
    for (new i  = 0 ; i < ModelStorage[mt][ML_Count];i ++)
    {
        if (ModelStacks[ModelStorage[mt][ML_List][i]][MD_ID] == mdid)
        {
            return i;
        }
    }
    return -1;
}

public GetIfUserHasItem(id , mdid , mt)
{
    new model[256];
    new modelcount = GetUserItems(id , model , mt);
    for (new i  = 0 ; i < modelcount;i ++)
    {
        if (model[i] == mdid)
        {
            return true;
        }
    }
    return false;
}

public CreateEmptyStorage(id)
{
    new s_buffer[2048];
	new JSON:Rootjson = json_init_object();
    
    for (new mt = 0 ; mt < ModelType;mt ++)
    {
        new object_current[32];
        copy(object_current , 32 , JsonObjectNames[mt])
        new object_list[32];
        format(object_list , 32 , "current_%s" , object_current);
        new JSON:model_Storage = json_init_array();
        json_object_set_number(Rootjson , object_current , -1);
        json_object_set_value(Rootjson , object_list , model_Storage);
        json_free(model_Storage);
    }

    json_serial_to_string(Rootjson , s_buffer , 2048);
    new pos = GetUserPosition(id);
    copy(CurrentPlayers[pos][StorageItems] ,2048 ,  s_buffer);

    json_free(Rootjson);

    SetUserItemData(id ,s_buffer);
}

public CheckUserStorageVaild(id , JSON:injson)
{
    if (json_get_type(injson) == JSONNull)
    {
        CreateEmptyStorage(id);
        return false;
    }
	if (injson == Invalid_JSON)
	{
		json_free(injson);
		console_print(-1 , "error Item Info");
		return false;
	}
    new needUpdate = 0;
    for (new mt = 0;mt < ModelType;mt ++)
    {
        new object_list[32];
        copy(object_list , 32 , JsonObjectNames[mt])
        new object_current[32];
        format(object_current , 32 , "current_%s" , object_list);
        
        if (json_object_has_value(injson , object_current) == false)
        {
            json_object_set_number(injson , object_current , -1);
            needUpdate = 1;
        }
        if (json_object_has_value(injson , object_list) == false)
        {
            new JSON:usp_Storage = json_init_array();
            json_object_set_value(injson , object_list , usp_Storage);
            json_free(usp_Storage);
            needUpdate = 1;
        }
    }
    if (needUpdate != 0)
    {
        new pos = GetUserPosition(id);
        json_serial_to_string(injson , CurrentPlayers[pos][StorageItems] , 2048);
        SetUserItemData(id ,CurrentPlayers[pos][StorageItems]);
    }
    return true;
}