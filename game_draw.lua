local alexgames = require("alexgames")
local draw = {}

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
    alexgames.draw_line('#ffffff', 4, 180, 750, 300, 750)   -- Arco derecho
end

function draw.render(state)
    alexgames.draw_clear()
    
    -- Dibuja la cancha estática
    draw_field()
    
    -- Jugador (Rojo)
    alexgames.draw_circle('#ff0000', '#000000', math.floor(state.player.y), math.floor(state.player.x), state.player.radius)
    
    -- Pelota (Blanca)
    alexgames.draw_circle('#ffffff', '#000000', math.floor(state.ball.y), math.floor(state.ball.x), state.ball.radius)
    
    alexgames.draw_refresh()
end

return draw