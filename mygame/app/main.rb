def boot args
  args.state = {}
end

def tick(...)
  $state.scene ||= :setup
  $outputs.background_color = [2, 2, 2]
  $outputs[:game_rt].w = 1280
  $outputs[:game_rt].h = 720
  $outputs[:game_rt].background_color = [2, 2, 2]

  send("tick_#{$state.scene}")
  $clock += 1
  $slow_clock += 0.1

  $state.scene = $state.next_scene
end

def tick_setup
    srand
    $score = 0
    $lives = 3
    $zombie_speed = 1
    $human_speed = 1
    $game_over = false
    $game_over_at = 0
    $high_score = 0
    $total_score = 0
    $show_fps = false
    $state.wave = 1
    $last_life_score = 0
    wave_selector
end

def tick_ready_for_next_wave
  # any stars, coins, or people left on screen give 1 point each
  $people.each do |p|
    # $fade_out_queue << { x: p.x, y: p.y, w: 96, h: 96, d: 0.5, s: 'black_smoke/black_smoke', path: 'sprites/black_smoke/black_smoke_1.png', anchor_x: 0.3, anchor_y: 0.35  }
    $fade_out_queue << { x: p.x, y: p.y, w: 96, h: 96, d: 0.5, s: 'white_puff/white_puff', path: 'sprites/white_puff/white_puff_1.png', anchor_x: 0.3, anchor_y: 0.35  }
    $popup_score_queue << {
      x: p.x + 30,
      y: p.y + 25,
      text: "1",
      frames: 100,
      elapsed: 0,
      base_color: { r: 255, g: 255, b: 255 }
    }
  end

  $coins.each do |c|
    $fade_out_queue << { x: c.x, y: c.y, w: 96, h: 96, d: 0.5, s: 'white_puff/white_puff', path: 'sprites/white_puff/white_puff_1.png', anchor_x: 0.3, anchor_y: 0.35  }
    $popup_score_queue << {
      x: c.x + 15,
      y: c.y + 25,
      text: "1",
      frames: 100,
      elapsed: 0,
      base_color: { r: 255, g: 255, b: 255 }
    }
  end

  $stars.each do |s|
    $fade_out_queue << { x: s.x, y: s.y, w: 96, h: 96, d: 0.5, s: 'flash/flash', path: 'sprites/flash/flash_1.png', anchor_x: 0.3, anchor_y: 0.35  }
    $popup_score_queue << {
      x: s.x + 15,
      y: s.y + 25,
      text: "1",
      frames: 100,
      elapsed: 0,
      base_color: { r: 255, g: 255, b: 255 }
    }
  end

  if $game_over
    msg = "game over"
    $outputs.labels << {
      x: 640,
      y: 325,
      size_px: 50,
      r: 0x2a, g: 0xad, b: 0xff,
      text: "high score #{$high_score}",
      font: "fonts/robotron.ttf",
      anchor_x: 0.5,
      anchor_y: 0.5 }
  else
    msg = "wave complete"
  end

  $outputs.labels << {
    x: 640,
    y: 500,
    size_px: 50,
    r: 0x2a, g: 0xad, b: 0xff,
    text: msg,
    font: "fonts/robotron.ttf",
    anchor_x: 0.5,
    anchor_y: 0.5 }

  $stars = []
  $coins = []
  $stars_inner = []
  $people = []
  $enemies = []

  $player_bullets = []
  $player_chest_bullets = []

  $score = 999999999 if $score > 999999999
  calc
  render
  wave_selector if $popup_score_queue.empty? && $fade_out_queue.empty? && $score == $total_score && !$game_over
  if $game_over
    if $clock - $game_over_at > 300
      $outputs[:game_rt].labels << $people.first($visible_count) << {
        x: 640,
        y: 150,
        size_px: 20,
        r: 0x2a, g: 0xad, b: 0xff,
        text: "press a key or click for new game",
        font: "fonts/robotron.ttf",
        anchor_x: 0.5,
        a: 200 }
      if $inputs.keyboard.key_down.truthy_keys.any? || $inputs.mouse.click
        $lives = 3
        $game_over = false
        $state.wave = 1
        wave_selector
      end
    end
  end
end

def wave_selector
  case $state.wave
  when 1
    $reveal_interval = 4
    $state.bullet_damage = 1
    $state.enemy_spawn_rate = 60
    $state.enemy_min_health = 5
    $state.enemy_health_range = 5
    $state.enemies_to_spawn = 5
    $state.stars_to_spawn = 5
    $state.coins_to_spawn = 10
    $state.people_to_spawn = 5
    wave_setup
    $state.next_scene = :menu
  when 2
    $zombie_speed *= 1.1
    $human_speed *= 1.2
    $reveal_interval = 2
    $state.bullet_damage *= 2.3
    $state.enemy_spawn_rate *= 0.5
    $state.enemy_min_health *= 2
    $state.enemy_health_range *= 2
    $state.enemies_to_spawn *= 2
    $state.stars_to_spawn = 6
    $state.coins_to_spawn *= 2
    $state.people_to_spawn *= 2
    wave_setup
    $state.next_scene = :spawn_people
  when 3
    $zombie_speed *= 1.1
    $human_speed *= 1.2
    $reveal_interval = 1
    $state.bullet_damage *= 2.3
    $state.enemy_spawn_rate *= 0.5
    $state.enemy_min_health *= 2
    $state.enemy_health_range *= 2
    $state.enemies_to_spawn *= 2
    $state.stars_to_spawn = 7
    $state.coins_to_spawn *= 2
    $state.people_to_spawn *= 2
    wave_setup
    $state.next_scene = :spawn_people
  else
    $zombie_speed *= 1.1 if $state.wave <= 5
    $human_speed *= 1.2 if $state.wave <= 5
    $reveal_interval = 1
    $state.bullet_damage *= 2.3
    $state.enemy_spawn_rate *= 0.5
    $state.enemy_min_health *= 2
    $state.enemy_health_range *= 2
    $state.enemies_to_spawn *= 2
    $state.stars_to_spawn = 8
    $state.coins_to_spawn *= 2 if $state.wave <= 5
    $state.people_to_spawn *= 2 if $state.wave <= 5
    wave_setup
    $state.next_scene = :spawn_people
  end
