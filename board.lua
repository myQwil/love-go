local board = {}

local boardwid = 550
local xblack ,xwhite = 150 ,350
local tile ,stnrad ,blen ,tlen ,offx ,offy ,ox ,oy
local grid ,dots = {} ,{}
local chars = { 'A' ,'B' ,'C' ,'D' ,'E' ,'F' ,'G' ,'H' ,'J'
               ,'K' ,'L' ,'M' ,'N' ,'O' ,'P' ,'Q' ,'R' ,'S' ,'T'
               ,A=1 ,B=2 ,C=3 ,D=4 ,E=5 ,F=6 ,G=7 ,H=8 ,J=9
               ,K=10,L=11,M=12,N=13,O=14,P=15,Q=16,R=17,S=18,T=19 }

-- Colors
local clrwd  = {0.86 ,0.7  ,0.36 } -- wood
local clrln  = {0    ,0    ,0    } -- lines
local clrtx  = {1    ,1    ,1    } -- text
local clrhl  = {0.25 ,1    ,1    } -- highlight
local clrstn =                     -- stones
{	 [black]  = {r=0  ,g=0 ,b=0  }
	,[white]  = {r=1  ,g=1 ,b=1  }   }

function board.init()
	local b = boardsize
	for k in next,grid do rawset(grid ,k ,nil) end
	for k in next,dots do rawset(dots ,k ,nil) end
	tile = math.floor(boardwid / (b + 2))
	stnrad = tile / 2.1
	blen = tile * (b + 1)
	tlen = tile * (b - 1)

	offx = 25
	offy = 50
	ox = offx + tile
	oy = offy + tile

	for i = 1,b do
		local g = {}
		local x ,y = offx+tile*i ,offy+tile*i
		g.coords =
		{	 {text=b-i+1    ,x=offx+4       ,y=y-8}
			,{text=b-i+1    ,x=offx+blen-22 ,y=y-8}
			,{text=chars[i] ,x=x-5          ,y=offy+8}
			,{text=chars[i] ,x=x-5          ,y=offy+blen-24}   }
		g.lines =
		{	 {ox ,y  ,ox+tlen ,y}
			,{x  ,oy ,x       ,oy+tlen}   }
		grid[i] = g end

	if b <= 2 then
		return end

	-- Handicap spots
	local l ,r
	if     b == 5  then
		l = 2 ; r = 4
	elseif b  < 12 then
		l = 3 ; r = b-2
	elseif b >= 12 then
		l = 4 ; r = b-3 end
	dots[1] = {x=offx+tile*l ,y=offy+tile*l}
	dots[2] = {x=offx+tile*r ,y=offy+tile*l}
	dots[3] = {x=offx+tile*r ,y=offy+tile*r}
	dots[4] = {x=offx+tile*l ,y=offy+tile*r}
	if b % 2 == 1 then
		local c = math.ceil(b/2)
		dots[5] = {x=offx+tile*c ,y=offy+tile*c}
		if b > 12 then
			dots[6] = {x=offx+tile*c ,y=offy+tile*l}
			dots[7] = {x=offx+tile*r ,y=offy+tile*c}
			dots[8] = {x=offx+tile*c ,y=offy+tile*r}
			dots[9] = {x=offx+tile*l ,y=offy+tile*c} end end
end

function board.draw()
	-- Wood
	love.graphics.setColor(clrwd)
	love.graphics.rectangle('fill' ,offx ,offy ,blen ,blen)

	-- Grid
	love.graphics.setColor(clrln)
	for _,g in next,grid do
		for _,c in next,g.coords do love.graphics.print(c.text ,c.x ,c.y) end
		for _,l in next,g.lines  do love.graphics.line(l) end end
	for _,d in next,dots do love.graphics.circle('fill' ,d.x ,d.y ,5) end

	-- Stone hover
	if playing and not waiting then
		local x ,y = love.mouse.getPosition()
		if  x > ox-stnrad and x < ox+tlen+stnrad
		and y > oy-stnrad and y < oy+tlen+stnrad then
			x ,y = x - offx ,y - offy
			x = math.floor(x/tile + 0.5) * tile
			y = math.floor(y/tile + 0.5) * tile
			col = chars[x/tile]
			row = boardsize - y/tile + 1
			x ,y = x + offx ,y + offy
			stone.x = x
			stone.y = y

			curnt[stone.color] = col..row
			local clr = clrstn[stone.color]
			love.graphics.setColor(clr.r ,clr.g ,clr.b ,0.5)
			love.graphics.circle('fill' ,x ,y ,stnrad)
			love.graphics.circle('line' ,x ,y ,stnrad)
		else
			row = nil
			rawset(curnt ,black ,nil)
			rawset(curnt ,white ,nil) end end

	-- Move labels
	love.graphics.setColor(1 ,1 ,1)
	love.graphics.print('Black' ,xblack ,5)
	love.graphics.print('White' ,xwhite ,5)
	love.graphics.setColor(stone.color == black and clrtx or clrhl)
	love.graphics.print(curnt[black] or prev[black] ,xblack ,25)
	love.graphics.setColor(stone.color == white and clrtx or clrhl)
	love.graphics.print(curnt[white] or prev[white] ,xwhite ,25)
	love.graphics.setColor(1 ,1 ,1)
	love.graphics.print(response ,233 ,25)

	-- Stones placed
	for _,stn in next,stones do
		local clr = clrstn[stn.color]
		love.graphics.setColor(clr.r ,clr.g ,clr.b)
		love.graphics.circle('fill' ,stn.x ,stn.y ,stnrad)
		love.graphics.circle('line' ,stn.x ,stn.y ,stnrad) end
end

function board.mousepressed(x ,y ,btn)
	if not row or stones[col..row] then
		return false end

	stones[col..row] = stone
	go:write('play '..str[stone.color]..' '..col..row..'\n')
	waiting = game.human
	return true
end

function board.populate(s ,b)
	for mv in string.gmatch(s ,'%S+') do
		local c = mv:sub(1 ,1)
		local r = mv:sub(2)
		stones[mv] =
		{	 color = b
			,x = offx+tile*chars[c]
			,y = offy+tile*(boardsize-r+1)   } end
end

board.init()
return board
