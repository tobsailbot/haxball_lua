local alexgames = require("alexgames")
local draw = {}

local function draw_field()
    alexgames.draw_rect('#327134', 0, 0, 480, 800)
    alexgames.draw_rect('#327134', 4, 4, 476, 796)
    alexgames.draw_rect('#4CAF50', 60, 50, 420, 750)
    alexgames.draw_circle('#4CAF50', '#c7c7c7', 240, 400, 70, 4)
    alexgames.draw_line('#c7c7c7', 4, 60, 400, 420, 400)
    alexgames.draw_line('#ffffff', 4, 180, 50, 300, 50)
    alexgames.draw_line('#ffffff', 4, 180, 750, 300, 750)
end

function draw.render(state)
    alexgames.draw_clear()
    
    draw_field()
    
    -- Configurar borde del jugador según el estado de pateo
    local p_outline = '#000000'
    local p_thickness = 2
    if state.player.kicking then
        p_outline = '#ffffff'
        p_thickness = 3
    end
    
    alexgames.draw_circle('#ff0000', p_outline, state.player.y, state.player.x, state.player.radius, p_thickness)
    alexgames.draw_circle('#ffffff', '#000000', state.ball.y, state.ball.x, state.ball.radius, 2)
    
    alexgames.draw_refresh()
end

return draw