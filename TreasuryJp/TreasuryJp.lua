_addon.name = 'TreasuryJp'
_addon.author = 'Ihina'
_addon.localize = 'Hazel'
_addon.version = '1.2.0.2'
_addon.commands = {'treasuryjp', 'trjp'}
_addon.language = 'japanese'
--_addon.language = 'English'

res = require('resources')
config = require('config')
packets = require('packets')
require('logger')

defaults = {}
defaults.Pass = S{}		--	set
defaults.Lot = S{}		--	set
defaults.Drop = S{}		--	set
defaults.Use = S{}		--	set
defaults.AutoDrop = false
defaults.AutoStack = true
defaults.AutoUse = true
defaults.Delay = 0
defaults.Verbose = false

settings = config.load(defaults)

ids = T{}
for item in res.items:it() do
    ids[item.name:lower()] = item.id 
    ids[item.name_log:lower()] = item.id 
end

s = S{'pass', 'lot', 'drop'}

-- テーブル情報 ダンプ
function dump_sjis( tbl, indent )
	for key, value in pairs( tbl ) do
		if type( value ) == 'table' then
			windower.add_to_chat( 8, '--- start table('..key..') ---' )
			dump( value, indent.." " )
			windower.add_to_chat( 8, '--- end table('..key..') ---' )
		elseif type( value ) == 'boolean' then
			windower.add_to_chat( 8, windower.to_shift_jis( indent..'key '..key..' value '..( value == true and "true" or "false" ) ) )
		else
			windower.add_to_chat( 8, windower.to_shift_jis( indent..'key '..key..' value '..value ) )
		end
	end
end

function dump_utf8( tbl, indent )
	for key, value in pairs( tbl ) do
		if type( value ) == 'table' then
			windower.add_to_chat( 8, '--- start table('..key..') ---' )
			dump( value, indent.." " )
			windower.add_to_chat( 8, '--- end table('..key..') ---' )
		elseif type( value ) == 'boolean' then
			windower.add_to_chat( 8, windower.from_shift_jis( indent..'key '..key..' value '..( value == true and "true" or "false" ) ) )
		else
			windower.add_to_chat( 8, windower.from_shift_jis( indent..'key '..key..' value '..value ) )
		end
	end
end

function dump( tbl, indent )
	for key, value in pairs( tbl ) do
		if type( value ) == 'table' then
			windower.add_to_chat( 8, '--- start table('..key..') ---' )
			dump( value, indent.." " )
			windower.add_to_chat( 8, '--- end table('..key..') ---' )
		elseif type( value ) == 'boolean' then
			windower.add_to_chat( 8, indent..'key '..key..' value '..( value == true and "true" or "false" ) ) 
		else
			windower.add_to_chat( 8, indent..'key '..key..' value '..value )
		end
	end
end

lotpassdrop_commands = T{
    lot = 'Lot',
    l = 'Lot',
    pass = 'Pass',
    p = 'Pass',
    drop = 'Drop',
    d = 'Drop',
}

addremove_commands = T{
    add = 'add',
    a = 'add',
    ['+'] = 'add',
    remove = 'remove',
    r = 'remove',
    ['-'] = 'remove',
}

bool_values = T{
    ['on'] = true,
    ['1'] = true,
    ['true'] = true,
    ['off'] = false,
    ['0'] = false,
    ['false'] = false,
}

inventory_id = res.bags:with('english', 'Inventory').id

function lotpassdrop(command1, command2, items )
log( 'lotpassdrop()' )
    local action = command1
    if command2 == 'add' then
        log( windower.to_shift_jis('Adding to ' .. action .. ' list:'..items:concat(" ") ) )
		for id in pairs( items ) do
--			log( windower.to_shift_jis('Adding to '..action .. ' '..res.items[id].name ) )
--			log( 'Adding to '..action .. ' '..res.items[id].name )
			settings[action]:add( res.items[id].name )
 		end
    elseif command2 == 'remove' then
        log( windower.to_shift_jis('Removing from ' .. action .. ' list:'..items:concat(" ") ) )
		for id in pairs( items ) do
--	        log( windower.to_shift_jis('Adding to '..action .. ' '..res.items[id].name ) )
			settings[action]:remove( res.items[id].name )
 		end
    end

    settings:save()
    force_check(command1 == 'Drop')
end

function act(action, output, id, ...)
    if settings.Verbose then
--		log( windower.to_shift_jis( '%s %s':format(output, res.items[id].name:color(258))) )
		local items = windower.ffxi.get_items()
--		log( windower.to_shift_jis( '%s %s':format(output, res.items[ items.inventory[ id ].id ].ja:color(258))) )
		log( '%s %s':format(output, res.items[ items.inventory[ id ].id ].ja:color(258) ) )
    end
end

function ContainInTable( t, key )
	windower.add_to_chat( 8, windower.to_shift_jis( "ContainInTable()" ) )
	dump( t, " " )
	isContain	= false
	for item_name, _ in ipairs( t ) do
		windower.add_to_chat( 8, windower.to_shift_jis( "ContainInTable( item_name="..item_name.." key="..key ) )
		if item_name == key then
			isContain	= true
			break
		end
	end
	return isContain
