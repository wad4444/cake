--!nonstrict
local package_module = script.Parent.Parent
local TS = _G[package_module]

if TS then
	return TS.import(script, TS.getModule(script, "@rbxts", "cake"))
else
	return require(package_module.Parent.cake)
end
