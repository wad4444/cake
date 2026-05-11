local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "cake_replecs_remotes"

local is_server = RunService:IsServer()

local folder: Instance
if is_server then
	local new_folder = Instance.new("Folder")
	new_folder.Name = FOLDER_NAME
	new_folder.Parent = ReplicatedStorage
	folder = new_folder
else
	folder = ReplicatedStorage:WaitForChild(FOLDER_NAME)
end

local function create_reliable(name: string): RemoteEvent
	if is_server then
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		return remote
	else
		return folder:WaitForChild(name) :: RemoteEvent
	end
end

local function create_unreliable(name: string): UnreliableRemoteEvent
	if is_server then
		local remote = Instance.new("UnreliableRemoteEvent")
		remote.Name = name
		remote.Parent = folder
		return remote
	else
		return folder:WaitForChild(name) :: UnreliableRemoteEvent
	end
end

return table.freeze({
	request_full = create_reliable("request_full"),
	send_full = create_reliable("send_full"),
	send_unreliables = create_unreliable("send_unreliables"),
	send_updates = create_reliable("send_updates"),
})
