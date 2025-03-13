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


local master_player = sdk.get_managed_singleton("app.PlayerManager"):getMasterPlayer()
local hunter_status = master_player:get_ContextHolder():get_Hunter():get_HunterStatus()

local mealEffect = hunter_status:get_MealEffect()
local mealEffect = hunter_status._MealEffect

local set_meal_effect = sdk.find_type_definition("app.cHunterMealEffect"):get_method("setMealEffect")

local function preMeal(args)
end

local function postMeal(retval)
    mealEffect:set_field("_TimerMax", 36000.0)
    mealEffect:set_field("_DurationTimer", 36000.0)
    return retval
end

sdk.hook(set_meal_effect, preMeal, postMeal)


local quest_start = sdk.find_type_definition("app.cQuestPlaying"):get_method("enter")

local function pre_quest_start(args)
    local max_stamina_add = mealEffect._MaxStaminaAdd
    hunter_status._Stamina:call("setStaminaMax", max_stamina_add)
    hunter_status._Stamina:set_field("_AutoMaxReduceTimer", 900.0)
end

local function post_quest_start(retval)
    return retval
end

sdk.hook(quest_start, pre_quest_start, post_quest_start)
