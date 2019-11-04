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


_addon.name = 'Fish'
_addon.version = '0.3.0'
_addon.author = 'Hazel'
_addon.command = 'fish'

--	ライブラリ
packets = require('packets')
chat = require('chat')
res = require('resources')
config = require('config')

--	グローバル変数
buff_enchant	= true
buff_food		= true

NoCatchCount	= 1
debug_mode		= false
Fish_ID			= 0;

--	デフォルト設定値
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
defaults.CastWait = 12			--	釣りの間隔
defaults.ActionTimeMax = 10		--	格闘時間の最大値
defaults.NoCatchCount = 10		--	「何も釣れなかった」が連続したら釣りをやめる
--[[
defaults.Fatigue = {			--	疲れ管理(未実装)
	Count = 0,
	Date = 0,
}
]]
settings = config.load(defaults)

--	外道
RustyItems = T{
	"アローウッド原木",
	"カッパーリング",
	"コバルトジェリー",
	"パムタム海苔",
	"錆びたサブリガ",
	"錆びたバケツ",
	"錆びたレギンス",
	"錆びたキャップ",
	"錆びた大剣",
	"錆びた鎚鉾",
}

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

function debug_print( msg )
	if debug_mode then
		windower.add_to_chat( 8, windower.to_shift_jis( msg ) )
	end
end

--	何も釣れなかったで釣り停止
windower.register_event('incoming text',function( original, modified, original_mode, modified_mode, blocked )
	local msg = windower.from_shift_jis( original )
	if msg:find( "何も釣れなかった" ) then
		debug_print( 'incoming text / NoCatchCount/MAX='..NoCatchCount.."/"..settings.NoCatchCount )
		if NoCatchCount < tonumber( settings.NoCatchCount ) then
			NoCatchCount	= NoCatchCount + 1;
		end
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
	end
end)

