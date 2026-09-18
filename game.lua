local alexgames = require("alexgames")

-- Estado global
local state = {
    ball = { x = 400, y = 240, vx = 0, vy = 0, radius = 10 },
    player = { x = 100, y = 240, vx = 0, vy = 0, radius = 15, up = false, down = false, left = false, right = false }
}

local FPS = 120
--local FPS = 2
local MS_PER_FRAME = math.floor(1000/FPS)

-- Dibuja el fondo, líneas y arcos
local function draw_field()

    -- Limites rectangulo 800 x 480
    alexgames.draw_rect('#c7c7c7', 0, 0, 480, 800)
    alexgames.draw_rect('#327134', 4, 4, 476, 796)

    -- Campo de juego 
    alexgames.draw_rect('#4CAF50', 60, 50, 420, 750)
    
    -- Círculo central (usamos el verde de fondo como relleno para simular transparencia)
    alexgames.draw_circle('#4CAF50', '#ffffff', 240, 400, 70, 2)
    
    -- Línea central     (color, grosor, y1, x1,  y2,  x2)
    alexgames.draw_line('#ffffff', 2, 60, 400, 420, 400)
    
    -- Arcos (representados por ahora como líneas más gruesas en los bordes)
    alexgames.draw_line('#ffffff', 4, 180, 50, 300, 50)     -- Arco izquierdo
    alexgames.draw_line('#ffffff', 4, 180, 750, 300, 750) -- Arco derecho
end

-- Calcula colisión circular y aplica fuerza
local function check_collision()
    local dx = state.ball.x - state.player.x
    local dy = state.ball.y - state.player.y
    local distance = math.sqrt(dx * dx + dy * dy)
    local min_dist = state.player.radius + state.ball.radius

    -- Si hay impacto
    if distance < min_dist then
        -- Evitar que la pelota se "meta" dentro del jugador
        local overlap = min_dist - distance
        local nx = dx / distance
        local ny = dy / distance

        state.ball.x = state.ball.x + nx * overlap
        state.ball.y = state.ball.y + ny * overlap

        -- Transferir el "pateo" (impulso a la velocidad)
        local kick_force = 400
        state.ball.vx = state.ball.vx + nx * kick_force
        state.ball.vy = state.ball.vy + ny * kick_force
    end
end

function update(dt_ms)
    local dt = dt_ms / 1000.0
    
    -- 1. Movimiento del jugador
    local speed = 250
    if state.player.up then state.player.y = state.player.y - speed * dt end
    if state.player.down then state.player.y = state.player.y + speed * dt end
    if state.player.left then state.player.x = state.player.x - speed * dt end
    if state.player.right then state.player.x = state.player.x + speed * dt end

    -- 2. Detectar colisiones
    check_collision()

    -- 3. Fricción de la pelota (hace que frene de a poco)
    state.ball.vx = state.ball.vx * 0.95
    state.ball.vy = state.ball.vy * 0.95

    -- 4. Actualizar posición de la pelota
    state.ball.x = state.ball.x + state.ball.vx * dt
    state.ball.y = state.ball.y + state.ball.vy * dt

    -- 5. Rebote de la pelota en los bordes de la pantalla
    if state.ball.x < state.ball.radius then 
        state.ball.x = state.ball.radius; state.ball.vx = -state.ball.vx * 0.8 
    end
    if state.ball.x > 750 - state.ball.radius then 
        state.ball.x = 750 - state.ball.radius; state.ball.vx = -state.ball.vx * 0.8 
    end
    if state.ball.x < 50 + state.ball.radius then 
        state.ball.x = 50 + state.ball.radius; state.ball.vx = -state.ball.vx * 0.8 
    end
    if state.ball.y < state.ball.radius then 
        state.ball.y = state.ball.radius; state.ball.vy = -state.ball.vy * 0.8 
    end
    if state.ball.y < 60 + state.ball.radius then 
        state.ball.y = 60 + state.ball.radius; state.ball.vy = -state.ball.vy * 0.8 
    end
    if state.ball.y > 420 - state.ball.radius then 
        state.ball.y = 420 - state.ball.radius; state.ball.vy = -state.ball.vy * 0.8 
    end

    -- 6. Renderizado
    alexgames.draw_clear()
    draw_field()
    
    -- Jugador (Rojo)
    alexgames.draw_circle('#ff0000', '#000000', math.floor(state.player.y), math.floor(state.player.x), state.player.radius)
    -- Pelota (Blanca)
    alexgames.draw_circle('#ffffff', '#000000', math.floor(state.ball.y), math.floor(state.ball.x), state.ball.radius)
    
    alexgames.draw_refresh()
end

function handle_key_evt(evt_id, code)
    local is_pressed = (evt_id == "keydown")
    
    if code == "ArrowUp" or code == "KeyW" then state.player.up = is_pressed
    elseif code == "ArrowDown" or code == "KeyS" then state.player.down = is_pressed
    elseif code == "ArrowLeft" or code == "KeyA" then state.player.left = is_pressed
    elseif code == "ArrowRight" or code == "KeyD" then state.player.right = is_pressed
    end
    
    return true
end

function start_game()
    alexgames.enable_evt("key")
    alexgames.set_timer_update_ms(MS_PER_FRAME)
end