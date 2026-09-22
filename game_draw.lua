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

local function draw_hud(state)
    -- Recordatorio de parámetros para draw_rect: color, y1, x1, y2, x2
    -- Asumimos que draw_text es: texto, color, y, x, tamaño_fuente
    
    -- Dibujar fondo negro semitransparente para el reloj (opcional, ayuda a leerlo mejor)
    alexgames.draw_rect('rgba(0,0,0,0.5)', 0, 0, 45, 800) 
    
    -- 1. MARCADOR (Esquina superior izquierda)
    -- Cuadrado Rojo
    alexgames.draw_rect('#ff0000', 15, 10, 35, 30) 
    -- Puntos Rojo
    alexgames.draw_text(tostring(state.score.red), '#ffffff', 35, 50, 20) 
    
    -- Guión separador
    alexgames.draw_text("-", '#ffffff', 35, 70, 20)
    
    -- Cuadrado Azul
    alexgames.draw_rect('#4d4dff', 15, 110, 35, 130) 
    -- Puntos Azul
    alexgames.draw_text(tostring(state.score.blue), '#ffffff', 35, 90, 20)

    -- 2. CRONÓMETRO (Centro superior)
    -- Calcular minutos y segundos
    local minutos = math.floor(state.match_time / 60)
    local segundos = math.floor(state.match_time % 60)
    -- Formatear a "00:00"
    local tiempo_str = string.format("%02d:%02d", minutos, segundos)
    
    -- Dibujar el texto del tiempo en el centro (x = 375 aproxima el centro considerando el ancho del texto)
    alexgames.draw_text(tiempo_str, '#ffffff', 35, 400, 24)
end

function draw.render(state)
    alexgames.draw_clear()
    
    draw_field()
    
    -- Recorrer y dibujar a todos los jugadores
    for _, p in ipairs(state.players) do
        local p_outline = '#000000'
        local p_thickness = 2
        
        if p.kicking then
            p_outline = '#ffffff'
            p_thickness = 3
        end
        
        alexgames.draw_circle(p.color, p_outline, p.y, p.x, p.radius, p_thickness)
    end
    
    -- Dibujar la pelota
    alexgames.draw_circle('#ffffff', '#000000', state.ball.y, state.ball.x, state.ball.radius, 2)
    
    -- Dibujar la interfaz por encima de todo
    draw_hud(state)
    
    alexgames.draw_refresh()
end

return draw