windower.register_event('incoming chunk',function(id, data)
	local	packet = packets.parse('incoming', data)
	-------------- Fishing ---------------
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
	if id == 0x115 then
		local	biteId	= tostring( packet['Fish Bite ID'])		--	掛かったもののID
		local	zoneId	= tostring( windower.ffxi.get_info().zone )		--	キーとしては文字列
		windower.add_to_chat( 8, 'biteId='..biteId )
		windower.add_to_chat( 8, 'zoneId='..zoneId )
		debug_print( 'packet[Catch Key] '..packet['Catch Key'] )

		local pullin_packet

		if settings.Fish[ zoneId ] and settings.Fish[ zoneId ][ biteId ] then
			windower.add_to_chat( 8, windower.to_shift_jis( settings.Fish[ zoneId ][ biteId ].."が掛かった" ) )
		else
			windower.add_to_chat( 8, windower.to_shift_jis( "不明な魚( biteId = "..biteId..")が掛かった" ) )
		end
		--	釣ったものの登録
		if not settings.Fish[ zoneId ] then
			settings.Fish[ zoneId ] = {}						--	現在のエリアで初めての釣果の場合
		end
		if not settings.Fish[ zoneId ][ biteId ] then
			settings.Fish[ zoneId ][ biteId ] = "Monster"		--	新規IDはモンスターとして仮決め
			settings:save('all')
			windower.add_to_chat( 8, windower.to_shift_jis( "不明な魚( biteId = "..biteId..")を登録" ) )
		end
	
		if( settings.Release[ zoneId ] and settings.Release[ zoneId ][ biteId ] ) then
			--	リリース対象
			debug_print( windower.to_shift_jis( "settings.Release[ "..zoneId.." ][ "..biteId.." ]="..settings.Release[ zoneId ][ biteId ] ) )
			windower.add_to_chat( 8, windower.to_shift_jis( settings.Release[ zoneId ][ biteId ].."をリリースします" ) )
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
	        random_wait = math.random( 3, settings.ActionTimeMax )
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
	-- Fishing Action
	--[[
	fields.outgoing[0x110] = L{
	    {ctype='unsigned int',      label='Player',             fn=id},             -- 04
	    {ctype='unsigned int',      label='Fish HP'},                               -- 08   Always 200 when releasing, zero when casting and putting away rod
	    {ctype='unsigned short',    label='Player Index',       fn=index},          -- 0C
	    {ctype='unsigned char',     label='Action',             fn=e+{'fishing'}},  -- 0E
	    {ctype='unsigned char',     label='_unknown1'},                             -- 0F   Always zero (pre-March fishing update this value would increase over time, probably zone fatigue)
	    {ctype='unsigned int',      label='Catch Key'},                             -- 10   When catching this matches the catch key from the 0x115 packet, otherwise zero
	}
	]]
	if id == 0x110 then
		debug_print( '-- outgoing chunk --')
		debug_print( '  packet[Player] '..packet['Player'] )
		debug_print( '  packet[Fish HP] '..packet['Fish HP'] )
		debug_print( '  packet[Player Index] '..packet['Player Index'] )
		debug_print( '  packet[Action] '..packet['Action'] )
		debug_print( '  packet[_unknown1] '..packet['_unknown1'] )
		debug_print( '  packet[Catch Key] '..packet['Catch Key'] )
		debug_print( '-------------------')

		if T{2, 3}:contains( packet['Action'] ) then
			if ( fish_continue and ( NoCatchCount < tonumber( settings.NoCatchCount ) ) ) then
--			if fish_continue then
--				debug_print( 'fish_continue '..( fish_continue and 'true' or 'false' ) )
--				debug_print('next /fish start')
				--	バフ掛け直し(GSと組み合わせると、装備が外れる場合がある)
				if buff_enchant then
--					windower.send_command( windower.to_shift_jis( 'wait 5;input /item ペリカンリング <me>; wait 12; input /fish') )
				end
				if buff_food then
--					windower.send_command( windower.to_shift_jis( 'wait 5;input /item 釣り人弁当 <me>; wait 12; input /fish') )
				end

				--	次の釣り
				windower.send_command('wait '..settings.CastWait..';input /fish')
			else
				debug_print('next /fish stop')
				windower.add_to_chat( 5, windower.to_shift_jis( "規定回数獲物が掛からなかったので動作を停止します" ) )
			end
		end
	end
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
                windower.add_to_chat(207, line..chat.controls.reset)
            end
        elseif comm == 'start' then
			fish_continue = true
			NoCatchCount = 1
			windower.send_command('input /fish')
			windower.add_to_chat( 5 , windower.to_shift_jis( '-- 釣りを開始します --' ) )
        elseif comm == 'stop' then
			fish_continue = false
			windower.add_to_chat( 5 , windower.to_shift_jis( '-- 釣りを止めます --' ) )
        elseif comm == 'autostop' then
			local count				= args[2] and args[2] or defaults.NoCatchCount
			settings.NoCatchCount	= count
			windower.add_to_chat( 5 , windower.to_shift_jis( '-- '..settings.NoCatchCount..' 回連続で釣れなかったら釣りを止めます --' ) )
        elseif comm == 'r' then
			settings = config.load(defaults)
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

--	日付変更(疲れクリア)
windower.register_event('day change', function(new_day, old_day)
	windower.add_to_chat( 8 , windower.to_shift_jis( '日付変更：'..old_day..' -> '..new_day ) )
end)

windower.register_event('add item', function( bag, index, id, count )
	local	zoneId	= tostring( windower.ffxi.get_info().zone )
	local	fishId	= tostring( Fish_ID )
	if res.bags:with( 'en', 'Inventory' ).id == bag then
		if Fish_ID ~= 0 then
			windower.add_to_chat( 8 , windower.to_shift_jis( 'add item / item='..res.items[id].name..' Fish_ID='..Fish_ID ) )
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
			if settings.Fish[ zoneId ] then		--	エミネンの交換などの際のエラー対策
				if settings.Fish[ zoneId ][ fishId ] ~= res.items[id].name then
					settings.Fish[ zoneId ][ fishId ] = res.items[id].name
					settings:save('all')
				end
			end
			Fish_ID	= 0
		end
	end
end)

windower.register_event('load', function()
end)
windower.register_event('unload', function()
	settings:save('all')
end)

windower.register_event('gain buff', function(buff_id)
	local buff_name = res.buffs:with( 'id', buff_id ).name
	windower.add_to_chat( 8 , windower.to_shift_jis( 'gain buff：'..buff_name ) )
	if buff_name == "エンチャント" then
		buff_enchant	= true
	end
	if buff_name == "食事" then
		buff_food	= true
	end
end)
windower.register_event('lose buff', function(buff_id)
	local buff_name = res.buffs:with( 'id', buff_id ).name
	windower.add_to_chat( 8 , windower.to_shift_jis( 'lose buff：'..buff_name ) )
	if buff_name == "エンチャント" then
		buff_enchant	= false
	end
	if buff_name == "食事" then
		buff_food	= false
	end
end)

