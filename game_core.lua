local alexgames = require("alexgames")
local core = {}

local FRICTION = 0.995 
local PLAYER_FRICTION = 0.985 
local PLAYER_ACCEL = 400 

local KICKING_SPEED_MULT = 0.75
local SPEED_TRANSITION_TIME = 1.25 
local SPEED_CHANGE_RATE = (1.0 - KICKING_SPEED_MULT) / SPEED_TRANSITION_TIME
local IMPULSE_FORCE = 1

local KICK_REACH = 8

-- Estado global actualizado con variables para el gol
core.state = {
    ball = { x = 400, y = 240, vx = 0, vy = 0, radius = 11 },
    score = { red = 0, blue = 0 },
    goal_scored = false,
    goal_timer = 0,
    players = {
        { id = 1, team = "red", color = '#ff0000', x = 200, y = 240, vx = 0, vy = 0, radius = 15, up = false, down = false, left = false, right = false, kicking = false, speed_mult = 1.0 },
        { id = 2, team = "blue", color = '#4d4dff', x = 600, y = 240, vx = 0, vy = 0, radius = 15, up = false, down = false, left = false, right = false, kicking = false, speed_mult = 1.0 }
    }
}

-- Constantes de los postes
local POST_RADIUS = 6
local POSTS = {
    { x = 50, y = 180 }, { x = 50, y = 300 }, -- Postes izquierdos
    { x = 750, y = 180 }, { x = 750, y = 300 } -- Postes derechos
}

-- Función para rebotar contra los postes cilíndricos
local function check_posts(entity, is_ball)
    local bounce = is_ball and 0.8 or 0.2 

    for _, post in ipairs(POSTS) do
        local dx = entity.x - post.x
        local dy = entity.y - post.y
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist == 0 then dist = 0.001 end
        
        local min_dist = entity.radius + POST_RADIUS
        if dist < min_dist then
            local overlap = min_dist - dist
            local nx = dx / dist
            local ny = dy / dist
            
            entity.x = entity.x + nx * overlap
            entity.y = entity.y + ny * overlap
            
            local vel_along_normal = entity.vx * nx + entity.vy * ny
            if vel_along_normal < 0 then
                local impulse = -(1 + bounce) * vel_along_normal
                entity.vx = entity.vx + impulse * nx
                entity.vy = entity.vy + impulse * ny
            end
        end
    end
end

-- Sistema de límites
local function apply_bounds(entity, is_ball)
    local r = entity.radius
    local bounce = is_ball and -0.8 or 0

    if entity.y < 60 + r then 
        entity.y = 60 + r; entity.vy = entity.vy * bounce 
    end
    if entity.y > 420 - r then 
        entity.y = 420 - r; entity.vy = entity.vy * bounce 
    end

    if entity.x < 50 then
        if entity.y < 180 + r then 
            entity.y = 180 + r; entity.vy = entity.vy * bounce 
        end
        if entity.y > 300 - r then 
            entity.y = 300 - r; entity.vy = entity.vy * bounce 
        end
    elseif entity.x > 750 then
        if entity.y < 180 + r then 
            entity.y = 180 + r; entity.vy = entity.vy * bounce 
        end
        if entity.y > 300 - r then 
            entity.y = 300 - r; entity.vy = entity.vy * bounce 
        end
    end

    if entity.y > 180 and entity.y < 300 then
        if entity.x < 25 + r then 
            entity.x = 25 + r; entity.vx = entity.vx * bounce 
        end
        if entity.x > 775 - r then 
            entity.x = 775 - r; entity.vx = entity.vx * bounce 
        end
    else
        if entity.x < 50 + r then 
            entity.x = 50 + r; entity.vx = entity.vx * bounce 
        end
        if entity.x > 750 - r then 
            entity.x = 750 - r; entity.vx = entity.vx * bounce 
        end
    end
end

local function check_collision(state)
    -- 1. Colisión entre Jugadores
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
        
        local overlap = (p_min_dist - p_dist) * 0.5
        p1.x = p1.x - nx * overlap
        p1.y = p1.y - ny * overlap
        p2.x = p2.x + nx * overlap
        p2.y = p2.y + ny * overlap
        
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

        if distance < min_dist then
            local overlap = min_dist - distance

            state.ball.x = state.ball.x + nx * (overlap * 0.8)
            state.ball.y = state.ball.y + ny * (overlap * 0.8)
            p.x = p.x - nx * (overlap * 0.2)
            p.y = p.y - ny * (overlap * 0.2)

            local rvx = state.ball.vx - p.vx
            local rvy = state.ball.vy - p.vy
            local vel_along_normal = rvx * nx + rvy * ny

            if vel_along_normal < 0 then
                if not p.kicking then
                    local ball_restitution = 0.2 
                    local impulse = -(1 + ball_restitution) * vel_along_normal
                    
                    state.ball.vx = state.ball.vx + impulse * nx
                    state.ball.vy = state.ball.vy + impulse * ny
                    
                    local mass_ratio = 0.15 
                    p.vx = p.vx - (impulse * mass_ratio) * nx
                    p.vy = p.vy - (impulse * mass_ratio) * ny
                end
            end
        end

        if p.kicking and distance < kick_dist then
            local kick_force = IMPULSE_FORCE * 350  
            state.ball.vx = state.ball.vx + nx * kick_force
            state.ball.vy = state.ball.vy + ny * kick_force
            p.kicking = false
        end
    end
