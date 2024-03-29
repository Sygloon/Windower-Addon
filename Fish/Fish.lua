--[[
Copyright c 2014, Hazel
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of <addon name> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

------------------------------
--	addon information
------------------------------
_addon.name = 'Fish'
_addon.version = '0.6.2'
_addon.author = 'Hazel'
_addon.command = 'fish'

------------------------------
--	ライブラリ
------------------------------
packets = require('packets')
chat = require('chat')
res = require('resources')
config = require('config')
require('logger')


--	共通関数群
-- テーブル情報 ダンプ
function dump( tbl, indent )
	if type(tbl) ~= 'table' then
		windower.add_to_chat( 8, 'Cannot dump because not table.' )
		return
	end
	for key, value in pairs( tbl ) do
		if type( value ) == 'table' then
			windower.add_to_chat( 8, windower.to_shift_jis( '--- start table('..key..') ---' ) )
			dump( value, indent.." " )
			windower.add_to_chat( 8, windower.to_shift_jis( '--- end table('..key..') ---' ) )
		elseif type( value ) == 'boolean' then
			windower.add_to_chat( 8, windower.to_shift_jis( indent..'key '..key..' value '..( value == true and "true" or "false" ) ) )
		else
			windower.add_to_chat( 8, windower.to_shift_jis( indent..'key '..key..' value '..value ) )
		end
	end
end

--	デバッグログ表示
function debug_print( msg )
	if debug_mode then
		windower.add_to_chat( 8, windower.to_shift_jis( msg ) )
	end
end

--	キュー
Queue	= {}
function Queue.new()
	local obj = { buff = {} }
	return setmetatable(obj, {__index = Queue})
end

function Queue:enqueue(x)
	table.insert(self.buff, x)
end

function Queue:dequeue()
	return table.remove(self.buff, 1)
end

function Queue:top()
	if #self.buff > 0 then
		return self.buff[1]
	end
end

function Queue:isEmpty()
  return #self.buff == 0
end

--	竿、餌、etcの装備
--	equip_part	'Main', 'Head', etc
--	equipment	'太公望の釣竿', 'フィッシャトルク', etc
function equip( equip_part, equipment )
	if not equip_part or not equipment then
		return
	end
	if check_equiped( equip_part, equipment ) then
--		log( equipment..' is equiped.')
		return
	end
	if not have_equip( equipment ) then
--		log( 'not have a '..equipment)
		return
	end
	if equip_part == 'Lring' then
		equip_part = 'L.ring'
	elseif equip_part == 'Rring' then
		equip_part = 'R.ring'
	end
	log( '/equip '..equip_part..' '..equipment )
	windower.send_command( windower.to_shift_jis( 'input /equip '..equip_part..' '..equipment ) )
end

--	装備可能なストレージにアイテムが存在するか
function have_equip( equipment_name )
	local info = windower.ffxi.get_items()
	local bags = T{
		'inventory',
		'wardrobe',
		'wardrobe2',
		'wardrobe3',
		'wardrobe4',
	}
	for _, bag in pairs( bags ) do
--		log( 'bag='..bag)
		if info[ bag ].enabled then
			for slot = 1, 80 do
				local item = info[ bag ][ slot ]
--				dump( item, " " )
				if item.id ~= 0 then
--					log( 'type( item.id )='..type( item.id ))
					if res.items[ item.id ].name == equipment_name then
						return true
					end
				end
			end
		end
	end
	return false
end

--	装備しているかチェック
--	true	装備している(装備変更の必要なし)
--	false	装備していない
function check_equiped( equip_slot, equipment_name )
	local	isEquip = false
	local info = windower.ffxi.get_items()

	--	slot名変換
	if equip_slot == 'Rring' then
		equip_slot = 'right_ring'
	elseif equip_slot == 'Lring' then
		equip_slot = 'left_ring'
	end
	if info and info.equipment and info.equipment[ equip_slot ] then
		local	index	= tonumber( info.equipment[ equip_slot ] )
		local	bag_id	= tonumber( info.equipment[ equip_slot..'_bag' ] )
		local	strage_info = windower.ffxi.get_items( bag_id, index )

		if info.equipment[ equip_slot ] and info.equipment[ equip_slot ] > 0 then	--	何某かを装備している
			--	目的の装備品を装備しているか？
			local	current_equip_name = res.items[ strage_info.id ].name
			if current_equip_name == equipment_name then
				isEquip = true
			else
--				log( 'current_equip_name='..current_equip_name )
--				log( 'equipment_name='..equipment_name )
			end
		end
	end
	return isEquip;
end


--	釣り装備
function equip_fish_gear()
	local gear = settings.Gear
	for slot, partsName in pairs( gear ) do
		if partsName then
--			log( 'slot='..slot..' partsName='..partsName )
			if partsName and partsName:length() > 0 then
				equip( slot, partsName )
			end
		end
	end
end

--	釣り実行
function cast_rod()
	if check_skill_cap() then		--	スキルキャップしているので実行しない
		return
	end
	eat_fisherman_boxlunch()
	use_ring1()
	equip_fish_gear()
	coroutine.sleep(1)
	windower.send_command('input /fish')
end

--	Index取得
function get_item_index_in_bag( item_name )
	local items = windower.ffxi.get_items( res.bugs:with( 'en', 'Inventory' ).id )
	for inv_index = 1, #items do
		local	item = items[ inv_index ]
		if res.items[ item.id ].name then
			return item.id
		end
	end
end

--	竿修理
function hash(crystal, item, count)
    local c = ((crystal % 6506) % 4238) % 4096
    local m = (c + 1) * 6 + 77
    local b = (c + 1) * 42 + 31
    local m2 = (8 * c + 26) + (item - 1) * (c + 35)
    return (m * item + b + m2 * (count - 1)) % 127
end
function repair_rod()
	--	到着間近の船の上なら修理しない
	if ship_state ~= 2 then
        local p = packets.new('outgoing', 0x096)
        local crystal = recipe['crystal']
        if hqsynth then
            crystal = hqcrystal[crystal]
        end
        local id, index = fetch_ingredient(crystal)
        if not index then return id end
		p['Crystal'] = res.items:with('jp', '光のクリスタル' ).id
		p['Crystal Index'] = get_item_index_in_bag( '光のクリスタル' )
        p['Ingredient count'] = 1
        p["Ingredient 1"] = res.items:with('jp', '折れた太公望の釣竿' ).id
        p["Ingredient Index 1"] = get_item_index_in_bag( '折れた太公望の釣竿' )
        p['_unknown1'] = hash(p['Crystal'], p['Ingredient 1'], p['Ingredient count'])
		packets.inject( p )
	end
end

--	スキル値のチェック
function check_skill_cap()
	local skill = windower.ffxi.get_player().skills
	text_box.skill	= tostring( skill.fishing )
	if( skill.fishing < settings.StopBySkillCap) then
		return false
	else
		log( ( string.format( "スキルキャップ(%d/%d)", skill.fishing, settings.StopBySkillCap ) ) )
		return true
	end
end
--	すでにペリカンリングを使っているかチェック
function check_ring_using()
	local is_rinf_used	= false
	local player = windower.ffxi.get_player()
	for _, buffId in pairs( player.buffs ) do
		if buffId == res.buffs:with( 'ja', 'エンチャント' ).id then
			is_rinf_used = true
		end
	end
	return is_rinf_used
end

--	リング使用
function use_ring1()
	if( settings.AutoRingMode and settings.AutoRingMode.Use and fish_continue and not check_ring_using() ) then
		windower.send_command( ( 'input /item '..settings.AutoRingMode.Ring..' <me>' ) )
		coroutine.sleep( 4.0 )
	end
end
--	リング使用 / 2種類使ったときにバフアイコンの区別がつかない問題をどう解決するか…
function use_ring2()
--[[
	if( settings.AutoRingMode and fish_continue ) then
		windower.send_command( ( 'input /item '..settings.AutoRingMode.Ring..' <me>' ) )
		coroutine.sleep( 4.0 )
	end
]]
end

--	かばんに食事が入っているかチェック
function check_food_in_bag()
	local is_food_in_bag	= false
	local bag				= windower.ffxi.get_items( 0 )	--	get inventry info
	for idx = 1, bag.max do
		local item = bag[idx]
		if item.id == res.items:with( 'ja', '釣り人弁当' ).id then
			is_food_in_bag = true
			break
		end
	end
	return is_food_in_bag
end
--	すでに食事を取っているかチェック
function check_food_eat()
	local is_food_eaten	= false
	local player = windower.ffxi.get_player()
	for _, buffId in pairs( player.buffs ) do
		if buffId == res.buffs:with( 'ja', '食事' ).id then
			is_food_eaten = true
		end
	end
	return is_food_eaten
end
--	釣り人弁当使用
function eat_fisherman_boxlunch()
	if(  settings.AutoFoodMode and fish_continue ) then
		local is_alreadey_eat	= check_food_eat()
		local is_food_in_bag	= check_food_in_bag()
		if not is_food_in_bag then
			log( ( "釣り人弁当がかばんに無いのよ..." ) )
		end
		local loop_continue	= ( not is_alreadey_eat ) and is_food_in_bag
		while loop_continue do
			windower.send_command( ( 'input /item 釣り人弁当 <me>' ) )
			coroutine.sleep( 1.0 )
			loop_continue	= ( not check_food_eat() ) and is_food_in_bag
		end
	end
end
--	スニーク使用
function use_sneak()
	local loop_continue = true
	while loop_continue do
		windower.send_command( ( 'input /ma スニーク <me>' ) )
		local player = windower.ffxi.get_player()
		for _, buffId in pairs( player.buffs ) do
			if buffId == res.buffs:with( 'ja', 'スニーク' ).id then
				loop_continue = false
			end
		end
		coroutine.sleep( 0.5 )
	end
end

--	釣り場所判定
function check_ship_state()
	local	zoneId	= windower.ffxi.get_info().zone
	if T{220,221,227,228}:contains( zoneId ) then 
		ship_state = 1		--	船の上
	else
		ship_state = 0		--	地上
	end
end

--	ハラキリ
coroutine_id	= nil
function harakiri_routine( fish_name, target_npc )
	log( 'ハラキリ開始' )
	if not fish_name or not target_npc then
		coroutine_id = nil	--	スレッド終了
		return
	end
	local storages	= windower.ffxi.get_items()
	local bag		= storages.inventory

	for index = 1, bag.max do
		if bag[index].id ~= 0 then
			if res.items[ bag[index].id ].name == windower.from_shift_jis( fish_name ) then
				log( windower.from_shift_jis( 'trade '..fish_name..' to Zaldon' ) )
				windower.send_command( ( 'trade '..fish_name..' Zaldon' ) )
				coroutine.sleep( 10 )
				windower.send_command( 'setkey enter down;wait 0.1;setkey enter up;' )
				coroutine.sleep( 2 )
			end
		end
	end
	log( 'ハラキリ終了' )
	coroutine_id = nil	--	スレッド終了
end
function do_harakiri( fish_name )
	target_npc		= windower.ffxi.get_mob_by_name('Zaldon')
	if not target_npc then
		error( 'Zaldon の近くでコマンドを実行してください')
		return
	end
	harakiri_routine( windower.convert_auto_trans( fish_name ), target_npc )
	coroutine_id = nil
end
windower.register_event('keyboard', function (dik, flags , blocked)
	if coroutine_id ~= nil and dik == DIK_ESCAPE then
		-- Escキーで停止させる
		coroutine.close(coroutine_id)
		coroutine_id = nil
		log( 'ハラキリを中止します' )
	end
end)
	
--	テキストボックス更新
function update_text_box()

	--	釣った引数
	text_box.count	= catch_count	--	本日の釣果

	--	現在のエリア
	local zoneId	= windower.ffxi.get_info().zone
	if T{227, 228 }:contains( zoneId ) then 
		text_box.zone	= res.zones[zoneId].name..string.format( "(海賊！)(%d)", zoneId )
	else
		text_box.zone	= res.zones[zoneId].name..string.format( "(%d)", zoneId )
	end
	
	--	入港間近
--	text_box.PortEntry	= ""
	
	--	釣りスキル
	local skill = windower.ffxi.get_player().skills
	text_box.skill	= tostring( skill.fishing )
	
	text_box.Food	= tostring( settings.AutoFoodMode )
	text_box.Ring	= tostring( settings.AutoRingMode.Use )
	
end

--	キュー実行スレッド
function queue_execute()
	while true do	--	無限ループ
		if not action_queue:isEmpty() then
			print( "queue_execute() not Empty" )
			while action_queue:isEmpty() do	--	無限ループ
				local	task	= action_queue:dequeue()
				task()
			end
		else
			print( "queue_execute() is Empty" )
			coroutine.sleep( 0.5 )
		end
	end
end

------------------------------
--	グローバル変数
------------------------------
NoCatchCount	= 1						--	「何も釣れなかった」連続回数
debug_mode		= false					--	デバッグログ出力フラグ
auto_sneak_mode	= false					--	自動スニークモード
auto_food_mode	= false					--	自動「釣り人弁当」モード
auto_ring_mode	= false					--	自動「ペリカンリング」モード
Fish_ID			= 0						--	釣り上げた魚のID
catch_count		= 0						--	その日に釣り上げた魚の数
today			= os.date("%Y-%m-%d")	--	日付
action_queue	= Queue.new()			--	各種行動のキュー(例：弁当食べる＞スニーク＞釣り)
ship_state		= 0						--	船の上状態 [0]：地上 [1]：船の上 [2]：船の上(到着間近)
fish_continue	= false					--	釣りを繰り返している間は true
CastRetry		= 0						--	「ここでは釣りはできません」のリトライ回数

--	外道
RustyItems = T{
	"アローウッド原木",
	"カッパーリング",
	"シルバーリング",
	"コバルトジェリー",
	"パムタム海苔",
	"ミスリルソード",
	"ミスリルダガー",
	"ノーグ貝",
	"濡れた巻物",
	"破れた帽子",
	"バグベアマスク",
	"モブリンマスク",
	"珊瑚のかけら",
	"魚鱗の盾",
	"錆びたサブリガ",
	"錆びたバケツ",
	"錆びたレギンス",
	"錆びたキャップ",
	"錆びた大剣",
	"錆びた鎚鉾",
	"錆びた短刀",
	"錆びた槍",
	"錆びた鎌",
	"錆びた盾",
	"錆びた短剣",
}



------------------------------
--	デフォルト設定値
------------------------------
defaults = {}
defaults.Fish = {		--	エリア毎の獲物の情報j / アドオンが更新していく
	["246"] = {			--	ZoneID / キーは文字列でないとsave()に失敗する
		["30146569"] = "ノストーヘリング",		--	獲物のID / 獲物の名称
		["32768010"] = "タイガーコッド",		--	0x01F4000A
	},
	["126"] = {
		["30146569"] = "ノストーヘリング",		--	0x01CC0009
		["32768010"] = "タイガーコッド",		--	0x01F4000A
	}
}
defaults.Release = {	--	エリア毎のリリースする獲物の情報
	["246"]		= {
		["26214403"] = "錆びたバケツ",			--	0x01900003
		["36700163"] = "錆びたレギンス",		--	0x02300003
		["39321601"] = "コバルトジェリー",		--	0x02580001
		["50343938"] = "錆びたバケツ",			--	0x03003002
		["50388993"] = "錆びたサブリガ",		--	0x0300E001
		["57671683"] = "カッパーリング",		--	0x03700003
	},
	["126"]		= {
		["26214403"] = "錆びたバケツ",			--	0x01900003
		["36700163"] = "錆びたレギンス",		--	0x02300003
		["39321601"] = "コバルトジェリー",		--	0x02580001
		["50343938"] = "錆びたバケツ",			--	0x03003002
		["50388993"] = "錆びたサブリガ",		--	0x0300E001
		["57671683"] = "カッパーリング",		--	0x03700003
	}
}
defaults.AutoFoodMode	= false		--	釣り人弁当を自動で食べる
defaults.AutoRingMode	= {			--	ペリカンリングの自動使用
	Use			= true,
	Ring		= "ペリカンリング",
}
defaults.AutoRetryCast	= {			--	「ここで釣りはできません」の時にリトライするかどうか
	DoRetry		= true,				--	リトライする
	RetryMax	= 2,				--	リトライする回数
}
defaults.CastWait		= 12		--	釣り上げ→釣りの間隔
defaults.ActionTime =
{
	Max = 5,		--	格闘時間の最大値
	Min = 1			--	格闘時間の最大値
}
defaults.NoCatchCount	= 10		--	「何も釣れなかった」が連続したら釣りをやめる
defaults.StopBySkillCap	= 110		--	指定したスキル値に到達したら釣りをやめる(昇級認定試験)

defaults.Gear = {
	main = "",
	sub = "",
	range = "太公望の釣竿",
	ammo = "",
	head = "トラトラマグラス",
	neck = "フィッシャトルク",
	Lear = "",
	Rear = "",
	body = "漁師スモック",
	hands = "カチナグローブ",
	Lring = "ノディリング",
	Rring = "ペリカンリング",
	back = "",
	waist = "",
	legs = "フィッシャホーズ",
	feet = "ウエーダー",

	AutoRepair = false
}

-- textsの設定項目(値は何も指定していなかった場合のデフォルト値)
local texts_settings = {
	-- テキストの表示位置
	pos = {
		x = 0,
		y = 0,
	},
	-- 背景色
	bg = {
		alpha = 255,
		red = 0,
		green = 0,
		blue = 0,
		visible = true, -- 背景表示の有無
	},
-- 文字列の表示形式
	flags = {
		right = false,
		bottom = false,
		bold = false,
		draggable = true, -- マウスでの移動
		italic = false,
	},
	-- 文字と背景との余白
	padding = 0,

	-- 文字列
	text = {
		size = 10,
		font = 'メイリオ', -- 日本語を表示させる場合は、日本語が表示可能なフォントを設定する必要あり
		fonts = {},
		alpha = 255, -- 透過
		red = 255,
		green = 255,
		blue = 255,

		-- 文字列の縁取り
		stroke = {
			width = 0,
			alpha = 255,
			red = 0,
			green = 0,
			blue = 0,
		}
	}
}
defaults.texts = texts_settings

settings = config.load(defaults)

--	テキストボックスの作成
local texts = require('texts')
text_box = texts.new( '今日の釣果：${count|0}匹\n${zone|？？？} ${PortEntry}\n釣りスキル：${skill|？？？}\nFood：${Food}\nRing：${Ring}', settings.texts, settings )
text_box:show()
update_text_box()


------------------------------
--	Windwoer event
------------------------------
windower.register_event('incoming text',function( original, modified, original_mode, modified_mode, blocked )
	local msg = windower.from_shift_jis( original )
	if ( fish_continue and ( NoCatchCount < tonumber( settings.NoCatchCount ) ) ) then
		if msg:find( "何も釣れなかった" ) then
			--	何も釣れなかったで釣り停止
			debug_print( 'incoming text / NoCatchCount/MAX='..NoCatchCount.."/"..settings.NoCatchCount )
			if NoCatchCount < tonumber( settings.NoCatchCount ) then
				NoCatchCount	= NoCatchCount + 1;
			end
			coroutine.sleep( settings.CastWait )
			cast_rod()
		elseif msg:find( "モンスターを釣り上げた" ) then
			--	リリース対象に追加
			local	zoneId	= tostring( windower.ffxi.get_info().zone )
			local	fishId	= tostring( Fish_ID )
			if not settings.Release[ zoneId ] then
				settings.Release[ zoneId ] = {}
			end
			if not settings.Release[ zoneId ][ fishId ] then
				settings.Release[ zoneId ][ fishId ] = "Monster"
				settings:save('all')
			end
			Fish_ID	= 0			--	釣果をモンスターで確定
								--	'add item'で倒したモンスターのドロップが釣果として登録されるのを防ぐ
		elseif msg:find("釣り竿が折れてしまった" ) then
			repair_rod()
			Fish_ID	= 0			--	釣果をモンスターで確定
		elseif msg:find("ここで釣りはできません" ) then
				if settings.AutoRetryCast.DoRetry then 
				if CastRetry < settings.AutoRetryCast.RetryMax then
					cast_rod()
					CastRetry	= CastRetry + 1
				end
			end
		elseif msg:find("釣り糸が切れてしまった" )
				or msg:find("獲物に逃げられてしまった" )
				or msg:find("あきらめて仕掛けをたぐり寄せた" ) then
			coroutine.sleep( settings.CastWait )
			cast_rod()
			Fish_ID	= 0
		elseif windower.wc_match( msg, "まもなく*へ到着します" ) then
			print('incoming text()-1^4')
			--	機船航路 到着直前なら竿の修理などをやらない(未実装)
			ship_state = 2	--	船の上＆まもなく到着
		
			text_box.PortEntry = "入港間近"
		end
	end

	update_text_box()
end)

windower.register_event('incoming chunk',function(id, data)
	local	packet = packets.parse('incoming', data)
	-------------- Fishing ---------------
	if id == 0x036 then
	-- 何かが掛かったときのパケット
	--[[
	fields.incoming[0x115] = L{
	    {ctype='unsigned short',    label='_unknown1'},                             -- 04
	    {ctype='unsigned short',    label='_unknown2'},                             -- 06
	    {ctype='unsigned short',    label='_unknown3'},                             -- 08
	    {ctype='unsigned int',      label='Fish Bite ID'},                          -- 0A   Unique to the type of fish that bit
	    {ctype='unsigned short',    label='_unknown4'},                             -- 0E
	    {ctype='unsigned short',    label='_unknown5'},                             -- 10
	    {ctype='unsigned short',    label='_unknown6'},                             -- 12
	    {ctype='unsigned int',      label='Catch Key'},                             -- 14   This value is used in the catch key of the 0x110 packet when catching a fish
	}
	]]
	elseif id == 0x115 then
		
		local	biteId	= tostring( packet['Fish Bite ID'])		--	掛かったもののID
		local	zoneId	= tostring( windower.ffxi.get_info().zone )		--	キーとしては文字列
		debug_print( 'biteId='..biteId )
		debug_print( 'zoneId='..zoneId )
		debug_print( 'packet[Catch Key] '..packet['Catch Key'] )

		local pullin_packet

		if settings.Fish[ zoneId ] and settings.Fish[ zoneId ][ biteId ] then
			log( ( settings.Fish[ zoneId ][ biteId ].."が掛かった" ) )
		else
			log( ( "不明な魚( biteId = "..biteId..")が掛かった" ) )
		end
		--	釣ったものの登録
		if not settings.Fish[ zoneId ] then
			settings.Fish[ zoneId ] = {}						--	現在のエリアで初めての釣果の場合
		end
		if not settings.Fish[ zoneId ][ biteId ] then
			settings.Fish[ zoneId ][ biteId ] = "Monster"		--	新規IDはモンスターとして仮決め
			settings:save('all')
			log( ( string.format( "不明な魚( biteId=%s / zoneId=%s )を登録", biteId, zoneId ) ) )
		end
	
		if( settings.Release[ zoneId ] and settings.Release[ zoneId ][ biteId ] ) then
			--	リリース対象
			debug_print( "settings.Release[ "..zoneId.." ][ "..biteId.." ]="..settings.Release[ zoneId ][ biteId ] )
			debug_print( settings.Release[ zoneId ][ biteId ].."をリリースします" )
			--	不要な釣果を捨てる
			-- 釣り上げパケット生成＆送出
			pullin_packet = packets.new('outgoing', 0x110, {
				['Player'] = windower.ffxi.get_player()["id"],
				['Fish HP'] = 200,
				['Player Index'] = windower.ffxi.get_player()["index"],
				['Action'] = 3,
				['_unknown1'] = 0,
				['Catch Key'] = packet['Catch Key'],
			})
		else
			--	釣り上げ対象
			-- ランダム待ち(HPの減りを監視されてたら無駄な気も)
	        random_wait = math.random( settings.ActionTime.Min, settings.ActionTime.Max )
			for wait_count = 0, random_wait do
				coroutine.sleep( 1 )
				debug_print( '- '..(random_wait-wait_count)..'-----------------')
			end

			-- 釣り上げパケット生成＆送出
			pullin_packet = packets.new('outgoing', 0x110, {
				['Player'] = windower.ffxi.get_player()["id"],
				['Fish HP'] = 0,
				['Player Index'] = windower.ffxi.get_player()["index"],
				['Action'] = 3,
				['_unknown1'] = 0,
				['Catch Key'] = packet['Catch Key'],
			})
			Fish_ID	= packet['Fish Bite ID']
		end
		debug_print( '-- inject chunk --')
		debug_print( '  packet[Player] '..pullin_packet['Player'] )
		debug_print( '  packet[Fish HP] '..pullin_packet['Fish HP'] )
		debug_print( '  packet[Player Index] '..pullin_packet['Player Index'] )
		debug_print( '  packet[Action] '..pullin_packet['Action'] )
		debug_print( '  packet[_unknown1] '..pullin_packet['_unknown1'] )
		debug_print( '  packet[Catch Key] '..pullin_packet['Catch Key'] )
		debug_print( '-------------------')
		packets.inject(pullin_packet)
	
		NoCatchCount = 1	--	獲物が掛かったのでカウンターをリセット
	end
end)

windower.register_event('outgoing chunk', function(id, data)
	local packet = packets.parse('outgoing', data)
end)

windower.register_event('addon command', function(...)
    local args = {...}
    if args[1] ~= nil then
        local comm = args[1]:lower()
        if comm == 'help' then
            local helptext = [[Fish - Command List:
 1. fish autostop {count}-- 釣れなかったメッセージをカウント
 2. fish start -- 開始
 3. fish stop -- 停止
 4. fish release add/remove fishName zoneId-- リリースする対象を追加/削除(未実装)
 5. fish reset -- 疲れカウントクリア(未実装)
 6. fish r		--	設定ファイルの再読み込み(Release対象を追加後など)
	]]
            for _, line in ipairs(helptext:split('\n')) do
				log( line..chat.controls.reset)
            end
        elseif comm == 'start' then
			fish_continue = true
			NoCatchCount = 1
			CastRetry = 0
			log( '-- 釣りを開始します --' )
			cast_rod()
        elseif comm == 'stop' then
			fish_continue = false
			log( '-- 釣りを止めます --' )
        elseif comm == 'autoretry' then
			settings.AutoRetryCast.DoRetry = not settings.AutoRetryCast.DoRetry
			log( '-- 釣り失敗時の再実行回数='..tostring(settings.AutoRetryCast.DoRetry) )
        elseif comm == 'autosneak' then
			auto_sneak_mode = not auto_sneak_mode
			log( ( '-- 自動スニ='..tostring(auto_sneak_mode)..' --' ) )
        elseif comm == 'autoring' then	--	リングの自動使用モード
			settings.AutoRingMode.Use = not settings.AutoRingMode.Use
			log( 'autoring='..tostring(settings.AutoRingMode.Use) )
        elseif comm == 'autofood' then	--	弁当を自動で食べるモード
			settings.AutoFoodMode = not settings.AutoFoodMode
			log( 'autofood='..tostring(settings.AutoFoodMode) )
        elseif comm == 'autostop' then
			local count				= args[2] and args[2] or settings.NoCatchCount
			settings.NoCatchCount	= count
			log( '停止回数='..settings.NoCatchCount )
        elseif comm == 'cap' then		-- 指定のスキルに到達したら停止
			settings.StopBySkillCap	= args[2] and tonumber(args[2]) or settings.StopBySkillCap
			log( 'スキルキャップ制限='..settings.StopBySkillCap )
		elseif comm == 'debug' then
			catch_count				= args[2] and args[2] or 0
			update_text_box()
        elseif comm == 'r' then
			settings = config.load(defaults)
        elseif comm == 'z' then
			coroutine_id = coroutine.schedule( do_harakiri:prepare( args[2] ), 0 )
        elseif comm == 'reset' then
--			settings.Fatigue.Count = 0
        elseif comm == 'release' then
--[[
			local act		= args[2]:lower()
			local name		= args[3]
			local zoneId	= tostring( args[3] and args[3] or windower.ffxi.get_info().zone )
			if act == add then
				settings.Release[ zoneId ][ fishId ] = "Monster"
			else
	            for _, item in ipairs( settings.Release[ zoneId ] ) do
					if item == name then
	                windower.add_to_chat(207, line..chat.controls.reset)
	            end
            end
]]
		else
            return
        end
    end
end)

windower.register_event('time change', function( new, old )
	--	日付が変わったら釣果(200制限)をリセット
	if today ~= os.date("%Y-%m-%d")	then
		catch_count	= 0
		update_text_box()
	end
end)

windower.register_event('add item', function( bag, index, id, count )
	local	zoneId	= tostring( windower.ffxi.get_info().zone )
	local	fishId	= tostring( Fish_ID )
	--	かばんに物が増えた
	if res.bags:with( 'en', 'Inventory' ).id == bag then
		--	魚を釣り上げた後
		if Fish_ID ~= 0 then
			log( ( '釣り上げた魚：'..res.items[id].name..' Fish_ID='..Fish_ID ) )
			--	外道だったらリリース対象に追加
			if RustyItems:contains( res.items[id].name ) then
				--	リリース対象に追加
				if not settings.Release[ zoneId ] then
					settings.Release[ zoneId ] = {}
				end
				if not settings.Release[ zoneId ][ fishId ] then
					settings.Release[ zoneId ][ fishId ] = "Monster"
					settings:save('all')
				end
			end
			--	連れたものを一覧に追加
			if settings.Fish[ zoneId ] then
				if settings.Fish[ zoneId ][ fishId ] ~= res.items[id].name then
					--	釣れたものの名前を修正(仮でMonsterにしているので)
					settings.Fish[ zoneId ][ fishId ] = res.items[id].name
					settings:save('all')
				end
			end
			Fish_ID	= 0						--	釣った魚のIDをクリア
			catch_count	= catch_count + 1	--	釣り上げた魚の数をインクリメント
			update_text_box()				--	テキストボックスの表示を更新

			--	かばんが一杯になったら釣り中止
			local bag = windower.ffxi.get_items( 0 )	--	get inventry info
			if bag.max == bag.count then
				log( 'かばんが一杯です' )
				fish_continue = false
			else
				coroutine.sleep( settings.CastWait )
				cast_rod()
			end
		end
	end
end)

windower.register_event('load', function()
	check_ship_state()
end)
windower.register_event('unload', function()
	settings:save('all')
end)

windower.register_event('login', function()
	check_ship_state()
end)

windower.register_event('gain buff', function(buff_id)
	local buff_name = res.buffs:with( 'id', buff_id ).name
	log( ( 'gain buff：'..buff_name ) )
	if buff_name == "エンチャント" then
		buff_enchant	= true
	end
	if buff_name == "食事" then
		buff_food	= true
	end
end)

windower.register_event('lose buff', function(buff_id)
	local buff_name = res.buffs:with( 'id', buff_id ).name
	log( ( string.format( 'lose buff：%s(%d)', buff_name, buff_id ) ) )
	if fish_continue and auto_ring_mode and ( buff_id == res.buffs:with( 'ja', 'エンチャント' ).id ) then
		coroutine.schedule( use_penguin_ring, 0.5 )
	end
	if fish_continue and auto_food_mode and ( buff_id == res.buffs:with( 'ja', 'スニーク' ).id ) then
		coroutine.schedule( eat_fisherman_boxlunch, 0.5 )
	end
	if fish_continue and auto_sneak_mode and ( buff_id == res.buffs:with( 'ja', 'スニーク' ).id ) then
		coroutine.schedule( use_sneak, 0.5 )
	end
end)

windower.register_event('zone change',function ( new_zoneId, old_zoneId )
	check_ship_state()

	text_box.PortEntry = ""
	update_text_box()
	Fish_ID	= 0		--	エリアで釣りが中断したとき
end)