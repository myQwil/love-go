local gui =
{	 hori = false
	,size = 25
	,sens = 10
	,inc  = 1
	,num  = 0
	,text = ''
	,tx   = 15
	,ty   = 5
	,w    = 70
	,h    = 30
	,on = true   }

local focus
local lin = 1.5
local ffi = require('ffi')
local sdl = ffi.os == "Windows" and ffi.load("SDL2") or ffi.C
local fx ,fy = ffi.new("int[1]" ,0) ,ffi.new("int[1]" ,0)
ffi.cdef[[
	uint32_t SDL_GetGlobalMouseState(int *x ,int *y);
]]

local function clamp(x ,min ,max)
	return (min and x < min and min) or (max and x > max and max) or x
end

local arwSel = {0.5 ,0.75 ,0.75}
local arwOn =
{	 fill = {0.25 ,0.25 ,0.25 }
	,line = {0.5  ,0.5  ,0.5  }   }
local arwOff  =
{	 fill = {0.1  ,0.1  ,0.1  }
	,line = {0.25 ,0.25 ,0.25 }   }

local btnOn  =
{	 fill = {0.1  ,0.1  ,0.1  }
	,line = {0.5  ,0.5  ,0.5  }
	,text = {1    ,1    ,1    }   }
local btnOff =
{	 fill = {0.3  ,0.3  ,0.3  }
	,line = {0.5  ,0.5  ,0.5  }
	,text = {0.7  ,0.7  ,0.7  }   }
local btnPress =
{	 fill = {0.1  ,0.1  ,0.1  }
	,line = {0.5  ,0.75 ,0.75 }
	,text = {0.85 ,1    ,1    }   }

local function drag_draw(d)
	love.graphics.setLineWidth(lin)
	love.graphics.setColor(0.1 ,0.1 ,0.1)
	love.graphics.rectangle('fill' ,d.x ,d.y ,d.size ,d.size ,5)
	local arwinc = (not d.max or d.num < d.max) and arwOn or arwOff
	local arwdec = (not d.min or d.num > d.min) and arwOn or arwOff

	love.graphics.setColor(arwinc.fill)
	love.graphics.polygon('fill' ,d.triangles[1])
	love.graphics.setColor(arwinc.line)
	love.graphics.polygon('line' ,d.triangles[1])

	love.graphics.setColor(arwdec.fill)
	love.graphics.polygon('fill' ,d.triangles[2])
	love.graphics.setColor(arwdec.line)
	love.graphics.polygon('line' ,d.triangles[2])

	love.graphics.setColor(0.5 ,0.5 ,0.5)
	love.graphics.line(d.triangles[3])
	love.graphics.setLineWidth(1)
	love.graphics.setColor(focus == d and arwSel or arwOn.line)
	love.graphics.rectangle('line' ,d.x ,d.y ,d.size ,d.size ,5)
end

local function drag_update(d ,x ,y)
	if love.mouse.isDown(1) then
		sdl.SDL_GetGlobalMouseState(fx ,fy)
		local gx ,gy = fx[0] ,fy[0]
		if     focus == d then
			local c = d.hori and gx - d.start or d.start - gy
			c = clamp(d.prev + math.floor(c / d.sens) * d.inc ,d.min ,d.max)
			if d.change and d.num ~= c then
				d.change(c)
				d.num = c end
		elseif focus == nil
		and x >= d.x and x < d.xx
		and y >= d.y and y < d.yy then
			d.prev = d.num
			d.start = d.hori and gx - d.sens/2 or gy + d.sens/2
			focus = d end
	else focus = nil end
end

function gui.drag(x ,y ,opt)
	if type(opt) ~= 'table' then opt = gui end
	local drag =
	{	 x = x
		,y = y
		,hori = opt.hori or gui.hori
		,sens = opt.sens or gui.sens
		,size = opt.size or gui.size
		,inc  = opt.inc  or gui.inc
		,num  = opt.num  or gui.num
		,min  = opt.min
		,max  = opt.max
		,change = opt.change
		,draw   = drag_draw
		,update = drag_update   }

	local xx  = x + drag.size
	local yy  = y + drag.size
	local midx = x + ((xx - x) / 2)
	local midy = y + ((yy - y) / 2)
	local bas = math.floor(drag.size / 3)
	if drag.hori then
		drag.triangles =
		{	 {x+bas  ,y+lin   ,x+lin  ,midy    ,x+bas  ,yy-lin }
			,{xx-bas ,y+lin   ,xx-lin ,midy    ,xx-bas ,yy-lin }
			,{midx   ,y+lin   ,midx   ,yy-lin}   }
	else
		drag.triangles =
		{	 {x+lin  ,y+bas   ,midx   ,y+lin   ,xx-lin ,y+bas  }
			,{x+lin  ,yy-bas  ,midx   ,yy-lin  ,xx-lin ,yy-bas }
			,{x+lin  ,midy    ,xx-lin ,midy}   } end
	drag.xx = xx
	drag.yy = yy

	return drag
end

local function button_draw(b)
	local color = (b == focus and btnPress) or (b.on and btnOn) or btnOff
	love.graphics.setColor(color.fill)
	love.graphics.rectangle('fill' ,b.x ,b.y ,b.w ,b.h ,7)
	love.graphics.setColor(color.line)
	love.graphics.rectangle('line' ,b.x ,b.y ,b.w ,b.h ,7)
	love.graphics.setColor(color.text)
	love.graphics.print(b.text ,b.x+b.tx ,b.y+b.ty)
end

local function button_mousepressed(b ,x ,y)
	if b.on
	and x >= b.x and x < b.xx
	and y >= b.y and y < b.yy then
		focus = b
		return true end
end

local function button_mousereleased(b ,x ,y)
	if focus == b
	and x >= b.x and x < b.xx
	and y >= b.y and y < b.yy then
		b.click()
		focus = nil
		return true end
end

function gui.button(x ,y ,opt)
	if type(opt) ~= 'table' then opt = gui end
	local btn =
	{	 x = x
		,y = y
		,w = opt.w or gui.w
		,h = opt.h or gui.h
		,text = opt.text or gui.text
		,tx   = opt.tx   or gui.tx
		,ty   = opt.ty   or gui.ty
		,click = opt.click
		,draw  = button_draw
		,mousepressed  = button_mousepressed
		,mousereleased = button_mousereleased   }
	btn.xx = x + btn.w
	btn.yy = y + btn.h
	if opt.on ~= nil then
	     btn.on = opt.on
	else btn.on = gui.on end
	return btn
end

return gui
