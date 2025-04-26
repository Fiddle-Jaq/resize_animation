local S = obslua
local source_list = nil

function script_description()
  return [[
    <center><h2>jojoe resize animation</h2></center>
  ]]
end


function script_properties()
  local settings = S.obs_properties_create()

  local source_list = S.obs_properties_add_list(settings, "source_list", "Choose Source: ", S.OBS_COMBO_TYPE_LIST, S.OBS_COMBO_FORMAT_STRING)
  make_source_list(source_list)
  local scene_list = S.obs_properties_add_list(settings, "scene_list", "Choose Scene: ", S.OBS_COMBO_TYPE_LIST, S.OBS_COMBO_FORMAT_STRING)
  make_scene_list(scene_list)

  return settings
end

function make_source_list(source_list)
  local sources = S.obs_enum_sources()
  if sources ~= nil then
    for i, source in ipairs(sources) do
      local name = S.obs_source_get_name(source)
      S.obs_property_list_add_string(source_list, name, name)
    end
  end

  S.source_list_release(sources)
end

function make_scene_list(scene_list)
  local scenes = S.obs_frontend_get_scenes()
  if scenes ~= nil then
    for i, scene in ipairs(scenes) do
      local name = S.obs_source_get_name(scene)
      S.obs_property_list_add_string(scene_list, name, name)
    end
  end

  S.source_list_release(scenes)
end

function animate()
  w, h, x, y = get_instance_position()
  counter = counter + 1
  print("instance dimensions: " .. w .. "x" .. h .. " at " .. x .. "," .. y)
  print("counter: " .. counter)

  if counter < 10 then
    x_increment = 100 + (counter * 10)  -- was 20 and 5
    if h > 3000 then
      y_increment = 7500
    else
      y_increment = 100 + (counter * 10)  -- was 20 and 5
    end
  else
    x_increment = 500
    y_increment = 500
  end

  print("x increment: " .. x_increment)
  print("y increment: " .. y_increment)
  print("target height: " .. target_height)
  print("target width: " .. target_width)

  if target_height > 3000 then
    y_increment = 7500
  end

  if w < target_width then
    w = w + x_increment
    if w >= target_width then
      w = target_width
    end
  elseif w > target_width then
    w = w - x_increment
    if w <= target_width then
      w = target_width
    end
  end

  if h < target_height then
    h = h + y_increment
    if h >= target_height then
      h = target_height
    end
  elseif h > target_height then
    h = h - y_increment
    if h <= target_height then
      h = target_height
    end
  end

  pos_x = (canvas_width / 2) - (w / 2)
  pos_y = (canvas_height / 2) - (h / 2)

  print("pos x: " .. pos_x)
  print("pos y: " .. pos_y)


  resize_instance(w, h, pos_x, pos_y)

  if w == target_width and h == target_height then
    print("finished resizing")
    S.timer_remove(animate)
    S.timer_add(update_size, 100)
    -- if h < 5000 then                        BROKEN idk why 
    --   bounce_counter = 3 
    --   S.timer_add(bounce, 2500)
    -- end
  end
  
end

