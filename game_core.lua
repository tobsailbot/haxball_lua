local core = {}

local FRICTION = 0.995 
local PLAYER_FRICTION = 0.985 
local PLAYER_ACCEL = 400 

local KICKING_SPEED_MULT = 0.75
local SPEED_TRANSITION_TIME = 1.25 
local SPEED_CHANGE_RATE = (1.0 - KICKING_SPEED_MULT) / SPEED_TRANSITION_TIME
local IMPULSE_FORCE = 1
local BALL_PUSH_FACTOR = 0.075

local KICK_REACH = 8

-- Estado global actualizado para 2 jugadores (con tus nuevas físicas)
core.state = {
    ball = { x = 400, y = 240, vx = 0, vy = 0, radius = 11 },
    score = { red = 0, blue = 0 },
    players = {
        { id = 1, team = "red", color = '#ff0000', x = 200, y = 240, vx = 0, vy = 0, radius = 15, up = false, down = false, left = false, right = false, kicking = false, speed_mult = 1.0 },
        { id = 2, team = "blue", color = '#4d4dff', x = 600, y = 240, vx = 0, vy = 0, radius = 15, up = false, down = false, left = false, right = false, kicking = false, speed_mult = 1.0 }
    }
}

local function check_collision(state)
    -- 1. Colisión entre Jugadores (Física elástica para empujes)
    local p1 = state.players[1]
    local p2 = state.players[2]
    local pdx = p2.x - p1.x
    local pdy = p2.y - p1.y
    local p_dist = math.sqrt(pdx * pdx + pdy * pdy)
    if p_dist == 0 then p_dist = 0.001 end
    local p_min_dist = p1.radius + p2.radius

    if p_dist < p_min_dist then
        local nx = pdx / p_dist
        local ny = pdy / p_dist
        
        -- Separación posicional (Evita que se fusionen los cuerpos)
        local overlap = (p_min_dist - p_dist) * 0.5
        p1.x = p1.x - nx * overlap
        p1.y = p1.y - ny * overlap
        p2.x = p2.x + nx * overlap
        p2.y = p2.y + ny * overlap
        
        -- Calcular la velocidad relativa (diferencia de velocidades)
        local rvx = p1.vx - p2.vx
        local rvy = p1.vy - p2.vy
        local vel_along_normal = rvx * nx + rvy * ny
        
        if vel_along_normal > 0 then
            local restitution = 0.2 
            local impulse = (1 + restitution) * vel_along_normal * 0.5
            p1.vx = p1.vx - impulse * nx
            p1.vy = p1.vy - impulse * ny
            p2.vx = p2.vx + impulse * nx
            p2.vy = p2.vy + impulse * ny
        end
    end

    -- 2. Colisión de la Pelota con cada Jugador
    for _, p in ipairs(state.players) do
        local dx = state.ball.x - p.x
        local dy = state.ball.y - p.y
        local distance = math.sqrt(dx * dx + dy * dy)
        
        if distance == 0 then distance = 0.001 end 

        local min_dist = p.radius + state.ball.radius
        local kick_dist = min_dist + KICK_REACH 

        local nx = dx / distance
        local ny = dy / distance

        -- Resolver colisión física estricta (cuerpos tocándose)
        if distance < min_dist then
            local overlap = min_dist - distance

            -- Separación posicional adaptada:
            -- Como el jugador es más "pesado", la pelota cede el 80% del espacio
            -- y el jugador solo es movido un 20%. Esto se siente mucho mejor.
            state.ball.x = state.ball.x + nx * (overlap * 0.8)
            state.ball.y = state.ball.y + ny * (overlap * 0.8)
            p.x = p.x - nx * (overlap * 0.2)
            p.y = p.y - ny * (overlap * 0.2)

            -- Calcular la velocidad relativa entre la pelota y el jugador
            local rvx = state.ball.vx - p.vx
            local rvy = state.ball.vy - p.vy
            
            -- Calcular a qué velocidad se están impactando
            local vel_along_normal = rvx * nx + rvy * ny

            -- Si se están acercando (el valor es negativo en este caso por cómo restamos)
            if vel_along_normal < 0 then
                -- Si NO está pateando, aplicamos el rebote natural
                if not p.kicking then
                    -- RESTITUCIÓN DE LA PELOTA (Bounciness)
                    -- 0.0 = La pelota se frena al chocar. 1.0 = Rebota con toda la fuerza.
                    local ball_restitution = 0.2 
                    
                    -- Calculamos la fuerza del impacto para invertir la dirección
                    local impulse = -(1 + ball_restitution) * vel_along_normal
                    
                    -- Hacemos que la pelota rebote usando su propio vector alterado
                    state.ball.vx = state.ball.vx + impulse * nx
                    state.ball.vy = state.ball.vy + impulse * ny
                    
                    -- Opcional: Transferimos una pequeña vibración del impacto al jugador
                    -- para que pelotazos muy fuertes lo empujen un poquito hacia atrás.
                    local mass_ratio = 0.15 
                    p.vx = p.vx - (impulse * mass_ratio) * nx
                    p.vy = p.vy - (impulse * mass_ratio) * ny
                end
            end
        end

        -- Detectar pateo con tolerancia más amplia (Hitbox extendido)
        if p.kicking and distance < kick_dist then
            -- Al patear, se sobreescribe el rebote natural con la fuerza del tiro frontal
            local kick_force = IMPULSE_FORCE * 350  
            state.ball.vx = state.ball.vx + nx * kick_force
            state.ball.vy = state.ball.vy + ny * kick_force
            
            -- Desactiva el estado de pateo
            p.kicking = false
        end
    end