end

def wave_setup
  $clock = 0
  $slow_clock = 0
  $stars = []
  $coins = []
  $stars_inner = []
  $people = []
  $wave_people_count = 0
  $enemies_killed = 0
  $enemies = []
  $player_bullets = []
  $player_chest_bullets = []
  $fade_out_queue = []
  $popup_score_queue = []
  $visible_count = 0
  $last_reveal_at = 0
  $state.player = {
    x: 1280 / 2,
    y: 720 / 2,
    w: 96,
    h: 128,
    ssx: 4,
    ssy: 4,
    path: 'sprites/character_robot_idle.png',
    anchor_x: 0.5,
    anchor_y: 0.5,
    flip: false,
    standard: :true,
    chest: :true,
    standard_max: 5,
    chest_max: 5,
    scale: 1,
    fire_rate: 2,
    move_speed: 5,
    shot_speed: 2,
    shot_damage: 1,
    move_speed_multiplier: 1,
    shot_speed_multiplier: 10  }
  $state.enemies_spawned = 0
  $camera_trauma = 0
  $camera_x_offset = 0
  $camera_y_offset = 0

  $state.stars_to_spawn.times do
    x = 0
    y = 0
    loop do
      x = rand(1165) + 50
      y = rand(610) + 50
      break unless x.between?(515, 740) && y.between?(225, 460)
    end

    $stars << {
      x: x,
      y: y,
      w: 24,
      h: 24,
      path: 'sprites/star_1.png',
      ao: rand(350) }

    $stars_inner << {
      x: x,
      y: y,
      w: 24,
      h: 24,
      path: 'sprites/star_2.png' }
  end

  $stars.sort! { |a, b| b.y <=> a.y }
  $stars_inner.sort! { |a, b| b.y <=> a.y }

  $state.people_to_spawn.times do
    sprite_path = rand < 0.5 ? 'sprites/character_male_person_idle.png' : 'sprites/character_female_person_idle.png'
    x = 0
    y = 0
    loop do
      x = rand(1100) + 50
      y = rand(500) + 50
      next if x.between?(445, 740) && y.between?(135, 460)

      person_rect = { x: x, y: y, w: 98, h: 130 }

      star_collision = $stars.find do |s|
        next if (s.x - x).abs > 96 || (s.y - y).abs > 128
        Geometry.intersect_rect?(person_rect, s)
      end
      next if star_collision
      break
    end

    $people << {
      x: x,
      y: y,
      w: 96,
      h: 128,
      path: sprite_path,
      dx: 0,
      dy: 0,
      push_back_x: 0.25,
      push_back_y: 0.25,
      offscreen: false,
      person: 100,
      hp: 10,
      moving_to_x: 0,
      moving_to_y: 0,
      hunting: nil,
      speed: 1,
      total_health: 10 }
  end

  $people.each do |p|
    center_x = 590  # adjust to your screen center
    center_y = 296

    size = 150  # half width/height of patrol rectangle
    p.rectangle_waypoints = [
      { x: center_x - size, y: center_y - size },
      { x: center_x + size, y: center_y - size },
      { x: center_x + size, y: center_y + size },
      { x: center_x - size, y: center_y + size }
    ]
    p.waypoint_index = 0
  end

  # sort! { |a, b| a.y <=> b.y }
  $people.sort! { |a, b| b.y <=> a.y }

  $state.coins_to_spawn.times do
    attempts = 1
    valid_position = nil

    attempts.times do
      x = rand(1135) + 50
      y = rand(580) + 50
      next if x.between?(510, 730) && y.between?(225, 460)
      coin_rect = { x: x, y: y, w: 42, h: 42, anchor_x: 0, anchor_y: 0 }

      collides_with_person = $people.find do |p|
        next if (p.x - x).abs > 96 || (p.y - y).abs > 128
        person_rect = { x: p.x, y: p.y, w: 100, h: 130 }
        Geometry.intersect_rect?(coin_rect, person_rect)
      end

      next if collides_with_person
      valid_position = { x: x, y: y }
      break
    end

    next unless valid_position

    coin_scores = {
      gold: 10000,
      silver: 5000,
      bronze: 2500
    }

    type = ['gold', 'silver', 'bronze'].sample
    frame = [1, 2, 3, 4, 5, 6, 7].sample
    $coins << {
      x: valid_position.x,
      y: valid_position.y,
      w: 42,
      h: 42,
      path: "sprites/coins/#{type}_#{frame}.png",
      type: type,
      f: frame,
      score: coin_scores[type.to_sym]
    }
  end

  if $coins.empty?
    type = 'gold'
    frame = 7
    $coins << {
      x: 695,
      y: 300,
      w: 42,
      h: 42,
      path: "sprites/coins/#{type}_#{frame}.png",
      type: type,
      f: frame
    }
  end

  $coins.sort! { |a, b| b.y <=> a.y }

  $people.each do |p|
    pick_a_coin p
  end
end

def pick_a_coin(p)
  return if $coins.empty?
  # coin = $coins.min_by { |c| Math.sqrt((c.x - p.x)**2 + (c.y - p.y)**2) }
  coin = $coins.sample
  p.moving_to_x = coin.x - 26
  p.moving_to_y = coin.y
  dx = p.moving_to_x - p.x
  dy = p.moving_to_y - p.y
  p.coin = coin
end

def pick_a_human(z)
  # coin = $coins.min_by { |c| Math.sqrt((c.x - p.x)**2 + (c.y - p.y)**2) }s
  if $people.empty?
    z.moving_to_x = $state.player.x - 48
    z.moving_to_y = $state.player.y - 64
    z.hunting = :player
  else
    person = $people.sample
    z.moving_to_x = person.x
    z.moving_to_y = person.y
    z.hunting = person
  end
  # dx = z.moving_to_x - z.x
  # dy = z.moving_to_y - z.y
end

def family_member(x: x, y: y, sprite_path: sprite_path)
  { x: x,
    y: y,
    w: 96,
    h: 128,
    path: sprite_path,
    dx: 0,
    dy: 0,
    offscreen: false }
