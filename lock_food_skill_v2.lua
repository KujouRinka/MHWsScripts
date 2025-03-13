--[[
app.PlayerManager
 -> app.cPlayerManageControl[0] _PlayerList
  -> app.cPlayerManageInfo _PlayerInfo
   -> app.cPlayerContextHolder _ContextHolder
    -> app.cHunterContext <Hunter>k__BackingField
     -> app.cHunterStatus <HunterStatus>k__BackingField
      -> app.cHunterMealEffect _MealEffect
       -> func setMealEffect
       -> field _IsTimerActive
       -> field _DurationTimer
       -> field _TimerMax
--]]

local meal_flag = false

local log_prefix = "LOCK_FOOD_SKILL_V2"

local meal_effect_data = sdk.create_instance("app.cMealEffect", true):add_ref()
if meal_effect_data == nil then return end
meal_effect_data:call(".ctor")

local function get_hunter_status()
    local master_player = sdk.get_managed_singleton("app.PlayerManager"):getMasterPlayer()
    local hunterStatus = master_player:get_ContextHolder():get_Hunter():get_HunterStatus()
    return hunterStatus
end

local function save_current_meal()
    local mealEffect = get_hunter_status()._MealEffect._MealEffect
    -- parameters must be specified due to multiple overloaded functions
    meal_effect_data:call("copyFrom(app.cMealEffect)", mealEffect)
    meal_flag = true
end

local function do_meal()
    get_hunter_status()._MealEffect:setMealEffect(meal_effect_data, true)
end

-- hook quest start
local quest_start = sdk.find_type_definition("app.cQuestPlaying"):get_method("enter")
local quest_end = sdk.find_type_definition("app.cQuestPlaying"):get_method("exit")

local function pre_quest_start(args)
    if meal_flag then
        do_meal()
    end
end

local function post_quest_start(retval)
    return retval
end

sdk.hook(quest_start, pre_quest_start, post_quest_start)

-- hook meal effect
local set_meal_effect = sdk.find_type_definition("app.cHunterMealEffect"):get_method("setMealEffect")

local function pre_meal_effect(args)
end

local function post_meal_effect(retval)
    save_current_meal()
    return retval
end

sdk.hook(set_meal_effect, pre_meal_effect, post_meal_effect)
