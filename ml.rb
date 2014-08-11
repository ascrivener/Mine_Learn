class Board
	attr_accessor :board, :height, :width
	def initialize(height=10, width=10)		
		@height = height
		@width = width
		@board = Array.new(height) {Array.new(width,nil)}

		(0..(@height-1)).each do |i|
			(0..(@width-1)).each do |j|
				@board[i][j] = Tile.new([true,false].sample)
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
			true
		end
	end
	def flip(i,j)
		if (@board[i][j].has_bomb)
			puts "BOOM"
			"BOMB"
		elsif (@board[i][j].flipped)
			puts "already flipped!"
			false
		else
			@board[i][j].flipped = true
			true
		end
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
	attr_accessor :flipped, :marked, :has_bomb
	def initialize(bomb)
		@flipped = false
		@marked = false
		@has_bomb = bomb
	end
	def out(final=false)
		if @flipped
			"O"
		elsif @marked
			"?"
		elsif final && @has_bomb
			"B"
		else
			"X"
		end
	end
end

board = Board.new(10,10)

while(true)
	if (board.flip((0..board.height-1).to_a.sample,(0..board.width-1).to_a.sample) == "BOMB")
		board.out(true)
		break
	end
	board.out
end