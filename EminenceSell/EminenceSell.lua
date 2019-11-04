_addon.name = 'EminenceSell'
_addon.version = '0.2'
_addon.author  = 'Hazel'
_addon.command = 'emi'

packets = require 'packets'
math = require 'math'

--	item_point		= 1625
item_point		= 2755
exchange_count	= 0
currency_info	= {}
currency_info2	= {}

function debug_output(str)
	windower.add_to_chat(8, str)
end

local _debug_print
_debug_print = true
function dprint(...)
	if _debug_print then
		print(...)
	end
end

function talk_npc(npc_id)
--	windower.add_to_chat( 8, "takl_npc("..npc_id..")" )
	local full_id = 0x1000000 + windower.ffxi.get_info()['zone'] * 0x1000 + npc_id % 0x1000
--	windower.add_to_chat( 8, "full_id="..full_id )
	local mob = windower.ffxi.get_mob_by_id(full_id)
	if mob ~= nil then
--		windower.add_to_chat( 8, "mob.index="..mob.index )
		local _packet = packets.new('outgoing', 0x1A, {
			['Target']			= full_id,
			['Target Index']	= mob['index'],
			['Category']		= 0,
			['Param']			= 0,
			['_unknown1']		= 0,
			['X Offset']		= 0,	-- 10 -- non-zero values only observed for geo spells cast using a repositioned subtarget
			['Z Offset']		= 0,	-- 14
			['Y Offset']		= 0,	-- 18
		})
		packets.inject(_packet)
		return true
	else
		debug_output('指定IDのNPCが見つかりませんでした : '..npc_id )
		return false
	end
end

local target_npc

local next_cmd = 'setkey enter down;wait 0.1;setkey enter up;'
local page_cmd = 'setkey right down;wait 0.1;setkey right up;'
local up_cmd = 'setkey up down;wait 0.1;setkey up up;'
local down_cmd = 'setkey down down;wait 0.1;setkey down up;'
local escape_cmd = 'setkey escape down;wait 0.1;setkey escape up;'

local pagelast_cmd = 'setkey right down;wait 1.0;setkey right up;'

function do_exchange()
	local storages	= windower.ffxi.get_items()
	local bag		= storages.inventory
	
	eminence_point	= currency_info['Sparks of Eminence']
	
	exchange_count	= math.floor( ( eminence_point- 5000 ) / item_point )
	
	windower.add_to_chat(148, '交換開始：交換可能個数='..exchange_count..' 鞄の空き='..(bag.max-bag.count) )

	if bag.count < bag.max then

		talk_npc( target_npc.id )
		coroutine.sleep(1.5)

		--	装備品Lv71～Lv98
		windower.send_command(page_cmd)
		coroutine.sleep(0.3)
		windower.send_command(page_cmd)
		coroutine.sleep(0.3)
		windower.send_command(down_cmd)
		coroutine.sleep(0.4)
		windower.send_command(down_cmd)
		coroutine.sleep(0.4)
		windower.send_command(next_cmd)
		random_wait = math.random(1, 2)
		coroutine.sleep( random_wait )

		--	アケロンシールド
		windower.send_command(page_cmd)
		coroutine.sleep(0.3)
		windower.send_command(page_cmd)
		coroutine.sleep(0.3)
		windower.send_command(page_cmd)
		coroutine.sleep(0.3)
		windower.send_command(page_cmd)
		coroutine.sleep(0.3)
		windower.send_command(page_cmd)
		coroutine.sleep(0.3)
		windower.send_command(next_cmd)
		random_wait = math.random(1, 2)
		coroutine.sleep( random_wait )

		windower.send_command(page_cmd)
		coroutine.sleep(0.3)
		windower.send_command(page_cmd)
		coroutine.sleep(0.3)
		windower.send_command(page_cmd)
		coroutine.sleep(0.3)
		windower.send_command(page_cmd)
		coroutine.sleep(0.3)
		windower.send_command(page_cmd)
		coroutine.sleep(0.3)
		windower.send_command(down_cmd)
		coroutine.sleep(0.4)
		windower.send_command(next_cmd)
		random_wait = math.random(1, 2)
		coroutine.sleep( random_wait )

		windower.send_command(page_cmd)
		coroutine.sleep(0.3)
		windower.send_command(page_cmd)
		coroutine.sleep(0.3)
		windower.send_command(page_cmd)
		coroutine.sleep(0.3)
		windower.send_command(down_cmd)
		coroutine.sleep(0.4)
		windower.send_command(down_cmd)
		coroutine.sleep(0.4)

	end

	while bag.count < bag.max do
	
		windower.send_command(next_cmd)