end

--pass = act+{'pass_item', 'Passing'}
function pass( slot )
	windower.ffxi.pass_item( slot )
end

--	lot = act+{'lot_item', 'Lotting'}
function lot( slot )
    log('type(slot)='..type(slot))
    log('slot='..slot)
	windower.ffxi.lot_item( slot )
end

--	drop = act+{'drop_item', 'Dropping'}
function drop( index, count )
	windower.ffxi.drop_item( index, count )
end

function use( itemName )
	local name = windower.convert_auto_trans( itemName )
	windower.send_command( windower.to_shift_jis( "input //pouches "..itemName ) )
end


function force_check()
    local items = windower.ffxi.get_items()
    -- Check treasure pool
	for index, item in pairs(items.treasure) do
--[[
    items.treasure = {
        dropper_id
        item_id
        timestamp
        --  ロットした者がいれば有効値
        lot_name
        lot_id
        lot
        lot_index
    }
]]
		check(index, res.items[item.item_id].name )
	end

    -- Check inventory for unwanted items
    if settings.AutoDrop then
        for index, item in pairs(items.inventory) do
			if type(item) == 'table' and item.id > 0 then
				if settings.Drop:containskey( res.items[item.id].name ) then
        	        drop( index, item.count )
				else
--					windower.add_to_chat( 8, windower.to_shift_jis( "item.id="..item.id.." name="..res.items[item.id].ja ) )
				end
            end
        end
    end
end

--[[
    slot_index  ：ロット欄のSlot番号
    itemName    ：アイテム名(UTF8)
]]

function check(slot_index, itemName )
	if itemName == nil then
		return
	end
--	log( "check("..slot_index..", "..itemName..")" )
	if settings.Lot:containskey( itemName ) then
        local inventory = windower.ffxi.get_items(inventory_id)
        if inventory.max - inventory.count > 1 then
			log( "ロットイン("..itemName..")" )
			lot( slot_index)
		else
			error( "かばんが一杯でロット出来ません("..itemName..")" )
        end
	elseif ( settings.Drop:containskey( itemName ) or settings.Pass:containskey( itemName ) ) then
        log( "パスしました("..itemName..")" )
        pass( slot_index )
	end
end
function find_id(name)
    if name == 'pool' then
        return pool_ids()
        
    elseif name == 'seals' then
        return S{1126, 1127, 2955, 2956, 2957}
        
    elseif name == 'currency' then
        return S{1449, 1450, 1451, 1452, 1453, 1454, 1455, 1456, 1457}
    
    elseif name == 'geodes' then
        return S{3297, 3298, 3299, 3300, 3301, 3302, 3303, 3304}

    elseif name == 'avatarites' then
        return S{3520, 3521, 3522, 3523, 3524, 3525, 3526, 3527}

    elseif name == 'crystals' then
        return S{4096, 4097, 4098, 4099, 4100, 4101, 4102, 4103}

    else
		item_ids = S{}
		for key, value in pairs( res.items ) do
			if value.name == name then
				item_ids:add( value.id )
			end
		end
		return item_ids
    end
end
stack = function()
    local wait_time = 0

    return function()
        if os.clock() - last_stack_time > 2 then
            packets.inject(packets.new('outgoing', 0x03A))
            last_stack_time = os.clock()
            wait_time = 0
        elseif os.clock() - last_stack_time > wait_time then
            wait_time = wait_time + 0.45
            stack:schedule(0.5)
        end
    end:cond(function()
        return settings.AutoStack
    end)
end()

stack_ids = S{0x01F, 0x020}
last_stack_time = 0
windower.register_event('incoming chunk', function(id, data)
    if id == 0x0D2 then		--	210
        --	ロット欄に追加
        local treasure = packets.parse('incoming', data)
		if treasure and treasure.Index and treasure.Item ~= 0 then 
            log( 'Item droped from monster / '..res.items[treasure.Item].name )
        	check(treasure.Index, res.items[treasure.Item].name )
		end
	elseif id == 0x0D3 then
		--	誰かがロット
		local tr = packets.parse('incoming', data)
		local pl = windower.ffxi.get_player()
		if tr then
			if tr['Current Lotter Name'] and tr['Current Lot'] then
				if ( tr['Current Lotter Name'] == "Aelyne" and pl.name == "Fomalhaut" )		--	別垢がロットしたらパス
					or ( tr['Current Lotter Name'] == "Fomalhaut" and pl.name == "Aelyne" ) then
					if tr['Current Lot'] ~= 0x0FFFF then	--	0x0FFFFはパス
			        	pass( tr.Index )
					end
				end
			end
		end
    elseif stack_ids:contains(id) then
		--	かばんに直接放り込まれた
		local chunk = packets.parse('incoming', data)

		-- Ignore items in other bags
        if chunk.Bag ~= inventory_id then
            return
        end
--		if id == 0x020 and chunk.Item > 0 then
        if chunk.Item and chunk.Item > 0 then
			local itemName = res.items[chunk.Item].name
			--	アイテムが追加
			if settings.AutoDrop then
				force_check()
			elseif settings.AutoUse and settings.Use:containskey( itemName ) then
				use( itemName )
			end
        else
			--	着替えなどでも受信する
            -- Don't need to stack in the other case, as a new inventory packet will come in after the drop anyway
            stack()
        end
    end
end)

