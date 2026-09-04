local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Modules.Client.SkillPage.ExampleConfig)
local SkillTreeTypes = require(ReplicatedStorage.Modules.Shared.SkillTree.Types)

type SkillTreeConfig = SkillTreeTypes.SkillTreeConfig
type NodeConfig = SkillTreeTypes.NodeConfig
export type EffectData = SkillTreeTypes.EffectData

local function buildNodeMap(config: SkillTreeConfig): { [string]: NodeConfig }
	local nodes: { [string]: NodeConfig } = {}

	if config.nodes then
		for _, node in ipairs(config.nodes) do
			nodes[node.id] = node
		end
	end

	if config.categories then
		for _, category in ipairs(config.categories) do
			for _, node in ipairs(category.nodes) do
				nodes[node.id] = node
			end
		end
	end

	return nodes
end

local Skill = {}
Skill.node_map = buildNodeMap(Config)

local function initModule() end

initModule()
return Skill
