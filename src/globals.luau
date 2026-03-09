local RunService = game:GetService("RunService")
local globals = {
	dev_mode = RunService:IsStudio(),
	default_error_ignore_time = 10,
}

return globals
