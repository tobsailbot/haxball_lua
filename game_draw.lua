local alexgames = require("alexgames")
local draw = {}

local function draw_field()
    alexgames.draw_rect('#327134', 0, 0, 480, 800)
    alexgames.draw_rect('#327134', 4, 4, 476, 796)
    alexgames.draw_rect('#4CAF50', 60, 50, 420, 750)
    alexgames.draw_circle('#4CAF50', '#ededed', 240, 400, 70, 4)
    alexgames.draw_line('#ededed', 4, 60, 400, 420, 400)
    -- Dibujar arcos de las porterías
    alexgames.draw_rect('#ededed', 180, 25, 300, 50) -- Portería izquierda
    alexgames.draw_rect('#ededed', 180, 750, 300, 775) -- Portería derecha

    -- Lineas de borde de la cancha
    alexgames.draw_line('#ededed', 4, 58, 50, 422, 50) -- Lado izquierdo
    alexgames.draw_line('#ededed', 4, 58, 750, 422, 750) -- Lado derecho
    alexgames.draw_line('#ededed', 4, 60, 50, 60, 750) -- Fondo izquierdo
    alexgames.draw_line('#ededed', 4, 420, 50, 420, 750) -- Fondo derecho

    -- Postes izquierdos (Circulos blancos con borde negro)
    alexgames.draw_circle('#ededed', '#b0b0b0', 180, 50, 6, 2)
    alexgames.draw_circle('#ededed', '#b0b0b0', 300, 50, 6, 2)
    
    -- Postes derechos
    alexgames.draw_circle('#ededed', '#b0b0b0', 180, 750, 6, 2)
    alexgames.draw_circle('#ededed', '#b0b0b0', 300, 750, 6, 2)
end

function draw.render(state)
    alexgames.draw_clear()
    
    draw_field()
    
    -- Recorrer y dibujar a todos los jugadores
    for _, p in ipairs(state.players) do
        -- Configurar borde del jugador según su propio estado de pateo
        local p_outline = '#000000'
        local p_thickness = 2
        
        if p.kicking then
            p_outline = '#ffffff'
            p_thickness = 3
        end
        
        -- Dibuja usando el color del equipo (p.color) en lugar de rojo fijo
        alexgames.draw_circle(p.color, p_outline, p.y, p.x, p.radius, p_thickness)
    end
    
    -- Dibujar la pelota por encima de los jugadores
    alexgames.draw_circle('#ffffff', '#000000', state.ball.y, state.ball.x, state.ball.radius, 2)
    
    alexgames.draw_refresh()
end

return draw