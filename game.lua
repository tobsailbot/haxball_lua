local alexgames = require("alexgames")
local core = require("game_core")
local draw = require("game_draw")

local FPS = 144
local MS_PER_FRAME = 1000/FPS

function update(dt_ms)
    local dt = dt_ms / 1000.0
    core.update_physics(dt)
    draw.render(core.state)
end

function handle_key_evt(evt_id, code)
    local is_pressed = (evt_id == "keydown")

    -- Controles Jugador 1 (Rojo)
    if code == "KeyW" then core.state.players[1].up = is_pressed
    elseif code == "KeyS" then core.state.players[1].down = is_pressed
    elseif code == "KeyA" then core.state.players[1].left = is_pressed
    elseif code == "KeyD" then core.state.players[1].right = is_pressed
    elseif code == "Space" then core.state.players[1].kicking = is_pressed
    
    -- Controles Jugador 2 (Azul)
    elseif code == "ArrowUp" then core.state.players[2].up = is_pressed
    elseif code == "ArrowDown" then core.state.players[2].down = is_pressed
    elseif code == "ArrowLeft" then core.state.players[2].left = is_pressed
    elseif code == "ArrowRight" then core.state.players[2].right = is_pressed
    elseif code == "ShiftRight" then core.state.players[2].kicking = is_pressed
    end
    
    return true
end

function start_game()
    alexgames.enable_evt("key")
    alexgames.set_timer_update_ms(MS_PER_FRAME)
end