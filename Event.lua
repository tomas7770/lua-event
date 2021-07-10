local Event = {}
Event.__index = Event

local CreateConnection
local Connection = {}
Connection.__index = Connection

local function find(haystack, needle)
	for i = 1,#haystack do
		if haystack[i] == needle then
			return i
		end
	end
end

function Event.new()
	local NewEvent = {
		_Connections = {},
	}
	setmetatable(NewEvent, Event)
	return NewEvent
end

function Event:Fire(...)
	local CurrentConnections = {}
	for _,Connection in ipairs(self._Connections) do
		table.insert(CurrentConnections, Connection)
	end
	for i = #CurrentConnections,1,-1 do
		local Connection = CurrentConnections[i]
		if Connection.Connected then
			if Connection._Callback then
				coroutine.wrap(Connection._Callback)(...)
			elseif Connection._Thread then
				coroutine.resume(Connection._Thread, ...)
			end
		end
	end
end

function Event:Connect(Callback)
	local NewConnection = CreateConnection(self, Callback)
	table.insert(self._Connections, NewConnection)
	return NewConnection
end

function Event:Wait()
	local Thread = coroutine.running()
	local NewConnection = CreateConnection(self, nil, Thread)
	table.insert(self._Connections, NewConnection)
	return coroutine.yield()
end

function CreateConnection(Event, Callback, Thread)
	assert(Event)
	assert(not (Callback and Thread))
	if Callback then
		assert(type(Callback) == "function")
	elseif Thread then
		assert(type(Thread) == "thread")
	else
		error()
	end
	local NewConnection = {
		Connected = true,
		_Event = Event,
		_Callback = Callback,
		_Thread = Thread,
	}
	setmetatable(NewConnection, Connection)
	return NewConnection
end

function Connection:Disconnect()
	self.Connected = false
	local EventConnections = self._Event._Connections
	local i = find(EventConnections, self)
	if i then
		table.remove(EventConnections, i)
	end
end

return Event
