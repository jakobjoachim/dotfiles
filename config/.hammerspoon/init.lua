local eventtap = require('hs.eventtap')
local fs = require('hs.fs')
require('hs.ipc')
local timer = require('hs.timer')
local event = eventtap.event

local aerospace = {}
aerospace.binary = nil
aerospace.minSwipeDistance = 0.18
aerospace.maxVerticalDrift = 0.12
aerospace.cooldown = 0.45
aerospace.debug = false

local gesture = {
  active = false,
  startX = nil,
  startY = nil,
  lastTriggeredAt = 0,
}

local function log(message)
  if aerospace.debug then
    print('[aerospace gestures] ' .. message)
  end
end

local function runAerospace(command)
  if not aerospace.binary then
    hs.alert.show('aerospace binary not found')
    return
  end

  local shellCommand = string.format(
    '%s list-workspaces --monitor focused --empty no | %s workspace --wrap-around --stdin %s',
    aerospace.binary,
    aerospace.binary,
    command
  )

  hs.execute(shellCommand, false)
end

local function findAerospaceBinary()
  local candidates = {
    '/opt/homebrew/bin/aerospace',
    '/usr/local/bin/aerospace',
  }

  for _, candidate in ipairs(candidates) do
    if fs.attributes(candidate) then
      return candidate
    end
  end

  return nil
end

local function resetGesture()
  gesture.active = false
  gesture.startX = nil
  gesture.startY = nil
end

local function averageTouchPosition(touches)
  local x = 0
  local y = 0
  local count = 0

  for _, touch in ipairs(touches) do
    if touch.touching and touch.type == 'indirect' and touch.normalizedPosition then
      x = x + touch.normalizedPosition.x
      y = y + touch.normalizedPosition.y
      count = count + 1
    end
  end

  if count == 0 then
    return nil
  end

  return {
    x = x / count,
    y = y / count,
    count = count,
  }
end

local function handleGesture(e)
  local touches = e:getTouches()
  if not touches then
    return false
  end

  local position = averageTouchPosition(touches)
  if not position or position.count < 3 then
    resetGesture()
    return false
  end

  if not gesture.active then
    gesture.active = true
    gesture.startX = position.x
    gesture.startY = position.y
    log(string.format('start: count=%d x=%.3f y=%.3f', position.count, position.x, position.y))
    return false
  end

  local dx = position.x - gesture.startX
  local dy = position.y - gesture.startY
  local now = timer.secondsSinceEpoch()

  if math.abs(dx) < aerospace.minSwipeDistance then
    return false
  end

  if math.abs(dy) > aerospace.maxVerticalDrift then
    resetGesture()
    log(string.format('cancel: vertical drift %.3f', dy))
    return false
  end

  if now - gesture.lastTriggeredAt < aerospace.cooldown then
    return false
  end

  gesture.lastTriggeredAt = now
  resetGesture()

  if dx < 0 then
    log('swipe left -> next workspace')
    runAerospace('next')
  else
    log('swipe right -> previous workspace')
    runAerospace('prev')
  end

  return false
end

aerospace.binary = findAerospaceBinary()

if not hs.accessibilityState(true) then
  hs.alert.show('Hammerspoon needs Accessibility permission')
end

aerospace.gestureTap = eventtap.new({ event.types.gesture }, handleGesture)
aerospace.gestureTap:start()

if aerospace.binary then
  hs.alert.show('Hammerspoon AeroSpace gestures loaded')
else
  hs.alert.show('Hammerspoon loaded, aerospace not found')
end
