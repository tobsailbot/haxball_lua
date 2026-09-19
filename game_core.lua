local core = {}
local FRICTION = 0.995 
local PLAYER_FRICTION = 0.985 
local PLAYER_ACCEL = 450 

local KICKING_SPEED_MULT = 0.75
local SPEED_TRANSITION_TIME = 1.25 
local SPEED_CHANGE_RATE = (1.0 - KICKING_SPEED_MULT) / SPEED_TRANSITION_TIME
local IMPULSE_FORCE = 1
local BALL_PUSH_FACTOR = 0.15 

local KICK_REACH = 8

-- Estado global
core.state = {
    ball = { x = 400, y = 240, vx = 0, vy = 0, radius = 11 },
    player = { 
        x = 100, y = 240, vx = 0, vy = 0, radius = 15, 
        up = false, down = false, left = false, right = false, 
        kicking = false, speed_mult = 1.0
    }
}

local function check_collision(state)
    local dx = state.ball.x - state.player.x
    local dy = state.ball.y - state.player.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    -- Prevenir división por cero
    if distance == 0 then distance = 0.001 end 

    local min_dist = state.player.radius + state.ball.radius
    local kick_dist = min_dist + KICK_REACH 

    local nx = dx / distance
    local ny = dy / distance

    -- 1. Resolver colisión física estricta (cuerpos tocándose)
    if distance < min_dist then
        local overlap = min_dist - distance

        -- Repartir la separación evita que el jugador atraviese la pelota
        state.ball.x = state.ball.x + nx * (overlap * 0.5)
        state.ball.y = state.ball.y + ny * (overlap * 0.5)
        state.player.x = state.player.x - nx * (overlap * 0.5)
        state.player.y = state.player.y - ny * (overlap * 0.5)

        -- Si la pelota va muy rápido, empuja al jugador
        local ball_speed = math.sqrt(state.ball.vx^2 + state.ball.vy^2)
        if ball_speed > 150 then 
            state.player.vx = state.player.vx - nx * ball_speed * BALL_PUSH_FACTOR
            state.player.vy = state.player.vy - ny * ball_speed * BALL_PUSH_FACTOR
        end

        -- Si chocan pero NO está pateando, aplicamos el rebote suave
        if not state.player.kicking then
            local player_speed = math.sqrt(state.player.vx^2 + state.player.vy^2)
            local bounce_force = IMPULSE_FORCE
            state.ball.vx = state.ball.vx + nx * bounce_force
            state.ball.vy = state.ball.vy + ny * bounce_force
        end
    end

    -- 2. Detectar pateo con tolerancia más amplia (Hitbox extendido)
    if state.player.kicking and distance < kick_dist then
        local kick_force = IMPULSE_FORCE * 350  
        state.ball.vx = state.ball.vx + nx * kick_force
        state.ball.vy = state.ball.vy + ny * kick_force
        
        -- Novedad: Desactiva el estado de pateo inmediatamente después de impactar.
        -- Esto obliga al jugador a soltar y volver a presionar la tecla Espacio,
        -- y le devuelve su velocidad de movimiento gradualmente.
        state.player.kicking = false
    end
end

function core.update_physics(dt)
    local state = core.state

    -- 1. Transición fluida del multiplicador de velocidad (cargar tiro)
    if state.player.kicking then
        state.player.speed_mult = state.player.speed_mult - (SPEED_CHANGE_RATE * dt)
        if state.player.speed_mult < KICKING_SPEED_MULT then
            state.player.speed_mult = KICKING_SPEED_MULT
        end
    else
        state.player.speed_mult = state.player.speed_mult + (SPEED_CHANGE_RATE * dt)
        if state.player.speed_mult > 1.0 then
            state.player.speed_mult = 1.0
        end
    end

    local current_accel = PLAYER_ACCEL * state.player.speed_mult

    -- 2. Calcular el vector de dirección de los inputs
    local move_x, move_y = 0, 0
    if state.player.up then move_y = move_y - 1 end
    if state.player.down then move_y = move_y + 1 end
    if state.player.left then move_x = move_x - 1 end
    if state.player.right then move_x = move_x + 1 end

    -- Normalizar el vector para que la aceleración diagonal no sea mayor
    if move_x ~= 0 or move_y ~= 0 then
        local length = math.sqrt(move_x * move_x + move_y * move_y)
        move_x = move_x / length
        move_y = move_y / length
        
        -- Añadir aceleración a la VELOCIDAD del jugador
        state.player.vx = state.player.vx + move_x * current_accel * dt
        state.player.vy = state.player.vy + move_y * current_accel * dt
    end

    -- 3. Aplicar fricción (deslizamiento) al jugador
    state.player.vx = state.player.vx * PLAYER_FRICTION
    state.player.vy = state.player.vy * PLAYER_FRICTION

    -- 4. Aplicar el movimiento final al jugador según su velocidad
    state.player.x = state.player.x + state.player.vx * dt
    state.player.y = state.player.y + state.player.vy * dt

    -- 5. Detectar colisiones
    check_collision(state)

    -- 6. Fricción de la pelota
    state.ball.vx = state.ball.vx * FRICTION
    state.ball.vy = state.ball.vy * FRICTION

    -- 7. Actualizar posición de la pelota
    state.ball.x = state.ball.x + state.ball.vx * dt
    state.ball.y = state.ball.y + state.ball.vy * dt

    -- 8. Rebote de la pelota en los bordes
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

    -- 9. Limitar al jugador dentro de la cancha (y anular su velocidad si choca la pared)
    if state.player.x < 0 + state.player.radius then 
        state.player.x = 0 + state.player.radius
        state.player.vx = 0 
    end
    if state.player.x > 800 - state.player.radius then 
        state.player.x = 800 - state.player.radius
        state.player.vx = 0 
    end
    if state.player.y < 0 + state.player.radius then 
        state.player.y = 0 + state.player.radius
        state.player.vy = 0 
    end
    if state.player.y > 480 - state.player.radius then 
        state.player.y = 480 - state.player.radius
        state.player.vy = 0 
    end
    print("Ball X: " .. state.ball.x .. " | Player X: " .. state.player.x)
    --print("Ball Y: " .. state.ball.y .. " | Player Y: " .. state.player.y)
end

return core