end

-- Función nueva para revisar si la pelota cruzó la línea de gol
local function check_goal(state)
    if state.goal_scored then return end
    
    local in_goal_y = (state.ball.y > 180 and state.ball.y < 300)
    
    -- Gol a favor del equipo Azul (Arco Izquierdo)
    if state.ball.x < 50 and in_goal_y then
        state.score.blue = state.score.blue + 1
        state.goal_scored = true
        state.goal_timer = 4.0
        
        -- Cámara lenta cortando la velocidad bruscamente
        state.ball.vx = state.ball.vx * 0.2
        state.ball.vy = state.ball.vy * 0.2
        
        alexgames.set_status_msg("¡GOL DEL EQUIPO AZUL! | Marcador: Rojo " .. state.score.red .. " - Azul " .. state.score.blue)
        
    -- Gol a favor del equipo Rojo (Arco Derecho)
    elseif state.ball.x > 750 and in_goal_y then
        state.score.red = state.score.red + 1
        state.goal_scored = true
        state.goal_timer = 4.0
        
        -- Cámara lenta cortando la velocidad bruscamente
        state.ball.vx = state.ball.vx * 0.2
        state.ball.vy = state.ball.vy * 0.2
        
        alexgames.set_status_msg("¡GOL DEL EQUIPO ROJO! | Marcador: Rojo " .. state.score.red .. " - Azul " .. state.score.blue)
    end
end

function core.update_physics(dt)
    local state = core.state

    -- 1. Revisar sistema de goles
    check_goal(state)

    -- Manejar la secuencia de pausa tras el gol
    if state.goal_scored then
        state.goal_timer = state.goal_timer - dt
        
        -- Ya no aplicamos fricción continua extra. 
        -- La pelota solo recibió el frenazo inicial del 15% en check_goal().
        
        if state.goal_timer <= 0 then
            -- Restablecer las posiciones de la pelota y los jugadores
            state.ball.x, state.ball.y = 400, 240
            state.ball.vx, state.ball.vy = 0, 0
            
            state.players[1].x, state.players[1].y = 200, 240
            state.players[1].vx, state.players[1].vy = 0, 0
            
            state.players[2].x, state.players[2].y = 600, 240
            state.players[2].vx, state.players[2].vy = 0, 0
            
            state.goal_scored = false
            alexgames.set_status_msg("Marcador: Rojo " .. state.score.red .. " - Azul " .. state.score.blue)
        end
    end

    for _, p in ipairs(state.players) do
        -- Los jugadores SIEMPRE actualizan sus inputs y velocidad
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

        local move_x, move_y = 0, 0
        if p.up then move_y = move_y - 1 end
        if p.down then move_y = move_y + 1 end
        if p.left then move_x = move_x - 1 end
        if p.right then move_x = move_x + 1 end

        if move_x ~= 0 or move_y ~= 0 then
            local length = math.sqrt(move_x * move_x + move_y * move_y)
            move_x = move_x / length
            move_y = move_y / length
            
            p.vx = p.vx + move_x * current_accel * dt
            p.vy = p.vy + move_y * current_accel * dt
        end

        -- Aplicar fricción (deslizamiento) y mover al jugador
        p.vx = p.vx * PLAYER_FRICTION
        p.vy = p.vy * PLAYER_FRICTION

        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt

        -- Limitar al jugador dentro de la cancha
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

    -- Las colisiones siempre se calculan. Si patean la pelota durante los 3 segundos, saldrá disparada normal.
    check_collision(state)

    -- Fricción y movimiento estándar de la pelota
    state.ball.vx = state.ball.vx * FRICTION
    state.ball.vy = state.ball.vy * FRICTION

    state.ball.x = state.ball.x + state.ball.vx * dt
    state.ball.y = state.ball.y + state.ball.vy * dt

    check_posts(state.ball, true)
    apply_bounds(state.ball, true)
end

return core