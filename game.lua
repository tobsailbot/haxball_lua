local alexgames = require("alexgames")
local core = require("game_core")
local draw = require("game_draw")

local FPS = 120
local MS_PER_FRAME = math.floor(1000/FPS)

function update(dt_ms)
    local dt = dt_ms / 1000.0
    
    -- 1. Actualizar lógica de movimiento, colisiones y físicas
    core.update_physics(dt)

    -- 2. Renderizar el estado actual
    draw.render(core.state)
end

function handle_key_evt(evt_id, code)
    local is_pressed = (evt_id == "keydown")
    
    if code == "ArrowUp" or code == "KeyW" then core.state.player.up = is_pressed
    elseif code == "ArrowDown" or code == "KeyS" then core.state.player.down = is_pressed
    elseif code == "ArrowLeft" or code == "KeyA" then core.state.player.left = is_pressed
    elseif code == "ArrowRight" or code == "KeyD" then core.state.player.right = is_pressed
    end
    
    return true
end

function start_game()
    alexgames.enable_evt("key")
    alexgames.set_timer_update_ms(MS_PER_FRAME)
end