end

def family_parade
  $family ||= []
  $family_count ||= 0
  $spawned_family_count ||= 0
  $spawn_next_person_at ||= 0
  $robot ||= {
    x: 940,
    y: 250,
    w: 96,
    h: 128,
    path: 'sprites/character_robot_idle.png' }

  if $spawned_family_count < 5 && $clock >= $spawn_next_person_at
    sprite_path = rand < 0.5 ? 'sprites/character_male_person_idle.png' : 'sprites/character_female_person_idle.png'
    $family << family_member(x: 740 - ($spawned_family_count * 150), y: 250, sprite_path: sprite_path)
    $spawned_family_count += 1
    $spawn_next_person_at = $clock + 60
  end

  $outputs.sprites << $family
  $outputs.sprites << $robot

  $robot.x -= 1 unless $robot.x < 191
  $family.each do |f|
    f.x += 0.1
    if ($robot.x - f.x).abs < 0.5
      play_scanned_sound
      $family_count += 1
      f.offscreen = true
      $popup_score_queue << {
        x: f.x + 48,
        y: 375,
        text: "#{$family_count * 1000}",
        frames: 100,
        elapsed: 0,
        base_color: { r: 255, g: 255, b: 255 }
      }
    end
  end
  Array.reject!($family, &:offscreen)
  popup_score_menu
end

def tick_menu
  family_parade
  $outputs.labels << {
    x: 640,
    y: 500,
    size_px: 50,
    r: 0x2a, g: 0xad, b: 0xff,
    text: "ROBOTRUN 2025",
    font: "fonts/robotron.ttf",
    anchor_x: 0.5,
    anchor_y: 0.5 }

  $outputs.labels << $people.first($visible_count) << {
    x: 640,
    y: 150,
    size_px: 20,
    r: 0x2a, g: 0xad, b: 0xff,
    text: "press a key or click for new game",
    font: "fonts/robotron.ttf",
    anchor_x: 0.5,
    a: 200 }

  if $inputs.keyboard.key_down.truthy_keys.any? || $inputs.mouse.click
    $alpha = 0
    $family = []
    $family_count = 0
    $spawned_family_count = 0
    $spawn_next_person_at = 0
    $popup_score_queue = []
    # $robot.x = 940
    $robot = nil
    $state.next_scene = :spawn_people
  end
end

def popup_score_menu
  $popup_score_queue.each do |item|
    item.elapsed ||= 0
    item.elapsed += 1
    item.y += 0.5

    scale = 1.0 + Math.sin(item.elapsed * 0.1) * 0.2

    r = (item.base_color[:r] * scale).clamp(0, 255)
    g = (item.base_color[:g] * scale).clamp(0, 255)
    b = (item.base_color[:b] * scale).clamp(0, 255)

    $outputs.labels << {
      x: item.x,
      y: item.y,
      size_px: 20,
      text: item.text,
      r: r.to_i, #r: 0x2a,
      g: (r/2).to_i, # 0xad,
      b: r, #0xff,
      #r: r.to_i,
      #g: g.to_i,
      #b: b.to_i,
      font: "fonts/robotron.ttf",
      anchor_x: 0.5
    }
  end

  $popup_score_queue.reject! { |item| item.elapsed >= item.frames }
end

def tick_spawn_people
  if $visible_count < $people.length
    if $clock - $last_reveal_at >= $reveal_interval
      play_pop_sound
      $visible_count += 1
      $last_reveal_at = $clock
    end
  end

  $outputs[:game_rt].sprites << $people.first($visible_count)

  if $visible_count == $people.length &&
     $clock - $last_reveal_at >= $reveal_interval
    $visible_count = 0
    $last_reveal_at = 0
    $state.next_scene = :spawn_obstacles
  end
  draw_game_info
end

def tick_spawn_obstacles
  if $visible_count < $stars.length
    if $clock - $last_reveal_at >= $reveal_interval
      play_pop_sound
      $visible_count += 1
      $last_reveal_at = $clock
    end
  end

  spin_stars

  $outputs[:game_rt].sprites << $stars.first($visible_count)
  $outputs[:game_rt].sprites << $stars_inner.first($visible_count)
  $outputs[:game_rt].sprites << $people

  if $visible_count == $stars.length &&
     $clock - $last_reveal_at >= $reveal_interval
    $visible_count = 0
    $last_reveal_at = 0
    $state.next_scene = :spawn_coins
  end
  draw_game_info
end

def tick_spawn_coins
  if $visible_count < $coins.length
    if $clock - $last_reveal_at >= $reveal_interval
      play_pop_sound
      $visible_count += 1
      $last_reveal_at = $clock
    end
  end

  spin_stars
  spin_coins

  $outputs[:game_rt].sprites << $coins.first($visible_count)
  $outputs[:game_rt].sprites << $stars
  $outputs[:game_rt].sprites << $stars_inner
  $outputs[:game_rt].sprites << $people

  if $visible_count == $coins.length &&
     $clock - $last_reveal_at >= $reveal_interval
    $visible_count = 0
    $last_reveal_at = 0
    $state.next_scene = :spawn_enemies
  end
  draw_game_info
end

def tick_spawn_enemies
  spin_stars
  spin_coins

  $outputs[:game_rt].sprites << $coins
  $outputs[:game_rt].sprites << $stars
  $outputs[:game_rt].sprites << $stars_inner
  $outputs[:game_rt].sprites << $people

  if $visible_count < 2
    if $clock - $last_reveal_at >= $reveal_interval
      $visible_count += 1
      $last_reveal_at = $clock
    end
  else
    $visible_count = 0
    $last_reveal_at = 0
    $state.next_scene = :phase_in_player
  end
  draw_game_info
end

def tick_phase_in_player
  spin_stars
  spin_coins

  $outputs[:game_rt].sprites << $coins
  $outputs[:game_rt].sprites << $stars
  $outputs[:game_rt].sprites << $stars_inner
  $outputs[:game_rt].sprites << $people

  $alpha ||= 0
  $alpha += 4

  $outputs[:game_rt].sprites << $state.player.merge(a: $alpha)
  if $alpha > 250
    $state.next_scene = :game
    $alpha = 0
  end
  draw_game_info
