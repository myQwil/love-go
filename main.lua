-- Path to GNU Go
local mswin = (love.system.getOS() == 'Windows')
local engine = mswin and '"C:/Program Files/gnugo/gnugo.exe"' or 'gnugo'
engine = engine..' --mode gtp'

black ,white = true ,false

-- Options
boardsize = 9
handicap  = 4
komi      = 4.5
level = -- computer strength
{	 [black] = 10
	,[white] = 1   }
play  = -- which players are human
{	 [black] = true
	,[white] = false   }

goversion = ''
version   = '0.1.0'
prev  = {[black] = ''      ,[white] = ''}
curnt = {[black] = ''      ,[white] = ''}
captr = {[black] = '0'     ,[white] = '0'}
str   = {[black] = 'black' ,[white] = 'white'}
stone ,stones ,history = {} ,{} ,{}
playing ,walking = false ,false
step ,last = 0 ,0
response = ''

local pos = 0
local gtp

function enough_args(n ,i)
	if n < i then
		return false end
	assert(n == i) -- there shouldn't be excess args
	pos = gtp:seek('end')
	return true
end

function set_playing(b)
	playing = b
	menu.btns.pass.on = b
	row = b and row or nil
end

function update()
	go:write('list_stones black\nlist_stones white\n'
          ..'captures black\ncaptures white\n')
	waiting = game.update
end

function genmove()
	go:write('level '..level[stone.color]..'\n')
	go:write('genmove '..str[stone.color]..'\n')
	response = 'thinking...'
	waiting = game.computer
end

function final_score()
	go:write('final_score\n')
	response = 'tallying...'
	waiting = game.done
end

function love.load()
	gui = require('gui')
	game = require('game')
	menu = require('menu')
	board = require('board')

	local cmd = 'gtp.txt'
	love.filesystem.write(cmd ,'')
	cmd = love.filesystem.getSaveDirectory()..'/'..cmd
	gtp = io.open(cmd)
	cmd = engine..' > "'..cmd..'"'
	if mswin then
		cmd = '"'..cmd..'"' end
	go = assert(io.popen(cmd ,'w'))
	go:setvbuf('no')
	go:write('name\n')
	go:write('version\n')
	go:write('boardsize '..boardsize..'\n')
	go:write('fixed_handicap '..handicap..'\n')
	love.graphics.setBackgroundColor(0.25 ,0.25 ,0.25)
	waiting = game.init
end

function love.update()
	if waiting then
		if gtp:seek('end') > pos then
			gtp:seek('set' ,pos)
			local t = {}
			for m in string.gmatch(gtp:read('*a') ,'[=?] ([^\n]*)\n*') do
				table.insert(t ,m) end
			waiting(t) end
	else menu.update() end
end

local bigfont = love.graphics.newFont(16)
local smlfont = love.graphics.newFont(13)
local width ,height  = love.graphics.getDimensions()

function love.draw()
	-- Version labels
	love.graphics.setFont(smlfont)
	love.graphics.setColor(1 ,1 ,1)
	love.graphics.print(goversion ,10       ,height-20)
	love.graphics.print(version   ,width-50 ,height-20)

	love.graphics.setFont(bigfont)
	board.draw()
	menu.draw()
end

function love.mousepressed(x ,y)
	if waiting then
		walking = true
	elseif
	not board.mousepressed(x ,y)
	then menu.mousepressed(x ,y) end
end

function love.mousereleased(x ,y)
	menu.mousereleased(x ,y)
end

function love.quit()
	go:close()
	gtp:close()
end
