#include <amxmodx>
#include <fakemeta>	
#include <cstrike>
#include <engine>
#include <Twinleaf>
#include <hamsandwich>
#include <sqlx>

#define SHOWQQ_TASK 521734

new SoundPath[64] = "ttt/nailong_laugh.wav";

public plugin_init()
{
    register_plugin("Twinleaf Menu", "0.0.1", "Tredam" /*, "github.com/Lo-kin" , "吉吉草拟"*/);
	register_clcmd("say menu" , "MainMenu" , -1 , "No test");
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "Ham_Knife_Deploy_post", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_usp", "Ham_Usp_Deploy_post", 1);

	set_task(30.0, "ShowQQ", SHOWQQ_TASK , "" , 0 ,"b");
}

public ShowQQ()
{
	client_print_color(0 ,0 , "^4[雙葉]:^1欢迎加入双叶公园QQ群 :^4 1098491779");
}

public MainMenu(id)
{
	ShowQQ();
	new Money = get_user_LeafCoin(id);
	new name[32];
	get_user_name(id , name , 32);
	new UserInfo[128];
	formatex(UserInfo ,  128 , "\d玩家:\w%s \d叶子币:\y%d " , name , Money);
	new Title[64];
	formatex(Title , 64 , "[雙葉]:\d你好呀, %s" , name);
	new menu = menu_create(Title , "MainSelection");
	menu_addtext2(menu , UserInfo);
	menu_additem(menu , "我的信息");
	menu_additem(menu , "双叶小卖铺");
	menu_additem(menu , "MP3 菜单");
	
	menu_additem(menu , "列出所有服务器");
	menu_setprop(menu , MPROP_EXIT, MEXIT_ALL);
	menu_display(id , menu);
}

public MainSelection(id , menu , item)
{
	switch (item)
	{
		case 1:
		{
			console_print(-1 , "test");
		}
		case 2:
		{
			StoreMenu(id);
		}
		case 3:
		{
			MP3Menu(id);	
		}
		case 4:
		{
			ServerMenu(id);
		}
	}
	
	menu_destroy(menu);
}

public MP3Menu(id)
{
	new menu = menu_create("MP3 菜单" , "MP3MenuSelection");
	menu_additem(menu , "MP3 列表");
	menu_additem(menu , "MP3 设置");
	menu_display(id , menu);
}

public MP3MenuSelection(id , menu , item)
{
	switch (item)
	{
		case 0:
		{
			show_mma_list(id);
		}
		case 1:
		{
			show_mma_config(id);
		}
	}
	menu_destroy(menu);
}

public StoreMenu(id)
{
	new menu = menu_create("[雙葉]:\d客官要来点什么" , "StoreSelection");
	menu_additem(menu , "小刀模型");
	menu_additem(menu , "USP模型");
	menu_additem(menu , "人物模型");
	menu_additem(menu , "语音(还没有)");
	menu_display(id , menu);
}

public StoreSelection(id , menu , item)
{
	if (item > 0 || item <= ModelType)
	{
		PurchaseItemMenu(id , item);
	}
	menu_destroy(menu);
}

public PurchaseItemMenu(id , mt)
{
	new item_count = get_model_count(mt);
	new menu = menu_create("[雙葉]:\d客官要来点什么呢" , "ItemSelection");
	for (new i = 0;i < item_count; i ++)
	{
		new item_data[ModelData];
		get_model(i , item_data , mt);
		new info[64];
		if (get_if_user_has_item(id , item_data[MD_ID] , mt) == true)
		{
			formatex(info , 64 , "%s\d[已购买] \R\y%d" , item_data[MD_Name] , item_data[MD_Price]);
		}
		else
		{
			formatex(info , 64 , "%s \R\y%d" , item_data[MD_Name] , item_data[MD_Price]);
		}
		
		new mtstr[6];
		formatex(mtstr , 6 ,"%d" , mt);
		menu_additem(menu , info , mtstr , 0);
	}
	menu_display(id , menu);
}