function bounce()
  w, h, x, y = get_instance_position()

  bounce_offset = 8

  bounce_width = target_width + (bounce_counter * bounce_offset)
  bounce_height = target_height + (bounce_counter * bounce_offset)
  bounce_increment = 4

  print("bounce_counter: " .. bounce_counter)
  print("bounce_offset: " .. bounce_offset)
  print("bounce_width " .. bounce_width)
  print("bounce_height: " .. bounce_height)
  print("bounce_increment: " .. bounce_increment)

  if target_height > (target_width * 2.5) then  -- thin, bounce width
    print("thin")
    if w < bounce_width then
      w = w + bounce_increment
      if w >= bounce_width then
        w = bounce_width
        bounce_width = target_width - (bounce_counter * bounce_offset)
      end

    elseif w > target_width then
      w = w - bounce_increment
      if w <= bounce_width then
        w = bounce_width
        bounce_width = target_width + (bounce_counter * bounce_offset)
        bounce_counter = bounce_counter - 1
      end
    end
  elseif target_width > (target_height * 2.5) then  -- wide, bounce height
    print("wide")
    if h < bounce_height then
      h = h + bounce_increment
      if h >= bounce_height then
        h = bounce_height
        bounce_height = target_height - (bounce_counter * bounce_offset)
      end
    elseif h > target_height then
      h = h - bounce_increment
      if h <= bounce_height then
        h = bounce_height
        bounce_height = target_height + (bounce_counter * bounce_offset)
        bounce_counter = bounce_counter - 1
      end
    end
  else
    print("none")
    -- no bounce
    bounce_counter = 0
  end

  pos_x = (canvas_width / 2) - (w / 2)
  pos_y = (canvas_height / 2) - (h / 2)

  if bounce_counter == 0 then
    S.timer_remove(bounce)
    pos_x = (canvas_width / 2) - (w / 2)
    pos_y = (canvas_height / 2) - (h / 2)
    w = target_width
    h = target_height

    resize_instance(w, h, pos_x, pos_Y) 
  end
end

function update_size(settings)
  local source = S.obs_get_source_by_name(source_name)
  width = S.obs_source_get_width(source)
  height = S.obs_source_get_height(source)

  if width ~= old_width or height ~= old_height then
    old_width = width
    old_height = height
    print("detected size change: " .. width .. "x" .. height)
    target_width = width
    target_height = height

    if target_width > 0 then
      if target_height > 0 then
        counter = 0
        print("resizing to " .. target_width .. "x" .. target_height)
        S.timer_remove(animate)
        S.timer_remove(update_size)
        S.timer_add(animate, interval)
      end
    end
  end
end

function get_instance_position()
  local scene = S.obs_get_scene_by_name(scene_name)
  local sceneitem = S.obs_scene_find_source(scene, source_name)
  local info = S.obs_transform_info()
  S.obs_sceneitem_get_info(sceneitem, info)

  local w = info.bounds.x
  local h = info.bounds.y
  local x = info.pos.x
  local y = info.pos.y
  S.obs_scene_release(scene)

  return w,h,x,y
end

function resize_instance(w,h,x,y)
  local scene = S.obs_get_scene_by_name(scene_name)
  local sceneitem = S.obs_scene_find_source(scene, source_name)
  local info = S.obs_transform_info()
  S.obs_sceneitem_get_info(sceneitem, info)

  info.bounds.x = w
  info.bounds.y = h
  info.pos.x = x
  info.pos.y = y

  S.obs_sceneitem_set_info(sceneitem, info)

  S.obs_scene_release(scene)
end

function ensure_stretch_to_bounds()
  local scene = S.obs_get_scene_by_name(scene_name)
  local sceneitem = S.obs_scene_find_source(scene, source_name)
  
  S.obs_sceneitem_set_bounds_type(sceneitem, 1) -- stretch to bounds 
  S.obs_sceneitem_set_bounds_alignment(sceneitem, 5) -- top left
  S.obs_sceneitem_set_alignment(sceneitem, 5) -- top left

  S.obs_scene_release(scene)
end

function script_update(settings)
  -- global variables
  counter = 0
  bounce_counter = 4
  interval = 10
  local video_info = S.obs_video_info()
  S.obs_get_video_info(video_info)    
  canvas_width = video_info.base_width
  canvas_height = video_info.base_height
  bounce_width = canvas_width
  bounce_height = canvas_height
  source_name = S.obs_data_get_string(settings, "source_list")
  scene_name = S.obs_data_get_string(settings, "scene_list")

  ensure_stretch_to_bounds()

  local source = S.obs_get_source_by_name(source_name)
  old_width, width = S.obs_source_get_width(source)
  old_height, height = S.obs_source_get_height(source)

  S.timer_remove(update_size)
  S.timer_add(update_size, 100)
end
