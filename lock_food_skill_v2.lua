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
local meal_effect_call_from_script = false

local on_start_check = false

local log_prefix = "LOCK_FOOD_V2"

local meal_effect_data = sdk.create_instance("app.cMealEffect", true):add_ref()
if meal_effect_data == nil then return end
meal_effect_data:call(".ctor")

local function get_hunter_status()
    local master_player = sdk.get_managed_singleton("app.PlayerManager"):getMasterPlayer()
    local hunterStatus = master_player:get_ContextHolder():get_Hunter():get_HunterStatus()
    return hunterStatus
end

local function save_current_meal(time)
    local mealEffect = get_hunter_status()._MealEffect._MealEffect
    if not on_start_check then
        local mem_time_duration = mealEffect._DurationTimer
        if mem_time_duration % 1 ~= 0 or mem_time_duration % 10 ~= 0 then
            local file_time_duration = tonumber(fs.read("lock_food_skill.dat"))
            mealEffect:set_field("_DurationTimer", file_time_duration)
        end
    end
    -- parameters must be specified due to multiple overloaded functions
    meal_effect_data:call("copyFrom(app.cMealEffect)", mealEffect)

    -- todo: record get_hunter_status()._MealEffect._MealEffect._DurationTimer to file
    if time ~= nil then
        meal_effect_data:set_field("_DurationTimer", tonumber(time))
    else
        fs.write("lock_food_skill.dat", mealEffect._DurationTimer)
    end
    meal_flag = true
end

local function do_meal()
    meal_effect_call_from_script = true
    get_hunter_status()._MealEffect:setMealEffect(meal_effect_data, true)
    meal_effect_call_from_script = false
end

-- hook quest start
local quest_start = sdk.find_type_definition("app.cQuestPlaying"):get_method("enter")
local quest_end = sdk.find_type_definition("app.cQuestPlaying"):get_method("exit")


local function pre_quest_start(args)
    local meal_effect = get_hunter_status()._MealEffect
    if (not on_start_check) and meal_effect._IsEffectActive then
        -- todo: read from file and write to get_hunter_status()._MealEffect._MealEffect._DurationTimer
        local duration_timer = fs.read("lock_food_skill.dat")
        if duration_timer ~= "" then
            save_current_meal(duration_timer)
        end
        on_start_check = true
    end
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
    if not meal_effect_call_from_script then
        save_current_meal()
    end
    return retval
end

sdk.hook(set_meal_effect, pre_meal_effect, post_meal_effect)
