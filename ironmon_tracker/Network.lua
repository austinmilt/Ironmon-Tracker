Network = {
	CurrentConnection = {},
	lastUpdateTime = 0,
	TEXT_UPDATE_FREQUENCY = 3, -- # of seconds
	SOCKET_UPDATE_FREQUENCY = 2, -- # of seconds
	HTTP_UPDATE_FREQUENCY = 2, -- # of seconds
	TEXT_INBOUND_FILE = "Inbound-Tracker.txt", -- The CLIENT's inbound data file; Tracker is the "Server" and will write responses to this file
	TEXT_OUTBOUND_FILE = "Outbound-Tracker.txt", -- The CLIENT's outbound data file; Tracker is the "Server" and will read requests from this file
	SOCKET_SERVER_NOT_FOUND = "Socket server was not initialized",
}

Network.ConnectionTypes = {
	None = "None",
	Text = "Text",

	-- WebSockets WARNING: Bizhawk must be started with command line arguments to enable connections
	-- It must also be a custom/new build of Bizhawk that actually supports asynchronous web sockets (not released yet)
	WebSockets = "WebSockets",

	-- HTTP WARNING: If Bizhawk is not started with command line arguments to enable connections
	-- Then an internal Bizhawk error will crash the tracker. This cannot be bypassed with pcall() or other exception handling
	-- Consider turning off "AutoConnectStartup" if exploring Http
	Http = "Http",
}

Network.Options = {
	["AutoConnectStartup"] = true,
	["ConnectionType"] = Network.ConnectionTypes.None,
	["DataFolder"] = "",
	["WebSocketIP"] = "0.0.0.0", -- 127.0.0.1
	["WebSocketPort"] = "8080",
	["HttpGet"] = "",
	["HttpPost"] = "",
}

function Network.initialize()
	Network.loadConnectionSettings()
	Network.lastUpdateTime = 0
end

function Network.isConnected()
	return Network.CurrentConnection and Network.CurrentConnection.IsConnected ~= false
end

---@return table supportedTypes
function Network.getSupportedConnectionTypes()
	local supportedTypes = {}
	table.insert(supportedTypes, Network.ConnectionTypes.WebSockets) -- Not fully supported
	table.insert(supportedTypes, Network.ConnectionTypes.Http) -- Not fully supported
	table.insert(supportedTypes, Network.ConnectionTypes.Text)
	table.insert(supportedTypes, Network.ConnectionTypes.None)
	return supportedTypes
end

function Network.loadConnectionSettings()
	Network.CurrentConnection = nil
	Network.changeConnection(Network.Options["ConnectionType"] or Network.ConnectionTypes.None)
	if Network.Options["AutoConnectStartup"] then
		Network.tryConnect()
	end
end

---Changes the current connection type
---@param connectionType string A Network.ConnectionTypes enum
function Network.changeConnection(connectionType)
	connectionType = connectionType or Network.ConnectionTypes.None
	-- Create or swap to a new connection
	if not Network.CurrentConnection or Network.CurrentConnection.Type ~= connectionType then
		if Network.isConnected() then
			Network.closeConnections()
		end
		Network.CurrentConnection = Network.IConnection:new({ Type = connectionType })
		Network.Options["ConnectionType"] = connectionType
		Main.SaveSettings(true)
	end
end