end

def tick_game
  input
  calc
  render

  $score = 999999999 if $score > 999999999
end

def draw_game_info
  $outputs[:game_rt].labels << $people.first($visible_count) << {
    x: 640,
    y: 20,
    size_px: 20,
    r: 0x2a, g: 0xad, b: 0xff,
    text: "#{$state.wave} wave",
    font: "fonts/robotron.ttf",
    anchor_x: 0.5,
    a: 150 }
  $outputs[:game_rt].labels << {
    x: 50,
    y: 720,
    size_px: 20,
    r: 0x2a, g: 0xad, b: 0xff,
    text: "#{$score}",
    font: "fonts/robotron.ttf",
    a: 150 }
  lives = []
  $lives.each do |l|
    lives << {
      x: ($score.to_s.length * 15) + 100 + l * 16,
      y: 720,
      w: 12,
      h: 16,
      path: 'sprites/character_robot_idle.png',
      anchor_y: 1.1 }
  end
  $outputs[:game_rt].sprites << lives
  left = $state.enemies_to_spawn - $enemies_killed
  $outputs[:game_rt].labels << {
    x: 1000,
    y: 720,
    size_px: 20,
    r: 0x2a, g: 0xad, b: 0xff,
    text: "enemies left: #{left}",
    font: "fonts/robotron.ttf",
    a: 150 } unless left == 0

  $outputs.sprites << {
    x: 640 + $camera_x_offset,
    y: 360 + $camera_y_offset,
    w: 1280,
    h: 720,
    anchor_x: 0.5,
    anchor_y: 0.5,
    path: :game_rt
  }
end

def render
  doshake
  # $outputs.labels << {
  # $sprites.sort! { |a, b| a.y <=> b.y }
  # $sprites.sort! { |a, b| b.y <=> a.y }
  $outputs[:game_rt].sprites << $people # .sort! { |a, b| b.y <=> a.y }
  $outputs[:game_rt].sprites << $coins
  # $outputs.sprites << $enemies #.sort! { |a, b| b.y <=> a.y } #.map { |e| enemy_prefab e }
  $outputs[:game_rt].sprites << $enemies.map { |e| enemy_prefab e }
  # $outputs.sprites.sort! { |a, b| b.y <=> a.y }
  $outputs[:game_rt].sprites << $stars
  $outputs[:game_rt].sprites << $stars_inner
  #for e in $people
  #  $outputs.borders << { x: e.x, y: e.y, w: 70, h: 120, path: :pixel, r: 200, g: 200, b: 200, anchor_x: -0.2, anchor_y: -0.02 }
  #end
  unless $game_over
    $outputs[:game_rt].sprites << $state.player.merge(
      w: $state.player.w * $state.player.scale,
      h: $state.player.h * $state.player.scale,
      flip_horizontally: $state.player.flip )
  end

  $outputs[:game_rt].sprites << $fade_out_queue
  $outputs[:game_rt].sprites << $pop_up_score_queue
  if $state.player.standard
    $outputs[:game_rt].sprites << Array.map($player_bullets) do |b|
      b.merge w: 20 * $state.player.scale, h: 20 * $state.player.scale, path: 'sprites/standard_bullet.png'
    end
  end
  if $state.player.chest
    $outputs[:game_rt].sprites << Array.map($player_chest_bullets) do |b|
      b.merge w: 20 * $state.player.scale, h: 20 * $state.player.scale, path: 'sprites/chest_bullet.png'
    end
  end

  if $show_fps
    $outputs[:game_rt].labels << {
      x: 10,
      y: 700,
      size_px: 20,
      text: "fps: #{$gtk.current_framerate.round}",
      r: 0x2a, g: 0xad, b: 0xff,
      font: "fonts/robotron.ttf" }
  end
=begin
  $outputs.labels << {
    x: 8,
    y: 680,
    size_px: 20,
    r: 0x2a, g: 0xad, b: 0xff,
    text: " Simul: #{$gtk.current_framerate_calc.round}",
    font: "fonts/robotron.ttf" }
  $outputs.labels << {
    x: 10,
    y: 660,
    size_px: 20,
    r: 0x2a, g: 0xad, b: 0xff,
    text: "Rendr: #{$gtk.current_framerate_render.round}",
    font: "fonts/robotron.ttf" }
=end
draw_game_info
end

def input
  return if $game_over
  dx = 0
  dy = 0
  sx = 0
  sy = 0
  speed = $state.player.move_speed
  speed *= $state.player.move_speed_multiplier
  shot_speed = $state.player.shot_speed
  shot_speed *= $state.player.shot_speed_multiplier

  if $inputs.keyboard.a
    $state.player.flip = true
    dx = -speed
  elsif $inputs.keyboard.d
    $state.player.flip = false
    dx = speed
  end

  if $inputs.keyboard.w
    dy = speed
  elsif $inputs.keyboard.s
    dy = -speed
  end

  if $inputs.keyboard.left_arrow
    sx = -shot_speed
  elsif $inputs.keyboard.right_arrow
    sx = shot_speed
  end

  if $inputs.keyboard.up_arrow
    sy = shot_speed
  elsif $inputs.keyboard.down_arrow
    sy = -shot_speed
  end

  if dx != 0 && dy != 0
    dx *= 0.7071
    dy *= 0.7071
  end

  if sx != 0 && sy != 0
    sx *= 0.7071
    sy *= 0.7071
  end

  $state.player.x += dx
  $state.player.y += dy

  $state.player.x = $state.player.x.cap_min_max(50, 1230)
  $state.player.y = $state.player.y.cap_min_max(64, 655)

  if $inputs.mouse.held
    mx = $inputs.mouse.x
    my = $inputs.mouse.y
    dx = mx - $state.player.x
    dy = my - $state.player.y

    magnitude = Math.sqrt(dx * dx + dy * dy)

    if magnitude > 0
      sx = dx / magnitude * shot_speed
      sy = dy / magnitude * shot_speed
    end
  end

  $state.player.ssx = sx
  $state.player.ssy = sy

   $show_fps = !$show_fps if $inputs.keyboard.key_up.f