end

function core.update_physics(dt)
    local state = core.state

    -- Aplicar las físicas a TODOS los jugadores iterando la tabla
    for _, p in ipairs(state.players) do
        -- 1. Transición fluida del multiplicador de velocidad (cargar tiro)
        if p.kicking then
            p.speed_mult = p.speed_mult - (SPEED_CHANGE_RATE * dt)
            if p.speed_mult < KICKING_SPEED_MULT then
                p.speed_mult = KICKING_SPEED_MULT
            end
        else
            p.speed_mult = p.speed_mult + (SPEED_CHANGE_RATE * dt)
            if p.speed_mult > 1.0 then
                p.speed_mult = 1.0
            end
        end

        local current_accel = PLAYER_ACCEL * p.speed_mult

        -- 2. Calcular el vector de dirección de los inputs
        local move_x, move_y = 0, 0
        if p.up then move_y = move_y - 1 end
        if p.down then move_y = move_y + 1 end
        if p.left then move_x = move_x - 1 end
        if p.right then move_x = move_x + 1 end

        -- Normalizar el vector
        if move_x ~= 0 or move_y ~= 0 then
            local length = math.sqrt(move_x * move_x + move_y * move_y)
            move_x = move_x / length
            move_y = move_y / length
            
            -- Añadir aceleración a la VELOCIDAD del jugador
            p.vx = p.vx + move_x * current_accel * dt
            p.vy = p.vy + move_y * current_accel * dt
        end

        -- 3. Aplicar fricción (deslizamiento) al jugador
        p.vx = p.vx * PLAYER_FRICTION
        p.vy = p.vy * PLAYER_FRICTION

        -- 4. Aplicar el movimiento final al jugador según su velocidad
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt

        -- 9. Limitar al jugador dentro de la cancha (Reordenado para que sea por jugador)
        if p.x < 0 + p.radius then 
            p.x = 0 + p.radius; p.vx = 0 
        end
        if p.x > 800 - p.radius then 
            p.x = 800 - p.radius; p.vx = 0 
        end
        if p.y < 0 + p.radius then 
            p.y = 0 + p.radius; p.vy = 0 
        end
        if p.y > 480 - p.radius then 
            p.y = 480 - p.radius; p.vy = 0 
        end
    end

    -- 5. Detectar colisiones (Jugador-Jugador y Jugador-Pelota)
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
end

return core