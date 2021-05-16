local menu = {}

local btns ,lbls
local xmenu = 560
local yd ,yn = 50  ,210
local yb ,yw = 390 ,480

local function reset_moves()
	btns.undo.on = false
	btns.redo.on = false
	prev[black]  ,prev[white] ,response = '' ,'' ,''
	captr[black] ,captr[white] = 0 ,0
end

local function reset_board()
	reset_moves()
	set_playing(false)
	go:write('boardsize '..boardsize..'\n')
	go:write('fixed_handicap '..handicap..'\n')
	waiting = game.board
end


-- Dragger Callbacks

local function boardsize_change(i)
	boardsize = i
	reset_board()
end

local function handicap_change(i)
	handicap = i == 1 and 0 or i
	reset_board()
end

local function komi_change(i)
	komi = i
	go:write('komi '..komi..'\n')
	waiting = game.komi
end

local function black_level(i) level[black] = i end
local function white_level(i) level[white] = i end


-- Button Callbacks

local function newgame()
	walking = false
	reset_moves()
	set_playing(true)
	go:write('clear_board\n')
	go:write('boardsize '..boardsize..'\n')
	go:write('fixed_handicap '..handicap..'\n')
	go:write('komi '..komi..'\n')
	waiting = game.new
end

local function undo()
	walking = true
	set_playing(true)
	stone.color = history[step].color
	prev[stone.color] = (step-2 > 0) and history[step-2].m or ''
	if history[step].final then
		prev[not stone.color] = (step-1 > 0) and history[step-1].m or '' end

	step = step - 1
	btns.undo.on = (step > 0)
	btns.redo.on = true
	go:write('undo\n')
	waiting = game.history
end

local function redo()
	walking = true
	step = step + 1
	btns.undo.on = true
	btns.redo.on = (step < last)

	local move = history[step]
	prev[move.color] = move.m
	stone.color = not move.color
	if move.final then
		if move.resign then
			prev[not move.color] = 'resign' end
		set_playing(false) end
	go:write('play '..str[move.color]..' '..move.m..'\n')
	waiting = game.history
end

local function pass()
	prev[stone.color] = 'PASS'
	go:write('play '..str[stone.color]..' pass\n')
	waiting = game.human
end

local function player_button(b ,btn)
	if play[b] then
		btn.text = 'Human'
		btn.tx   = 6
	else
		btn.text = 'Comp'
		btn.tx   = 12 end
end

local function black_play()
	play[black] = not play[black]
	player_button(black ,btns.blk)
end

local function white_play()
	play[white] = not play[white]
	player_button(white ,btns.wht)
end

function menu.init()
	gui.size = 30
	gui.sens = 15
	local optboard = {min=1 ,max=19 ,num=boardsize ,change=boardsize_change}
	local opthandi = {min=1 ,max=9  ,num=handicap  ,change=handicap_change}
	local optkomi  = {num=komi ,inc=0.5 ,change=komi_change}
	local optblvl  = {min=1 ,max=10 ,num=level[black]  ,change=black_level}
	local optwlvl  = {min=1 ,max=10 ,num=level[white]  ,change=white_level}
	drgs =
	{	 gui.drag(xmenu+100 ,yd-5  ,optboard)
		,gui.drag(xmenu+100 ,yd+45 ,opthandi)
		,gui.drag(xmenu+100 ,yd+95 ,optkomi)
		,gui.drag(xmenu+190 ,yb ,optblvl)
		,gui.drag(xmenu+190 ,yw ,optwlvl)   }

	local optnew   = {text='New Game' ,tx=46 ,w=180 ,click=newgame ,on=true}
	local optundo  = {text='Undo' ,click=undo}
	local optredo  = {text='Redo' ,click=redo}
	local optpass  = {text='Pass'     ,tx=70 ,w=180 ,click=pass}
	local optblack = {w=70 ,click=black_play ,on=true}
	local optwhite = {w=70 ,click=white_play ,on=true}
	btns =
	{	 new  = gui.button(xmenu     ,yn     ,optnew)
		,undo = gui.button(xmenu     ,yn+50  ,optundo)
		,redo = gui.button(xmenu+110 ,yn+50  ,optredo)
		,pass = gui.button(xmenu     ,yn+100 ,optpass)
		,blk  = gui.button(xmenu+60  ,yb ,optblack)
		,wht  = gui.button(xmenu+60  ,yw ,optwhite)   }
	player_button(black ,btns.blk)
	player_button(white ,btns.wht)
end

function menu.update()
	for i = 1,#drgs do
		drgs[i]:update(love.mouse.getPosition()) end
end

function menu.draw()
	love.graphics.setColor(1 ,1 ,1)
	love.graphics.printf('Board Size' ,xmenu     ,yd     ,90 ,'right')
	love.graphics.printf('Handicap'   ,xmenu     ,yd+50  ,90 ,'right')
	love.graphics.printf('Komi'       ,xmenu     ,yd+100 ,90 ,'right')
	love.graphics.print(boardsize     ,xmenu+140 ,yd)
	love.graphics.print(handicap      ,xmenu+140 ,yd+50)
	love.graphics.print(komi          ,xmenu+140 ,yd+100)
	love.graphics.print(step          ,xmenu+74  ,yn+55)

	love.graphics.print('Black:'      ,xmenu     ,yb+5)
	love.graphics.print('lvl'         ,xmenu+140 ,yb+5)
	love.graphics.print(level[black]  ,xmenu+160 ,yb+5)
	love.graphics.print('Captures:'   ,xmenu     ,yb+35)
	love.graphics.print(captr[black]  ,xmenu+90  ,yb+35)

	love.graphics.print('White:'      ,xmenu     ,yw+5)
	love.graphics.print('lvl'         ,xmenu+140 ,yw+5)
	love.graphics.print(level[white]  ,xmenu+160 ,yw+5)
	love.graphics.print('Captures:'   ,xmenu     ,yw+35)
	love.graphics.print(captr[white]  ,xmenu+90  ,yw+35)

	for _,b in next,btns do b:draw() end
	for i = 1,#drgs do drgs[i]:draw() end
end

function menu.mousepressed(x ,y)
	for _,b in next,btns do b:mousepressed(x ,y) end
end

function menu.mousereleased(x ,y)
	for _,b in next,btns do b:mousereleased(x ,y) end
end

menu.init()
menu.btns = btns
return menu