---Attempts to connect to the network using the current connection; returns connection status
---@return boolean isConnected
function Network.tryConnect()
	local C = Network.CurrentConnection or {}
	-- Create or swap to a new connection
	if not C.Type then
		Network.changeConnection(Network.ConnectionTypes.None)
		C = Network.CurrentConnection
	end
	if C.IsConnected then
		return true
	end
	if C.Type == Network.ConnectionTypes.WebSockets then
		if true then return false end -- Not fully supported
		C.UpdateFrequency = Network.SOCKET_UPDATE_FREQUENCY
		C.UpdateFunction = Network.updateBySocket
		C.SocketIP = Network.Options["WebSocketIP"] or "0.0.0.0"
		C.SocketPort = tonumber(Network.Options["WebSocketPort"] or "") or 0
		local serverInfo
		if C.SocketIP ~= "0.0.0.0" and C.SocketPort ~= 0 then
			comm.socketServerSetIp(C.SocketIP)
			comm.socketServerSetPort(C.SocketPort)
			serverInfo = comm.socketServerGetInfo() or Network.SOCKET_SERVER_NOT_FOUND
			-- TODO: Might also test/try 'bool comm.socketServerIsConnected()'
		end
		C.IsConnected = serverInfo and Utils.containsText(serverInfo, Network.SOCKET_SERVER_NOT_FOUND)
		if C.IsConnected then
			comm.socketServerSetTimeout(500) -- # of milliseconds
		end
	elseif C.Type == Network.ConnectionTypes.Http then
		if true then return false end -- Not fully supported
		C.UpdateFrequency = Network.HTTP_UPDATE_FREQUENCY
		C.UpdateFunction = Network.updateByHttp
		C.HttpGetUrl = Network.Options["HttpGet"] or ""
		C.HttpPostUrl = Network.Options["HttpPost"] or ""
		if C.HttpGetUrl ~= "" then
			-- Necessary for comm.httpTest()
			comm.httpSetGetUrl(C.HttpGetUrl)
		end
		if C.HttpPostUrl ~= "" then
			-- Necessary for comm.httpTest()
			comm.httpSetPostUrl(C.HttpPostUrl)
		end
		local result
		if C.HttpGetUrl ~= "" and C.HttpPostUrl then
			-- See HTTP WARNING at the top of this file
			pcall(function() result = comm.httpTest() or "N/A" end)
		end
		C.IsConnected = result and Utils.containsText(result, "done testing")
		if C.IsConnected then
			comm.httpSetTimeout(500) -- # of milliseconds
		end
	elseif C.Type == Network.ConnectionTypes.Text then
		C.UpdateFrequency = Network.TEXT_UPDATE_FREQUENCY
		C.UpdateFunction = Network.updateByText
		local folder = Network.Options["DataFolder"] or ""
		C.InboundFile = folder .. FileManager.slash .. Network.TEXT_INBOUND_FILE
		C.OutboundFile = folder .. FileManager.slash .. Network.TEXT_OUTBOUND_FILE
		C.IsConnected = (folder ~= "") and FileManager.folderExists(folder)
	end
	if C.IsConnected then
		RequestHandler.addNewRequest(RequestHandler.IRequest:new({
			EventType = RequestHandler.Events["TS_Start"].Key,
		}))
	end
	return C.IsConnected
end

--- Closes any active connections and saves outstanding Requests
function Network.closeConnections()
	if Network.isConnected() then
		RequestHandler.addNewRequest(RequestHandler.IRequest:new({
			EventType = RequestHandler.Events["TS_Stop"].Key,
		}))
		Network.CurrentConnection:TryUpdate()
		Network.CurrentConnection.IsConnected = false
	end
	RequestHandler.saveData()
end

function Network.update()
	-- Only check for possible update once every 10 frames
	if Program.Frames.highAccuracyUpdate ~= 0 or not Network.isConnected() then
		return
	end

	RequestHandler.tryNotifyConfigChanges()

	-- Check for any new, unqiue requests, process them accordingly, and send back responses
	Network.CurrentConnection:TryUpdate()

	RequestHandler.trySaveData()
end

--- The update function used by the "Text" Network connection type
function Network.updateByText()
	local C = Network.CurrentConnection
	if not C.OutboundFile or not C.InboundFile or not FileManager.JsonLibrary then
		return
	end

	-- Part 1: Read new requests from the other application's outbound text file
	local newRequests = FileManager.decodeJsonFile(C.OutboundFile)
	for _, request in pairs(newRequests or {}) do
		RequestHandler.addNewRequest(RequestHandler.IRequest:new({
			GUID = request.GUID,
			EventType = request.EventType,
			CreatedAt = request.CreatedAt,
			Username = request.Username,
			Args = request.Args,
		}))
	end

	-- Part 2: Process the requests
	RequestHandler.processAllRequests()

	-- Part 3: Send responses to the other application's inbound text file
	local responses = RequestHandler.getResponses()
	-- Prevent consecutive "empty" file writes
	if #responses > 0 or not C.InboundWasEmpty then
		local success = FileManager.encodeToJsonFile(C.InboundFile, responses)
		C.InboundWasEmpty = (success == false) -- false if no resulting json data
		RequestHandler.clearResponses()
	end
end

