local event = require("Event")
local GUI = require("GUI")
local log = require("Storage/Log")
local storage = {}
local _crafting = {}
local _timer = {}

local STORAGE_LOOP_DELAY = 1;

local function starts_with(str, start)
  return str:sub(1, #start) == start
end

function storage.loop()
  for name, item in pairs(_crafting) do
    --log.debug("Waiting craft to finish, ".. name)
    if item.isDone() == true then
      log.info(name .. " is done!")
      _crafting = {}
    end
    if item.isCanceled() == true then
      local state, err = item.isCanceled()
      log.warning(name .. " is canceled: " .. err)
      _crafting = {}
    end
  end
  console.debug('Done with main loop, sleeping for ' .. STORAGE_LOOP_DELAY .. ' seconds...')
  os.sleep(STORAGE_LOOP_DELAY)
end

function storage.init()
	_timer = event.addHandler(storage.loop, 0, math.huge)
end

function storage.stop()
  event.removeHandler(_timer)
end

function storage.getItemsInNetwork(filter)
  local interface = component.get("me_interface")
  return interface.getItemsInNetwork(filter)
end

function storage.isBusy()
  local name = "BaseControl"
  local cpus = component.get("me_interface").getCpus()
  for i=1,cpus.n do
    if (starts_with(cpus[i]['name'], name) and cpus[i]['busy'] == false) then
      return false
    end  
  end
  return true
end

function storage.getCraftables(filter)
  return component.get("me_interface").getItemsInNetwork({isCraftable=true})
end

function storage.isCrafting(item)
  if _crafting[item] == nil then
    return false
  end
  return true
end

function storage.getAvailableCrafter(prefix)
  local cpus = component.get("me_interface").getCpus()
  for i=1,cpus.n do
    if (starts_with(cpus[i]['name'], prefix) and cpus[i]['busy'] == false) then
      return cpus[i]['name']
    end  
  end
end

function storage.craft(item, amount)
  if storage.isBusy() then
    log.warning("[~] No crafting CPU available")
    return
  end
  if storage.isCrafting(item) then
    log.warning("[~] Already crafting item " .. item)
    return
  end

  local mod, name ,damage = item:match("([^:]+):([^:]+):([^:]+)")
  local itemData = component.get("me_interface").getCraftables({name=mod .. ':' .. name,  damage=tonumber(damage)})[1]
  local crafterName = storage.getAvailableCrafter("BaseControl")
  log.debug("Using Crafter " .. crafterName .. " for item " .. item)
  _crafting[item] = itemData.request(amount, false, crafterName)
end

return storage