end

def calc
  if $state.player.ssx != 0 || $state.player.ssy != 0
    if $clock.zmod?($state.player.fire_rate) && $state.next_scene != :ready_for_next_wave
      flip_offset = $state.player.flip ? 4 : 0
      if $player_bullets.length < $state.player.standard_max
        $player_bullets << {
          x: $state.player.x - ((flip_offset + 7) * $state.player.scale),
          y: $state.player.y + (17 * $state.player.scale),
          sx: $state.player.ssx,
          sy: $state.player.ssy,
          offscreen: false }
      end
      if $player_chest_bullets.length < $state.player.chest_max
        $player_chest_bullets << {
          x: $state.player.x - ((flip_offset + 7) * $state.player.scale),
          y: $state.player.y - (26 * $state.player.scale),
          sx: $state.player.ssx,
          sy: $state.player.ssy,
          offscreen: false }
      end
    end
  end

  if $state.player.standard
    $player_bullets.each do |b|
      $args.audio[:laser_fire] ||= {
      input: 'sounds/laser_fire.ogg',  # Filename
      x: 0.0, y: 0.0, z: 0.0,          # Relative position to the listener, x, y, z from -1.0 to 1.0
      gain: 1.0,                       # Volume (0.0 to 1.0)
      pitch: 1.0,                      # Pitch of the sound (1.0 = original pitch)
      paused: false,                   # Set to true to pause the sound at the current playback position
      looping: false                   # Set to true to loop the sound/music until you stop it
      }
      b.x += b.sx
      b.y += b.sy
      b.offscreen = true if b.x < -20 || b.x > 1300 || b.y < -20 || b.y > 740

      t = $enemies.find do |e|
        Geometry.intersect_rect? b.merge(w: 11, h: 11, anchor_x: -0.35, anchor_y: -0.38), e.merge(w: 70, h: 120, anchor_x: -0.2, anchor_y: -0.02)
      end

      if t
        play_zombie_hit_sound
        t.hp -= $state.bullet_damage
        t.x += (b.sx * t.push_back_x)
        t.y += (b.sy * t.push_back_y)
        $fade_out_queue << { x: b.x, y: b.y, w: 40, h: 40, d: 1, s: 'explosion/explosion', path: 'sprites/explosion/explosion_1.png', anchor_x: 0.25, anchor_y: 0.25 }
        b.y = 1000 # put it offscreen, it will be culled later
        if t.hp <= 0
          $enemies.delete(t)
          $enemies_killed += 1 if t.key?(:counts)
          $total_score += 100
          $popup_score_queue << {
            x: t.x + 50,
            y: t.y + 50,
            text: "100",
            frames: 100,
            elapsed: 0,
            base_color: { r: 255, g: 255, b: 255 }
          }
        end
      end

      s = $geometry.find_intersect_rect b.merge(w: 11, h: 11, anchor_x: -0.35, anchor_y: -0.38), $stars
      if s
        $stars.delete(s)
        $stars_inner.delete_if do |i|
          i.x == s.x &&
          i.y == s.y
        end
        $total_score += 100
        $popup_score_queue << {
          x: s.x,
          y: s.y + 25,
          text: "100",
          frames: 100,
          elapsed: 0,
          base_color: { r: 255, g: 255, b: 255 }
        }
      end
    end
  end

  if $state.player.chest
    $player_chest_bullets.each do |b|
      b.x += b.sx
      b.y += b.sy
      b.offscreen = true if b.x < -20 || b.x > 1300 || b.y < -20 || b.y > 740

      t = $enemies.find do |e|
        Geometry.intersect_rect? b.merge(w: 11, h: 11, anchor_x: -0.35, anchor_y: -0.38), e.merge(w: 70, h: 120, anchor_x: -0.2, anchor_y: -0.02)
      end

      if t
        play_zombie_hit_sound
        t.hp -= $state.bullet_damage
        t.x += (b.sx * t.push_back_x)
        t.y += (b.sy * t.push_back_y)
        $fade_out_queue << { x: b.x, y: b.y, w: 40, h: 40, d: 1, s: 'explosion/explosion', path: 'sprites/explosion/explosion_1.png', anchor_x: 0.25, anchor_y: 0.25 }
        b.y = 1000 # put it offscreen, it will be culled later
        if t.hp <= 0
          $enemies.delete(t)
          $enemies_killed += 1 if t.key?(:counts)
          $total_score += 100
          $popup_score_queue << {
            x: t.x + 50,
            y: t.y + 50 ,
            text: "100",
            frames: 100,
            elapsed: 0,
            base_color: { r: 255, g: 255, b: 255 }
          }
        end
      end

      s = $geometry.find_intersect_rect b.merge(w: 11, h: 11, anchor_x: -0.35, anchor_y: -0.38), $stars
      if s
        $stars.delete(s)
        $stars_inner.delete_if do |i|
          i.x == s.x &&
          i.y == s.y
        end
        $total_score += 100
        $popup_score_queue << {
          x: s.x + 25,
          y: s.y + 25,
          text: "100",
          frames: 100,
          elapsed: 0,
          base_color: { r: 255, g: 255, b: 255 }
        }
      end
    end
  end

  # The technique was originally called “symbol to proc” (as passing a value to a method’s block slot
  # using & implicitly calls #to_proc if needed, so initial implementations added Symbol#to_proc).
  Array.reject!($player_bullets, &:offscreen)
  Array.reject!($player_chest_bullets, &:offscreen)
  # $outputs.debug.watch $player_bullets.length
  # $outputs.debug.watch $player_chest_bullets.length

  if $clock.zmod?($state.enemy_spawn_rate) && $state.enemies_spawned < $state.enemies_to_spawn && !$game_over
    $state.enemies_spawned += 1

    enemy_dx = 0
    enemy_dy = 0

    side = rand(4)  # 0 = top, 1 = left, 2 = right, 3 = bottom
    case side
    when 0  # Top
      x = random_grid_x
      y = 720
      enemy_dy = -1
    when 1  # Left
      x = -96
      y = random_grid_y
      enemy_dx = 1
    when 2  # Right
      x = 1280 + 96
      y = random_grid_y
      enemy_dx = -1
    when 3  # Bottom
      x = random_grid_x
      y = -128
      enemy_dy = 1
    end

    hp = $state.enemy_min_health + rand($state.enemy_health_range)
    enemy     = { x: x,
                  y: y,
                  w: 96,
                  h: 128,
                  path: 'sprites/character_zombie_idle.png',
                  dx: enemy_dx,
                  dy: enemy_dy,
                  push_back_x: 0.25,
                  push_back_y: 0.25,
                  offscreen: false,
                  moving_to_x: x,
                  moving_to_y: y,
                  person: 0,
                  speed: $zombie_speed,
                  total_health: hp,
                  hp: hp,
                  counts: :yes }

    pick_a_human enemy
    $enemies << enemy
    # putz "spawned: #{$enemies.first}"
  end