--		windower.add_to_chat(148, 'cmd-1')
		coroutine.sleep( 2 )
		
		--	よろしいですか？
		windower.send_command(up_cmd)
--		windower.add_to_chat(148, 'cmd-2')
		coroutine.sleep( 1 )
		windower.send_command(next_cmd)
--		windower.add_to_chat(148, 'cmd-3')
		coroutine.sleep( 2 )

		storages	= windower.ffxi.get_items()
		bag			= storages.inventory
		
		exchange_count = exchange_count - 1
		if exchange_count == 0 then
			break
		end
	end
	if exchange_count > 0 then
		windower.add_to_chat(148, 'かばんが一杯になりました…')
	else
		windower.add_to_chat(148, 'エミネンスポイントが無くなりました…')
	end
end


local thread_id

function addon_thread()
	do_exchange()
	
	thread_id = nil
end

-- ロード時の処理
windower.register_event('load', function()
end)

local DIK_ESCAPE = 1

windower.register_event('keyboard', function (dik, flags , blocked)
	if thread_id ~= nil and dik == DIK_ESCAPE then
		-- Escキーで停止させる
		coroutine.close(thread_id)
		thread_id = nil
		windower.add_to_chat(148, _addon.name..': 中止します')
	end
end)

windower.register_event('incoming chunk',function(id,org,modi,is_injected,is_blocked)
	if state_get_currency == 1 then
--		windower.add_to_chat( 8, "come incoming chunk / id="..id )
		if id == 0x113 then
			local packet = packets.parse('incoming', org)
			currency_info = packet

--			windower.add_to_chat( 8, "currency_info['Sparks of Eminence']="..currency_info['Sparks of Eminence'] )
			
			state_get_currency = nil
			
			return true
		end
	end
end)
function get_currency_info()
	windower.add_to_chat( 8, "start get_currency_info()" )

	currency_info	= {}

	state_get_currency = 1
	packets.inject(packets.new('outgoing', 0x10F))

--	windower.add_to_chat( 8, "start get_currency_info() -1" )
	while state_get_currency do
		coroutine.sleep(0.01)
	end
	
	state_get_currency = 2
	packets.inject(packets.new('outgoing', 0x115))

--	windower.add_to_chat( 8, "end get_currency_info()" )
	if currency_info then
--		windower.add_to_chat( 8, "currency_info['Sparks of Eminence']="..currency_info['Sparks of Eminence'] )
	end
end

windower.register_event('addon command', function(mode, param)
--	windower.add_to_chat( 8, "mode="..mode )
--	windower.add_to_chat( 8, "param="..param )

	get_currency_info()

	target_npc	= nil
	if not target_npc then
		target_npc		= windower.ffxi.get_mob_by_name('Eternal Flame')
	end
	if not target_npc then
		target_npc		= windower.ffxi.get_mob_by_name('Fhelm Jobeizat')
	end
	if not target_npc then
		target_npc		= windower.ffxi.get_mob_by_name('Isakoth')
	end
	if not target_npc then
		target_npc		= windower.ffxi.get_mob_by_name('Rolandienne')
	end
	
	
	if target_npc then
		if thread_id == nil then
			thread_id = coroutine.schedule(addon_thread, 0)
		end
	else
		windower.add_to_chat(148, 'エミネンスNPCが居ません！')
	end
end)

