class Board
	attr_accessor :board, :height, :width, :num_bombs
	def initialize(height=10, width=10, num_bombs=10)		
		@height = height
		@width = width
		@board = Array.new(height) {Array.new(width,nil)}
		@num_bombs = num_bombs

		(0..@height-1).each do |i|
			(0..@width-1).each do |j|
				@board[i][j] = Tile.new
			end
		end

		n = 0
		while (n < @num_bombs)
			i = (0..(@height-1)).to_a.sample
			j =	(0..(@width-1)).to_a.sample
			if (!@board[i][j].has_bomb)
				@board[i][j].has_bomb = true
				n=n+1
			end
		end

		dirs = [[-1,-1],[-1,0],[-1,1],[0,-1],[0,1],[1,-1],[1,0],[1,1]]

		(0..@height-1).each do |i|
			(0..@width-1).each do |j|
				if @board[i][j].has_bomb
					@board[i][j].number = -1
				else
					count = 0
					dirs.each do |d_i,d_j|
						t_i = i+d_i
						t_j = j+d_j
						if (inbounds(t_i,t_j))
							if (@board[t_i][t_j].has_bomb)
								count = count+1
							end
						end
					end
					@board[i][j].number = count
				end
			end
		end
	end
	def mark(i,j)
		if (@board[i][j].flipped)
			puts "already flipped!"
		elsif (@board[i][j].marked)
			@board[i][j].marked = false
		else
			@board[i][j].marked = true
		end
	end
	def flip(i,j)
		if (@board[i][j].has_bomb)
			puts "BOOM"
		elsif (@board[i][j].flipped)
			puts "already flipped!"
		else
			@board[i][j].flipped = true
			if (@board[i][j].number == 0)
				clear(i,j)
			else
				#update(i,j)
			end
		end
	end
	def clear(i,j)
		dirs = [[-1,-1],[-1,0],[-1,1],[0,-1],[0,1],[1,-1],[1,0],[1,1]]

		dirs.each do |d_i,d_j|
			t_i = i+d_i
			t_j = j+d_j

			if (inbounds(t_i,t_j) && !@board[t_i][t_j].flipped)
				flip(t_i,t_j)
				if (@board[t_i][t_j].number == 0)
					clear(t_i,t_j)
				end
			end
		end
	end
	def inbounds(i,j)
		return (i >=0 && i < @height && j >= 0 && j < @width)
	end
	def out(final=false)
		(0..(@height-1)).each do |i|
			(0..(@width-1)).each do |j|
				print "#{@board[i][j].out(final)} "
			end
			puts
		end
		puts
	end
end

class Tile
	attr_accessor :flipped, :marked, :has_bomb, :number
	def initialize(has_bomb=false)
		@flipped = false
		@marked = false
		@has_bomb = has_bomb
	end
	def out(final=false)
		if @flipped
			@number
		elsif @marked
			"?"
		elsif final && @has_bomb
			"B"
		else
			"X"
		end
	end
end

class Game
	def play
		m = Board.new(10,10,10)

		while(true)
			i = gets.chomp.to_i
			j = gets.chomp.to_i
			m.flip(i,j)
			if (m.board[i][j].has_bomb)
				m.out(true)
				break
			end


			m.out
		end
	end
end

Game.new.play