=begin
  $outputs.sprites << { x: 10,
                        y: 10,
                        w: 96,
                        h: 128,
                        path: 'sprites/character_zombie_idle.png',
                        dx: enemy_dx,
                        dy: enemy_dy,
                        push_back_x: 0.25,
                        push_back_y: 0.25,
                        offscreen: false,
                        hp: hp
  $outputs.borders << { x: 10, y: 10, w: 96, h: 128, path: :pixel, r: 200, g: 200, b: 200 }
=end
  old_enemies = []
  $enemies.each do |e|
    o = $geometry.find_intersect_rect e, $stars

    if o
      play_explode_sound
      $camera_trauma = 0.5
      $fade_out_queue << { x: o.x, y: o.y, w: 96, h: 96, d: 0.5, s: 'flash/flash', path: 'sprites/flash/flash_1.png', anchor_x: 0.3, anchor_y: 0.35  }
      $stars.delete(o)
      $stars_inner.delete_if do |i|
        i.x == o.x &&
        i.y == o.y
      end
      e.offscreen = true
      $enemies_killed += 1 if e.key?(:counts)
      old_enemies << e
    end

    next if o

    pick_a_human e if e.hunting.nil?
    e.x += e.dx
    e.y += e.dy

    dx = e.moving_to_x - e.x
    dy = e.moving_to_y - e.y
    distance = Math.sqrt(dx * dx + dy * dy)

    if (e.x - e.moving_to_x).abs < 1 && (e.y - e.moving_to_y).abs < 1
      e.dx = 0
      e.dy = 0
      e.hunting = nil
    else
      if distance > 0
        e.dx = dx / distance * e.speed
        e.dy = dy / distance * e.speed
      end
    end
    # $outputs.borders << { x: e.x, y: e.y, w: 70, h: 120, path: :pixel, r: 200, g: 200, b: 200, anchor_x: -0.2, anchor_y: -0.02 }
=begin
    if e.dy == -1 && e.y + e.h > 720
      e.y -= (((e.y + e.h) - 720) / e.h.to_f) * 10
    elsif e.dy == 1 && e.y < 0
      e.y -= (e.y / e.h.to_f) * 10
    end

    if e.dx == 1 && e.x < 0
      e.x -= (e.x / e.w.to_f) * 10
    elsif e.dx == -1 && e.x + e.w > 1280
      e.x -= (((e.x + e.w) - 1280) / e.w.to_f) * 10
    end
    # hacky movement adjustments, slow them down
    e.x += e.dx / 2
    e.y += ((e.dy / 2) * 0.5625)
    e.offscreen = true if e.x < -128 || e.x > 1408 || e.y < -128 || e.y > 848
=end
  end

  k = $geometry.find_intersect_rect $state.player, $enemies

  if k
    play_explode_sound
    $camera_trauma = 0.5
    $fade_out_queue << { x: $state.player.x, y: $state.player.y, w: 96, h: 96, d: 0.5, s: 'flash/flash', path: 'sprites/flash/flash_1.png', anchor_x: 0.5, anchor_y: 0.6 }
    $enemies.delete(k)
    k.offscreen = true
    $enemies_killed += 1 if k.key?(:counts)
    $lives -= 1 if $lives > 0
    $popup_score_queue << {
      x: $state.player.x,
      y: $state.player.y + 25,
      text: "100",
      frames: 100,
      elapsed: 0,
      base_color: { r: 255, g: 255, b: 255 }
    }
  end

  $enemies.delete(old_enemies)
  Array.reject!($enemies, &:offscreen)
  # $outputs.debug.watch $state.enemies.length
  brains if $clock.zmod? 30

  # process the queue
  $fade_out_queue.each do |item|
    item.f ||= 9
    item.f -= item.d

    sprite_number = (9 - item.f).clamp(1, 9).to_i
    item.a = (item.f / 8.0) * 255
    item.path = "sprites/#{item.s}_#{sprite_number}.png"
  end

  #$outputs.debug.watch $fade_out_queue.length
  $fade_out_queue.reject! { |item| item.a <= 0 }

  spin_stars
  spin_coins

  $people.each do |p|
    original_x = p.x
    original_y = p.y

    p.x += p.dx
    p.y += p.dy

    hit_star = $stars.find do |star|
      $geometry.intersect_rect?(p, star)
    end

    if hit_star
      p.hp -= 1
      if p.hp < 1
        # they died on an obstacle, pop em
        play_explode_sound
        $camera_trauma = 0.5
        $fade_out_queue << { x: hit_star.x, y: hit_star.y, w: 96, h: 96, d: 0.5, s: 'flash/flash', path: 'sprites/flash/flash_1.png', anchor_x: 0.3, anchor_y: 0.35  }
        $stars.delete(hit_star)
        $stars_inner.delete_if do |i|
          i.x == hit_star.x &&
          i.y == hit_star.y
        end
        next
      end

      p.x = original_x
      p.y = original_y
      p.bumped = true
      p.x += (p.dx * p.push_back_x * -1)
      p.y += (p.dy * p.push_back_y * -1)
      p.coin = nil

      pos = find_valid_person_position
      p.moving_to_x = pos.x
      p.moving_to_x = pos.y
      dx = p.moving_to_x - p.x
      dy = p.moving_to_y - p.y
      next
    end

    dx = p.moving_to_x - p.x
    dy = p.moving_to_y - p.y
    distance = Math.sqrt(dx * dx + dy * dy)

    if (p.x - p.moving_to_x).abs < 1 && (p.y - p.moving_to_y).abs < 1
      p.dx = 0
      p.dy = 0

      # p.moving_to_x = coin.x - 26
      # p.moving_to_y = coin.y
      # putz p.coin.x
      # putz p.moving_to_x + 26

      # if p.coin && $coins.find(p.coin)
      if p.coin && $coins.include?(p.coin)
        $popup_score_queue << {
          x: p.x + 50,
          y: p.y + 50,
          text: "#{p.coin.score}",
          frames: 100,
          elapsed: 0,
          base_color: { r: 255, g: 255, b: 255 }
        }
        $total_score += p.coin.score
        $coins.delete(p.coin)
        p.coin = nil
        $args.audio[rand] = {
        input: 'sounds/bell.ogg',  # Filename
        x: 0.0, y: 0.0, z: 0.0,          # Relative position to the listener, x, y, z from -1.0 to 1.0
        gain: 0.2,                       # Volume (0.0 to 1.0)
        pitch: 1.0,                      # Pitch of the sound (1.0 = original pitch)
        paused: false,                   # Set to true to pause the sound at the current playback position
        looping: false                   # Set to true to loop the sound/music until you stop it
        }
      end

      if !$coins.empty?
        pick_a_coin p
      else
=begin
        if p.rectangle_waypoints && !p.rectangle_waypoints.empty?
          wp = p.rectangle_waypoints[p.waypoint_index]
          p.moving_to_x = wp.x
          p.moving_to_y = wp.y

          dx = p.moving_to_x - p.x
          dy = p.moving_to_y - p.y
          distance = Math.sqrt(dx * dx + dy * dy)

          if distance > 0
            p.dx = dx / distance * p.speed
            p.dy = dy / distance * p.speed
          end

          # Move to next waypoint in cycle
          p.waypoint_index = (p.waypoint_index + 1) % p.rectangle_waypoints.length
        end
=end
        p.moving_to_x = $state.player.x - 48
        p.moving_to_y = $state.player.y - 64
      end
    else
      if distance > 0
        p.dx = dx / distance * p.speed
        p.dy = dy / distance * p.speed
      end
    end
  end

  $people.reject! { |p| p.hp < 1 }

  $popup_score_queue.each do |item|
    item.elapsed ||= 0
    item.elapsed += 1
    item.y += 0.5

    # Smooth pulse multiplier between 0.8 and 1.2
    scale = 1.0 + Math.sin(item.elapsed * 0.1) * 0.2

    r = (item.base_color[:r] * scale).clamp(0, 255)
    g = (item.base_color[:g] * scale).clamp(0, 255)
    b = (item.base_color[:b] * scale).clamp(0, 255)

    $outputs[:game_rt].labels << {
      x: item.x,
      y: item.y,
      size_px: 20,
      text: item.text,
      r: r.to_i, #r: 0x2a,
      g: (r/2).to_i, # 0xad,
      b: r, #0xff,
      #r: r.to_i,
      #g: g.to_i,
      #b: b.to_i,
      font: "fonts/robotron.ttf",
      anchor_x: 0.5
    }
  end

  if $score + 150 < $total_score
    $score += 150
  elsif $score + 25 < $total_score
    $score += 25
  elsif $score + 10 < $total_score
    $score += 10
  elsif $score + 1 <= $total_score
    $score += 1
  end

  while $total_score - $last_life_score >= 50000
    play_extra_life_sound
    $lives += 1
    $last_life_score += 50000
  end

  $popup_score_queue.reject! { |item| item.elapsed >= item.frames }

  r = $geometry.find_intersect_rect $state.player, $stars

  if r
    play_explode_sound
    $camera_trauma = 0.5
    $fade_out_queue << { x: r.x, y: r.y, w: 96, h: 96, d: 0.5, s: 'flash/flash', path: 'sprites/flash/flash_1.png', anchor_x: 0.3, anchor_y: 0.35  }
    $stars.delete(r)
    $stars_inner.delete_if do |i|
      i.x == r.x &&
      i.y == r.y
    end
    $lives -= 1 if $lives > 0
  end

  h = $geometry.find_intersect_rect $state.player, $people

  if h
    # $fade_out_queue << { x: h.x, y: h.y, w: 96, h: 96, d: 0.5, s: 'flash/flash', path: 'sprites/flash/flash_1.png', anchor_x: 0.3, anchor_y: 0.35  }
    play_scanned_sound
    $wave_people_count += 1
    score = 1000 * $wave_people_count
    score = 5000 if score > 5000
    $popup_score_queue << {
      x: h.x + 50,
      y: h.y + 50,
      text: "#{score}",
      frames: 100,
      elapsed: 0,
      base_color: { r: 255, g: 255, b: 255 }
    }
    $total_score += score
    $people.delete(h)
  end

  def find_valid_person_position
    loop do
      x = rand(1100) + 50
      y = rand(500) + 50

      # Skip if in blocked center zone
      next if x.between?(445, 740) && y.between?(135, 460)

      person_rect = { x: x, y: y, w: 98, h: 130 }

      # Skip if collides with any star
      star_collision = $stars.find do |s|
        next if (s.x - x).abs > 96 || (s.y - y).abs > 128
        Geometry.intersect_rect?(person_rect, s)
      end
      next if star_collision
      return { x: x, y: y }
    end
  end

  $high_score = $total_score if $total_score > $high_score

  if $lives < 1
    $game_over_at = $clock unless $game_over
    $game_over = true
  end
  check_next_wave
end

def check_next_wave
  if $state.enemies_to_spawn == $enemies_killed && $enemies.empty? || $game_over
    unless $state.next_scene == :ready_for_next_wave
      $state.wave += 1 unless $game_over
      $camera_trauma = 0.5
      play_explode_sound
    end
    $state.next_scene = :ready_for_next_wave
  end
end

def score_test
  $popup_score_queue << {
    x: 100,
    y: 200,
    text: "1000",
    frames: 60,
    elapsed: 0,
    base_color: { r: 255, g: 255, b: 255 }
  }
end

def spin_coins
  if $clock.zmod? 10
    $coins.each do |c|
      f = c.f
      c.path = "sprites/coins/#{c.type}_#{f}.png"
      f += 1
      f = 1 if f > 7
      c.f = f
    end
  end
end

def spin_stars
  if $clock.zmod? 6
    $stars.each do |s|
      # s.angle = ($clock + rand(100) ) % 360
      s.angle = ($clock + s.ao) % 360
    end

    $stars_inner.each do |s|
      s.a = ((Math.sin($slow_clock) + 1) / 2.0 * 245)
    end
  end
end

def random_grid_x
  16 + rand(13) * 96
end

def random_grid_y
  8 + rand(6) * 116
end

def brains
  new_zombies = []
  $enemies.each do |z|
    z.person -=20 if z.person > 0
    next if z.person != 0

    #$people.find do |p|
    #  if Geometry.intersect_rect?(z, p.merge(w: 70, h: 120, anchor_x: -0.2, anchor_y: -0.02))
    #    putz "(z.x - p.x).abs : #{(z.x - p.x).abs}"
    #    putz "(z.y - p.y).abs : #{(z.y - p.y).abs}"
    #  end
    #end

    t = $people.find do |p|
      next if (z.x - p.x).abs > 83 || (z.y - p.y).abs > 125
      Geometry.intersect_rect?(z, p.merge(w: 70, h: 120, anchor_x: -0.2, anchor_y: -0.02))
    end

    if t
      play_infected_sound
      $fade_out_queue << { x: t.x, y: t.y, w: 128, h: 128, d: 0.25, s: 'gas/gas', path: 'sprites/gas/gas_1.png', anchor_x: 0.1, anchor_y: 0 }
      t.path = 'sprites/character_zombie_idle.png'
      new_zombies << t
      $people.delete(t)
    end
  end
  #new_zombies.each do |n|
  #  n.hunting = nil
  #end
  $enemies.concat(new_zombies)
  $enemies.sort! { |a, b| b.y <=> a.y }
end

def doshake
  next_offset = 200.0 * $camera_trauma**2
  $camera_x_offset = next_offset.randomize(:sign, :ratio)
  $camera_y_offset = next_offset.randomize(:sign, :ratio)
  $camera_trauma *= 0.86
end

def play_infected_sound
  $args.audio[:infected] ||= {
  input: 'sounds/infected.ogg',    # Filename
  x: 0.0, y: 0.0, z: 0.0,          # Relative position to the listener, x, y, z from -1.0 to 1.0
  gain: 0.3,                       # Volume (0.0 to 1.0)
  pitch: 1.0,                      # Pitch of the sound (1.0 = original pitch)
  paused: false,                   # Set to true to pause the sound at the current playback position
  looping: false                   # Set to true to loop the sound/music until you stop it
  }
end

def play_extra_life_sound
  $args.audio[:extra_life] ||= {
  input: 'sounds/extra_life.ogg',  # Filename
  x: 0.0, y: 0.0, z: 0.0,          # Relative position to the listener, x, y, z from -1.0 to 1.0
  gain: 0.02,                      # Volume (0.0 to 1.0)
  pitch: 1.0,                      # Pitch of the sound (1.0 = original pitch)
  paused: false,                   # Set to true to pause the sound at the current playback position
  looping: false                   # Set to true to loop the sound/music until you stop it
  }
end

def play_scanned_sound
  $args.audio[:scanned] ||= {
  input: 'sounds/droid_scan.ogg',  # Filename
  x: 0.0, y: 0.0, z: 0.0,          # Relative position to the listener, x, y, z from -1.0 to 1.0
  gain: 0.3,                       # Volume (0.0 to 1.0)
  pitch: 1.0,                      # Pitch of the sound (1.0 = original pitch)
  paused: false,                   # Set to true to pause the sound at the current playback position
  looping: false                   # Set to true to loop the sound/music until you stop it
  }
end

def play_pop_sound
  $args.audio[rand] = {
  input: 'sounds/pop.ogg',         # Filename
  x: 0.0, y: 0.0, z: 0.0,          # Relative position to the listener, x, y, z from -1.0 to 1.0
  gain: 0.1,                       # Volume (0.0 to 1.0)
  pitch: 1.0,                      # Pitch of the sound (1.0 = original pitch)
  paused: false,                   # Set to true to pause the sound at the current playback position
  looping: false                   # Set to true to loop the sound/music until you stop it
  }
end

def play_explode_sound
  $args.audio[rand] = {
  input: 'sounds/explode.ogg',     # Filename
  x: 0.0, y: 0.0, z: 0.0,          # Relative position to the listener, x, y, z from -1.0 to 1.0
  gain: 0.2,                       # Volume (0.0 to 1.0)
  pitch: 1.0,                      # Pitch of the sound (1.0 = original pitch)
  paused: false,                   # Set to true to pause the sound at the current playback position
  looping: false                   # Set to true to loop the sound/music until you stop it
  }
end

def play_zombie_hit_sound
  # $outputs.sounds << "sounds/zombie_hit.ogg"

  $args.audio[:zombie_hit] ||= {
  input: 'sounds/zombie_hit.ogg',  # Filename
  x: 0.0, y: 0.0, z: 0.0,          # Relative position to the listener, x, y, z from -1.0 to 1.0
  gain: 0.2,                       # Volume (0.0 to 1.0)
  pitch: 1.0,                      # Pitch of the sound (1.0 = original pitch)
  paused: false,                   # Set to true to pause the sound at the current playback position
  looping: false                   # Set to true to loop the sound/music until you stop it
  }
end

def enemy_prefab enemy
  hp = (enemy.hp / enemy.total_health * 96).clamp(1, 90)
  [
    enemy,
    Geometry.center(enemy).merge(
      x: enemy.x,
      y: enemy.y,
      w: hp,
      h: 5,
      path: :pixel,
      anchor_x: -0.05,
      anchor_y: 2,
      b: 10,
      a: 150
    )
  ]
end

GTK.reset
