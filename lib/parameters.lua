-- radio params

------------------------------
-- notes and todo lsit
--
-- note:
--
-- todo list:
------------------------------

parameters = {}

parameters.specs = {
  TUNER = cs.def{
    min=TUNER_MIN,
    max=TUNER_MAX,
    warp='lin',
    step=0.1,
    -- default=math.random(TUNER_MIN,TUNER_MAX),
    default = (TUNER_MAX-TUNER_MIN)/2,
    quantum=0.001,
    wrap=true,
    -- units='khz'
  },
  MAGIC_EYE_MAX_DIAMETER = cs.def{
    min=15,
    max=80,
    -- warp='lin',
    step=0.1,
    default = 80,
    -- wrap=true,
    -- units='khz'
  },
  MAGIC_EYE_WARP_CONVERGE_ATTEMPTS = cs.def{
    min=1,
    max=7,
    -- warp='lin',
    step=1,
    quantum=1,
    default = 3,
    -- wrap=true,
    -- units='khz'
  },
  MAGIC_EYE_WARP_SLIP_THROUGH_PERCENT = cs.def{
    min=0,
    max=100,
    -- warp='lin',
    step=1,
    quantum=1,
    default = 1,
    -- wrap=true,
    units='%'
  },
  DECAY_TIME = cs.def{
    min=0.1,
    max=5.0,
    warp='lin',
    step=0.1,
    -- default=math.random(TUNER_MIN,TUNER_MAX),
    default = 2,
    quantum=0.001,
    wrap=true,
    -- units='khz'
  },
  DELAY_TIME = cs.def{
    min=0,
    max=5.0,
    warp='lin',
    step=0.1,
    -- default=math.random(TUNER_MIN,TUNER_MAX),
    default = 0.2,
    quantum=0.001,
    wrap=true,
    -- units='khz'
  },
  GRAIN_DURATION = cs.def{
    min=0.001,
    max=0.2,
    warp='lin',
    step=0.001,
    -- default=math.random(TUNER_MIN,TUNER_MAX),
    default = 0.1,
    quantum=0.001,
    wrap=true,
    -- units='khz'
  }
}

function parameters.save_settings(setting)
  local setting_name = setting[1]
  local setting_value = setting[2]
  pirate_radio_settings = pirate_radio_settings and pirate_radio_settings or {}
  pirate_radio_settings[setting_name] = setting_value
  tab.save(pirate_radio_settings, SETTINGS_PATH)
end

function parameters.load_settings()
  pirate_radio_settings = tab.load(SETTINGS_PATH)
  if pirate_radio_settings then
    for k, v in pairs(pirate_radio_settings) do
      params:set(k,v)
    end
  end
end

function parameters.tuner_func()
  local setting_name = "tuner"
  local settings_value = params:get("tuner")
  tuner:set_dial_loc(settings_value,true)
  parameters.save_settings({setting_name,settings_value})
  -- update the marquee
  if marquee~=nil then
    marquee:update_playing_info(settings_value)
  end
end

function parameters.magic_eye_sensitivity_func(val)
  magic_eye.set_warp_max_constraint_attemps(val)
end

function parameters.magic_eye_noiziness_func(val)
  magic_eye.set_warp_slipthrough_percent(val)
end

function parameters.delay_func(val)
  engine.fxParam("effect_delay", val)
end

function parameters.delay_time_func(val)
  engine.fxParam("effect_delaytime", val)
end

function parameters.delay_decay_time_func(val)
  engine.fxParam("effect_delaydecaytime", val)
end

function parameters.granulator_func(val)
  engine.fxParam("effect_granulator", val)
end

function parameters.grain_duration_func(val)
  engine.fxParam("grainDur", val)
end

parameters.add_params = function()

  local specs = parameters.specs

  params:add_control("tuner","tuner",specs.TUNER)
  params:set_action("tuner", parameters.tuner_func)

  params:add_group("magic eye", 4)
  params:add_option("magic_eye_mode", "mode", {"fold", "expand"})
  params:add_control("magic_eye_max_amp", "max_amp", specs.MAGIC_EYE_MAX_DIAMETER)
  params:add_control("magic_eye_sensitivity", "sensitivity", specs.MAGIC_EYE_WARP_CONVERGE_ATTEMPTS)
  params:set_action("magic_eye_sensitivity", parameters.magic_eye_sensitivity_func)
  params:add_control("magic_eye_noiziness", "noiziness", specs.MAGIC_EYE_WARP_SLIP_THROUGH_PERCENT)
  params:set_action("magic_eye_noiziness", parameters.magic_eye_noiziness_func)

  params:add_separator("effects")
  params:add_control("delay", "delay")
  params:set_action("delay", parameters.delay_func)
  params:add_control("delay_time", "delay time", specs.DELAY_TIME)
  params:set_action("delay_time", parameters.delay_time_func)
  params:add_control("delay_decay_time", "delay decay time", specs.DECAY_TIME)
  params:set_action("delay_decay_time", parameters.delay_decay_time_func)
  params:add_control("granulator", "granulator")
  params:set_action("granulator", parameters.granulator_func)
  params:add_control("grain_duration", "grain duration", specs.GRAIN_DURATION)
  params:set_action("grain_duration", parameters.grain_duration_func)

  -- add eq params
  params:add_group("eq",#eq.bands.sliders+1)
  local eq_preset_data=fn.load_json(_path.code.."pirate-radio/lib/eq_defaults.json")
  local eq_preset_names={}
  for _,v in ipairs(eq_preset_data) do
    table.insert(eq_preset_names,v.name)
  end
  parameters.eq_names=eq_preset_names
  params:add_option("eq_preset","preset",eq_preset_names)
  params:set_action("eq_preset",function(v)
    for eq_i,eq_val in ipairs(eq_preset_data[v].eq) do
      params:set("eq"..eq_i,eq_val)
    end
  end)
  for i=1,#eq.bands.sliders,1 do
    local minmax = eq.bands.sliders[i]:get_minmax_values()
    local spec = cs.def{
      min=minmax.max,
      max=minmax.min,
      step=0.1,
      default = 0,
      quantum=0.01,
      wrap=false,
    }
    params:add{
      type="control",
      id="eq"..i,
      name="eq"..i,
      controlspec=spec,
      action=function(val)
        val = val*-1
        if initializing == false then
          local p_min = eq.bands.sliders[i].pointer_min
          local p_max = eq.bands.sliders[i].pointer_max
          local eq_val_new = util.linlin(0,minmax.min+minmax.min+1,p_min,p_max,val+minmax.min)
          local current_pointer_loc = eq.bands.sliders[i].pointer_loc
          local eq_val_delta = (eq_val_new - current_pointer_loc)
          -- print("band,val,delta, eq_val_new, current_pointer_loc",i,val,eq_val_delta, eq_val_new, current_pointer_loc)
          if eq.updating_from_ui[i] == false then
            eq.updating_from_param[i] = true
            eq:set_band_rel(i,math.floor(eq_val_delta), true)
          else
            eq.updating_from_ui[i] = false
          end
          -- if custom eq, then save it
          if params:get("eq_preset")==1 then
            eq_preset_data[1].eq[i]=-1*val
          end
        end
      end
    }
  end
end

return parameters
