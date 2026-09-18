local core = {}
local FRICTION = 0.98

-- Estado global
core.state = {
    ball = { x = 400, y = 240, vx = 0, vy = 0, radius = 10 },
    player = { x = 100, y = 240, vx = 0, vy = 0, radius = 15, up = false, down = false, left = false, right = false }
}

-- Calcula colisión circular y aplica fuerza
local function check_collision(state)
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

function core.update_physics(dt)
    local state = core.state

    -- 1. Movimiento del jugador
    local speed = 250
    if state.player.up then state.player.y = state.player.y - speed * dt end
    if state.player.down then state.player.y = state.player.y + speed * dt end
    if state.player.left then state.player.x = state.player.x - speed * dt end
    if state.player.right then state.player.x = state.player.x + speed * dt end

    -- 2. Detectar colisiones
    check_collision(state)

    -- 3. Fricción de la pelota (hace que frene de a poco)
    state.ball.vx = state.ball.vx * FRICTION
    state.ball.vy = state.ball.vy * FRICTION

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
end

return core