public ItemSelection(id , menu , item)
{
	//now lets create some variables that will give us information about the menu and the item that was pressed/chosen
    new szData[6], szName[64];
    new _access, item_callback;
    //heres the function that will give us that information ( since it doesnt magicaly appear )
    menu_item_getinfo( menu, item, _access, szData,charsmax( szData ), szName,charsmax( szName ), item_callback);

	new mt = str_to_num(szData);
	new bool:buystate = user_purchase_item(id , item , mt);
	if (buystate == true && mt == MT_Player)
	{
		new item_data[ModelData];
		get_model(item , item_data , MT_Player);
		cs_set_user_model(id , item_data[MD_Name] , false);
	}
	
}

public Ham_Knife_Deploy_post(ent)
{
	/*
	new id = get_weapon_owner(ent);
	if(is_user_alive(id))
	{
		new wpdata[ModelData];
		get_user_current_model(id , wpdata , MT_Knife);
		entity_set_string(id, EV_SZ_viewmodel, wpdata[MD_V_Model]);
		entity_set_string(id, EV_SZ_weaponmodel, wpdata[MD_P_Model]);
	}*/

	if(pev_valid(ent) != 2)
        return
    static id; id = get_pdata_cbase(ent, 41, 4) //Get ID
    if(get_pdata_cbase(id, 373) != ent) //373 = m_pActiveItem. This check if current weapon is correct or not
        return
	new wpdata[ModelData];
	get_user_current_model(id , wpdata , MT_Knife);
    set_pev(id, pev_viewmodel2, wpdata[MD_V_Model])
    set_pev(id, pev_weaponmodel2, wpdata[MD_P_Model])
}

public Ham_Usp_Deploy_post(ent)
{
	/*
	new id = get_weapon_owner(ent);
	if(is_user_alive(id))
	{
		new wpdata[ModelData];
		get_user_current_model(id , wpdata , MT_Usp);
		entity_set_string(id, EV_SZ_viewmodel, wpdata[MD_V_Model]);
		entity_set_string(id, EV_SZ_weaponmodel, wpdata[MD_P_Model]);
	}*/

	if(pev_valid(ent) != 2)
        return
    static id; id = get_pdata_cbase(ent, 41, 4) //Get ID
    if(get_pdata_cbase(id, 373) != ent) //373 = m_pActiveItem. This check if current weapon is correct or not
        return
	new wpdata[ModelData];
	get_user_current_model(id , wpdata , MT_Usp);
	set_pev(id, pev_weaponmodel2, wpdata[MD_P_Model])
    set_pev(id, pev_viewmodel2, wpdata[MD_V_Model])
    
}

public get_weapon_owner(ent)
{
	return get_pdata_cbase(ent, 41, 4);
}

public ServerMenu(id)
{
	new menu = menu_create("服务器列表" , "ServerSelection");
	menu_addtext2(menu , "选择服务器连接");
	menu_additem(menu , "4399小游戏  ");
	menu_additem(menu , "TTT匪镇谍影 ");
	menu_setprop(menu , MPROP_EXIT, MEXIT_ALL);
	menu_display(id , menu);
}

public ServerSelection(id , menu , item)
{
	switch (item)
	{
		case 1:
		{
			client_cmd(id, "connect twinleaf.moe:27015");
		}
		case 2:
		{
			client_cmd(id, "connect twinleaf.moe:27020");
		}
	}
	menu_destroy(menu);
}

public OnPlay(id)
{
	new cost = 1;
	new Money = get_user_LeafCoin(id);
	new name[32];
	get_user_name(id , name , 32);
	if (Money < cost)
	{
		client_print_color(0 , id , "^4[TwT] ^3%s ^1你的钱似乎不够 ^4(%d/%d)" , name , Money , cost);
		return; 

	}
    if (is_user_alive(id) == true)
    {
		set_user_LeafCoin_delta(id , -cost);
        emit_sound(id, CHAN_AUTO, SoundPath, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    }
	else
	{
		client_print_color(0 , id , "^4[TwT] ^3%s ^1死人是不能大笑的" , name);
	}
}

public GetIfUserHasItem(existlist[] , length , find)
{
    for (new i  = 0 ; i < length;i ++)
    {
        if (existlist[i] == find)
        {
            return true;
        }
    }
    return false;
}