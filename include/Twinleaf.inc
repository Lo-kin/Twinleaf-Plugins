#if (defined(_twinleaf_included))
	#endinput
#endif
#define _twinleaf_included

enum _:ModelData
{
    MD_ID,
    MD_Name[32],
    MD_Price,
	MD_V_Model[128],
	MD_P_Model[128]
}

enum _:ModelType
{
	MT_Knife,
	MT_Usp,
	MT_Player,
}

enum _:ModelStack
{
	ML_Count,
    ML_Default[ModelData],
	ML_List[64],//enum not support 2-d array,so instead quote
};

enum _:UserData
{
    SteamID[255],
    GameName[255],
    LeafCoin,
    SignInTime[255],
    OnlineTime,
    StorageCount,
    StorageItems[2048],
    bool:IsConnected,
    UserKnifeData[ModelData],
    UserUspData[ModelData],
	UserPlayerData[ModelData],
};

native show_mma_list(id);

native show_mma_config(id);

native broadcast_bgm(id , bgm);

native get_user_sign_time(id);

native get_user_LeafCoin(id);

native set_user_LeafCoin(id , value);

//set money to money + delta
native set_user_LeafCoin_delta(id , delta);

//mt = ModelType(enum)
native get_model(pos , out[ModelData] , mt);

native get_model_by_id(id , out[ModelData] , mt);

native get_model_count(mt);

//return count
native get_user_items(id , out[] , mt);

native get_user_current_model(id , out[ModelData] , mt);

native add_user_item(id , wpid , mt);

native set_user_current_model(id , wpid , mt);

native get_if_user_has_item(id , mdid , mt);

native user_purchase_item(id , mdid , mt);