--- The update function used by the "Socket" Network connection type
function Network.updateBySocket()
	local C = Network.CurrentConnection
	if C.SocketIP == "0.0.0.0" or C.SocketPort == 0 or not FileManager.JsonLibrary then
		return
	end

	-- TODO: Not implemented. Requires custom Bizhawk build with asynchronous websocket fixes
	if true then
		return
	end

	-- Part 1: Read new requests from the other application
	local input = ""
	local newRequests = FileManager.JsonLibrary.decode(input) or {}
	for _, request in pairs(newRequests or {}) do
		RequestHandler.addNewRequest(RequestHandler.IRequest:new({
			GUID = request.GUID,
			EventType = request.EventType,
			CreatedAt = request.CreatedAt,
			Username = request.Username,
			Args = request.Args,
		}))
	end

	-- Part 2: Process the requests
	RequestHandler.processAllRequests()

	-- Part 3: Send responses to the other application
	local responses = RequestHandler.getResponses()
	if #responses > 0 then
		local output = FileManager.JsonLibrary.encode(responses) or "[]"
		RequestHandler.clearResponses()
	end
end

--- The update function used by the "Http" Network connection type
function Network.updateByHttp()
	local C = Network.CurrentConnection
	if C.HttpGetUrl == "" or C.HttpPostUrl == "" or not FileManager.JsonLibrary then
		return
	end

	-- Part 1: Read new requests from the other application
	local resultGet = comm.httpGet(C.HttpGetUrl) or ""
	local newRequests = FileManager.JsonLibrary.decode(resultGet) or {}
	for _, request in pairs(newRequests or {}) do
		RequestHandler.addNewRequest(RequestHandler.IRequest:new({
			GUID = request.GUID,
			EventType = request.EventType,
			CreatedAt = request.CreatedAt,
			Username = request.Username,
			Args = request.Args,
		}))
	end

	-- Part 2: Process the requests
	RequestHandler.processAllRequests()

	-- Part 3: Send responses to the other application
	local responses = RequestHandler.getResponses()
	if #responses > 0 then
		local payload = FileManager.JsonLibrary.encode(responses) or "[]"
		local resultPost = comm.httpPost(C.HttpPostUrl, payload)
		Utils.printDebug("POST Response Code: %s", resultPost or "N/A")
		RequestHandler.clearResponses()
	end
end

-- Connection object prototype
Network.IConnection = {
	Type = Network.ConnectionTypes.None,
	IsConnected = false,
	UpdateFrequency = -1, -- Number of seconds; 0 or less will prevent updates
	UpdateFunction = function(self) end,
	-- Don't override the follow functions
	TryUpdate = function(self, updateFunc)
		if (self.UpdateFrequency or 0) > 0 and (os.time() - Network.lastUpdateTime) >= self.UpdateFrequency then
			updateFunc = updateFunc or self.UpdateFunction
			if type(updateFunc) == "function" then
				updateFunc(self)
			end
			Network.lastUpdateTime = os.time()
		end
	end,
}
function Network.IConnection:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- Not supported

-- [Web Sockets] Streamer.bot Docs
-- https://wiki.streamer.bot/en/Servers-Clients
-- https://wiki.streamer.bot/en/Servers-Clients/WebSocket-Server
-- https://wiki.streamer.bot/en/Servers-Clients/WebSocket-Server/Requests
-- https://wiki.streamer.bot/en/Servers-Clients/WebSocket-Server/Events
-- [Web Sockets] Bizhawk Docs
-- string comm.socketServerGetInfo 		-- returns the IP and port of the Lua socket server
-- bool comm.socketServerIsConnected 	-- socketServerIsConnected
-- string comm.socketServerResponse 	-- Receives a message from the Socket server. Formatted with msg length at start, e.g. "3 ABC"
-- int comm.socketServerSend 			-- sends a string to the Socket server
-- void comm.socketServerSetTimeout 	-- sets the timeout in milliseconds for receiving messages
-- bool comm.socketServerSuccessful 	-- returns the status of the last Socket server action

-- --- Registering an event is required to enable you to listen to events emitted by Streamer.bot:
-- --- https://wiki.streamer.bot/en/Servers-Clients/WebSocket-Server/Events
-- ---@param requestId string Example: "123"
-- ---@param eventSource string Example: "Command"
-- ---@param eventTypes table Example: { "Message", "Whisper" }
-- function Network.registerWebSocketEvent(requestId, eventSource, eventTypes)
-- 	local registerFormat = [[{"request":"Subscribe","id":"%s","events":{"%s":[%s]}}]]
-- 	local requestStr = string.format(registerFormat, requestId, eventSource, table.concat(eventTypes, ","))
-- 	local response = comm.socketServerSend(requestStr)
-- 	-- -1 = failed ?
-- end