windower.register_event('ipc message', function(msg)
    local args = msg:split(' ')
    if args:remove(1) == 'treasury' then
        command1 = args:remove(1)
        command2 = args:remove(1)
        lotpassdrop(command1, command2, S(args):map(tonumber))
    end
end)

windower.register_event('load', force_check:cond(table.get-{'logged_in'} .. windower.ffxi.get_info))

windower.register_event('addon command', function(command1, command2, ...)
    local args = L{...}
    local global = false

    if args[1] == 'global' then
        global = true
        args:remove(1)
    end

    command1 = command1 and command1:lower() or 'help'
    command2 = command2 and command2:lower() or nil

    local name = args:concat(' ')
    if lotpassdrop_commands:containskey(command1) then
        command1 = lotpassdrop_commands[command1]

        if addremove_commands:containskey(command2) then
            command2 = addremove_commands[command2]

            local ids = find_id( windower.from_shift_jis( name) )
            if ids:empty() then
                error('No items found that match: %s':format(name))
                return
            end
			log( "lotpassdrop("..command1..", "..command2..")" )
            lotpassdrop( command1, command2, ids )            

			log( "send_ipc_message("..command1..", "..command2..")" )
            if global then
                windower.send_ipc_message('treasury %s %s %s':format(command1, command2, ids:concat(' ')))
            end

        elseif command2 == 'clear' then
            code[command1:lower()]:clear()
            settings[command1]:clear()
            config.save(settings)

        elseif command2 == 'list' then
            log(command1 .. ':')
            for item in settings[command1]:it() do
                log('    ' .. windower.from_shift_jis( item ) )
            end

        end

    elseif command1 == 'passall' then
        for slot_index, item_table in pairs(windower.ffxi.get_items().treasure) do 
            windower.ffxi.pass_item(slot_index)
        end
        
    elseif command1 == 'lotall' then
        for slot_index, item_table in pairs(windower.ffxi.get_items().treasure) do 
            windower.ffxi.lot_item(slot_index)
        end

    elseif command1 == 'clearall' then
        code.pass:clear()
        code.lot:clear()
        code.drop:clear()
        settings.Pass:clear()
        settings.Lot:clear()
        settings.Drop:clear()
        config.save(settings)

    elseif command1 == 'autodrop' then
        if command2 then
            settings.AutoDrop = bool_values[command2:lower()]
        else
            settings.AutoDrop = not settings.AutoDrop
        end

        config.save(settings)
        log('AutoDrop %s':format(settings.AutoDrop and 'enabled' or 'disabled'))

    elseif command1 == 'autostack' then
        if command2 then
            settings.AutoStack = bool_values[command2:lower()]
        else
            settings.AutoStack = not settings.AutoStack
        end

        config.save(settings)
        log('AutoStack %s':format(settings.AutoStack and 'enabled' or 'disabled'))

    elseif command1 == 'delay' then
        if not (command2 and tonumber(command2)) then
            error('Please specify a value in seconds for the new delay')
            return
        end

        settings.Delay = tonumber(command2)
        log('Delay set to %f seconds':format(settings.Delay))

    elseif command1 == 'verbose' then
        if command2 then
            settings.Verbose = bool_values[command2:lower()]
        else
            settings.Verbose = not settings.Verbose
        end

        config.save(settings)
        log('Verbose output %s':format(settings.Verbose and 'enabled' or 'disabled'))

    elseif command1 == 'save' then
--		config.save(settings, 'all')
		config.save(settings)

    elseif command1 == 'help' then
        print('%s v%s':format(_addon.name, _addon.version))
        print('    \\cs(255,255,255)lot|pass|drop add|remove <name>\\cr - Adds or removes all items matching <name> to the specified list')
        print('    \\cs(255,255,255)lot|pass|drop clear\\cr - Clears the specified list for the current character')
        print('    \\cs(255,255,255)lot|pass list\\cr - Lists all items on the specified list for the current character')
        print('    \\cs(255,255,255)lotall|passall\\cr - Lots/Passes all items currently in the pool')
        print('    \\cs(255,255,255)clearall\\cr - Removes lotting/passing/dropping settings for this character')
        print('    \\cs(255,255,255)autodrop [on|off]\\cr - Enables/disables (or toggles) the auto-drop setting')
        print('    \\cs(255,255,255)verbose [on|off]\\cr - Enables/disables (or toggles) the verbose setting')
        print('    \\cs(255,255,255)autostack [on|off]\\cr - Enables/disables (or toggles) the autostack feature')
        print('    \\cs(255,255,255)delay <value>\\cr - Allows you to change the delay of actions (default: 0)')


    end
end)

--[[
Copyright 息 2014-2015, Windower
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of Windower nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Windower BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]
