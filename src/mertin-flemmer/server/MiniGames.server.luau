--!strict
-- Mini-Games System for Mertin-Flemmer
-- FULLY PLAYABLE Checkers with AI opponent and rewards
-- Mazes scattered throughout the world

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))

-- Create remotes
local MiniGameRemote = Instance.new("RemoteEvent")
MiniGameRemote.Name = "MiniGame"
MiniGameRemote.Parent = ReplicatedStorage

-- ==========================================
-- CHECKERS GAME - FULL IMPLEMENTATION
-- ==========================================

-- Board values: 0 = empty, 1 = red, 2 = red king, -1 = black, -2 = black king
-- Player is always RED, AI is always BLACK

type CheckersGame = {
	board: { { number } },
	currentTurn: string, -- "red" or "black"
	player: Player?,
	npcName: string?,
	gameOver: boolean,
	winner: string?,
	selectedPiece: { row: number, col: number }?,
	validMoves: { { fromRow: number, fromCol: number, toRow: number, toCol: number, isJump: boolean, jumpedRow: number?, jumpedCol: number? } },
	reward: number,
	boardModel: Model?,
}

local activeGames: { [Player]: CheckersGame } = {}
local boardModels: { [Model]: { npcName: string?, reward: number } } = {}

-- Initialize empty board state
local function createEmptyBoard(): { { number } }
	local board = {}
	for row = 1, 8 do
		board[row] = {}
		for col = 1, 8 do
			board[row][col] = 0
		end
	end
	return board
end

-- Initialize starting position
local function initializeBoard(): { { number } }
	local board = createEmptyBoard()

	for row = 1, 8 do
		for col = 1, 8 do
			-- Only dark squares (where row+col is odd)
			if (row + col) % 2 == 1 then
				if row <= 3 then
					board[row][col] = -1 -- Black (AI) on top
				elseif row >= 6 then
					board[row][col] = 1 -- Red (player) on bottom
				end
			end
		end
	end

	return board
end

-- Check if position is on board
local function isOnBoard(row: number, col: number): boolean
	return row >= 1 and row <= 8 and col >= 1 and col <= 8
end

-- Get all valid moves for a piece
local function getValidMoves(board: { { number } }, row: number, col: number, isRed: boolean): { { toRow: number, toCol: number, isJump: boolean, jumpedRow: number?, jumpedCol: number? } }
	local moves = {}
	local piece = board[row][col]
	if piece == 0 then return moves end

	local isKing = math.abs(piece) == 2

	-- Direction based on color (red moves up/negative, black moves down/positive)
	local directions = {}
	if isRed or isKing then
		table.insert(directions, -1) -- Move up
	end
	if not isRed or isKing then
		table.insert(directions, 1) -- Move down
	end

	-- Check each diagonal direction
	for _, rowDir in directions do
		for _, colDir in { -1, 1 } do
			local newRow = row + rowDir
			local newCol = col + colDir

			if isOnBoard(newRow, newCol) then
				local targetPiece = board[newRow][newCol]

				if targetPiece == 0 then
					-- Empty square - regular move
					table.insert(moves, {
						toRow = newRow,
						toCol = newCol,
						isJump = false,
					})
				elseif (isRed and targetPiece < 0) or (not isRed and targetPiece > 0) then
					-- Enemy piece - check for jump
					local jumpRow = newRow + rowDir
					local jumpCol = newCol + colDir

					if isOnBoard(jumpRow, jumpCol) and board[jumpRow][jumpCol] == 0 then
						table.insert(moves, {
							toRow = jumpRow,
							toCol = jumpCol,
							isJump = true,
							jumpedRow = newRow,
							jumpedCol = newCol,
						})
					end
				end
			end
		end
	end

	return moves
end

-- Check if there are any jump moves available (must take if available)
local function hasJumpMoves(board: { { number } }, isRed: boolean): boolean
	local pieceValues = isRed and { 1, 2 } or { -1, -2 }

	for row = 1, 8 do
		for col = 1, 8 do
			local piece = board[row][col]
			for _, val in pieceValues do
				if piece == val then
					local moves = getValidMoves(board, row, col, isRed)
					for _, move in moves do
						if move.isJump then
							return true
						end
					end
				end
			end
		end
	end

	return false
end

-- Get all valid moves for a player
local function getAllValidMoves(board: { { number } }, isRed: boolean): { { fromRow: number, fromCol: number, toRow: number, toCol: number, isJump: boolean, jumpedRow: number?, jumpedCol: number? } }
	local allMoves = {}
	local pieceValues = isRed and { 1, 2 } or { -1, -2 }
	local mustJump = hasJumpMoves(board, isRed)

	for row = 1, 8 do
		for col = 1, 8 do
			local piece = board[row][col]
			for _, val in pieceValues do
				if piece == val then
					local moves = getValidMoves(board, row, col, isRed)
					for _, move in moves do
						-- If must jump, only include jump moves
						if not mustJump or move.isJump then
							table.insert(allMoves, {
								fromRow = row,
								fromCol = col,
								toRow = move.toRow,
								toCol = move.toCol,
								isJump = move.isJump,
								jumpedRow = move.jumpedRow,
								jumpedCol = move.jumpedCol,
							})
						end
					end
				end
			end
		end
	end

	return allMoves
end

-- Execute a move on the board
local function executeMove(board: { { number } }, fromRow: number, fromCol: number, toRow: number, toCol: number, jumpedRow: number?, jumpedCol: number?): { { number } }
	local newBoard = {}
	for row = 1, 8 do
		newBoard[row] = {}
		for col = 1, 8 do
			newBoard[row][col] = board[row][col]
		end
	end

	local piece = newBoard[fromRow][fromCol]
	newBoard[fromRow][fromCol] = 0
	newBoard[toRow][toCol] = piece

	-- Remove jumped piece
	if jumpedRow and jumpedCol then
		newBoard[jumpedRow][jumpedCol] = 0
	end

	-- King promotion
	if piece == 1 and toRow == 1 then
		newBoard[toRow][toCol] = 2 -- Red king
	elseif piece == -1 and toRow == 8 then
		newBoard[toRow][toCol] = -2 -- Black king
	end

	return newBoard
end

-- Count pieces
local function countPieces(board: { { number } }): (number, number)
	local redCount = 0
	local blackCount = 0

	for row = 1, 8 do
		for col = 1, 8 do
			local piece = board[row][col]
			if piece > 0 then
				redCount += 1
			elseif piece < 0 then
				blackCount += 1
			end
		end
	end

	return redCount, blackCount
end

-- Check for winner
local function checkWinner(board: { { number } }): string?
	local redCount, blackCount = countPieces(board)

	if redCount == 0 then return "black" end
	if blackCount == 0 then return "red" end

	-- Check if current player has any moves
	local redMoves = getAllValidMoves(board, true)
	local blackMoves = getAllValidMoves(board, false)

	if #redMoves == 0 then return "black" end
	if #blackMoves == 0 then return "red" end

	return nil
end

-- AI Move Selection (simple but competent)
local function selectAIMove(board: { { number } }): { fromRow: number, fromCol: number, toRow: number, toCol: number, isJump: boolean, jumpedRow: number?, jumpedCol: number? }?
	local moves = getAllValidMoves(board, false) -- Black = AI

	if #moves == 0 then return nil end

	-- Prioritize jumps
	local jumpMoves = {}
	for _, move in moves do
		if move.isJump then
			table.insert(jumpMoves, move)
		end
	end

	if #jumpMoves > 0 then
		-- Pick a random jump (could be smarter)
		return jumpMoves[math.random(#jumpMoves)]
	end

	-- Score each move
	local bestMove = moves[1]
	local bestScore = -1000

	for _, move in moves do
		local score = 0

		-- Prefer moving toward promotion
		if board[move.fromRow][move.fromCol] == -1 then -- Regular piece
			score += move.toRow -- Closer to row 8 is better for black
		end

		-- Prefer edges (safer)
		if move.toCol == 1 or move.toCol == 8 then
			score += 2
		end

		-- Avoid center in early game
		if move.toRow >= 3 and move.toRow <= 6 and move.toCol >= 3 and move.toCol <= 6 then
			score -= 1
		end

		-- Random factor for variety
		score += math.random() * 2

		if score > bestScore then
			bestScore = score
			bestMove = move
		end
	end

	return bestMove
end

-- Render the board visually
local function renderBoard(game: CheckersGame)
	if not game.boardModel then return end

	local boardModel = game.boardModel

	-- Remove existing pieces
	for _, child in boardModel:GetChildren() do
		if string.find(child.Name, "Piece_") or string.find(child.Name, "Highlight_") then
			child:Destroy()
		end
	end

	local tablePart = boardModel:FindFirstChild("Table") :: BasePart?
	if not tablePart then return end

	local boardStart = tablePart.Position + Vector3.new(-3.5, 0.55, -3.5)
	local squareSize = 1

	-- Add pieces
	for row = 1, 8 do
		for col = 1, 8 do
			local pieceValue = game.board[row][col]
			if pieceValue ~= 0 then
				local piece = Instance.new("Part")
				piece.Name = "Piece_" .. row .. "_" .. col
				piece.Shape = Enum.PartType.Cylinder
				piece.Size = Vector3.new(0.3, 0.8, 0.8)
				piece.Position = boardStart + Vector3.new((col - 1) * squareSize + 0.5, 0.2, (row - 1) * squareSize + 0.5)
				piece.Orientation = Vector3.new(0, 0, 90)
				piece.Anchored = true
				piece.CanCollide = false

				if pieceValue > 0 then
					piece.Color = Color3.fromRGB(200, 50, 50) -- Red
				else
					piece.Color = Color3.fromRGB(30, 30, 30) -- Black
				end

				-- King crown
				if math.abs(pieceValue) == 2 then
					local crown = Instance.new("Part")
					crown.Name = "Crown"
					crown.Size = Vector3.new(0.4, 0.4, 0.4)
					crown.Position = piece.Position + Vector3.new(0, 0.3, 0)
					crown.Color = Color3.fromRGB(255, 215, 0)
					crown.Material = Enum.Material.Neon
					crown.Anchored = true
					crown.CanCollide = false
					crown.Parent = boardModel

					local weld = Instance.new("WeldConstraint")
					weld.Part0 = piece
					weld.Part1 = crown
					weld.Parent = piece
				end

				piece.Material = Enum.Material.SmoothPlastic
				piece.Parent = boardModel

				-- Add click detection for player pieces during their turn
				if pieceValue > 0 and game.currentTurn == "red" and not game.gameOver then
					local clickDetector = Instance.new("ClickDetector")
					clickDetector.MaxActivationDistance = 15
					clickDetector.Parent = piece

					clickDetector.MouseClick:Connect(function(clickPlayer)
						if clickPlayer == game.player then
							selectPiece(game, row, col)
						end
					end)
				end
			end
		end
	end

	-- Highlight selected piece and valid moves
	if game.selectedPiece and game.currentTurn == "red" then
		-- Highlight selected
		local selRow, selCol = game.selectedPiece.row, game.selectedPiece.col
		local highlight = Instance.new("Part")
		highlight.Name = "Highlight_Selected"
		highlight.Size = Vector3.new(0.9, 0.05, 0.9)
		highlight.Position = boardStart + Vector3.new((selCol - 1) * squareSize + 0.5, 0.03, (selRow - 1) * squareSize + 0.5)
		highlight.Color = Color3.fromRGB(255, 255, 0)
		highlight.Material = Enum.Material.Neon
		highlight.Anchored = true
		highlight.CanCollide = false
		highlight.Parent = boardModel

		-- Highlight valid moves
		for _, move in game.validMoves do
			if move.fromRow == selRow and move.fromCol == selCol then
				local moveHighlight = Instance.new("Part")
				moveHighlight.Name = "Highlight_Move_" .. move.toRow .. "_" .. move.toCol
				moveHighlight.Size = Vector3.new(0.7, 0.05, 0.7)
				moveHighlight.Position = boardStart + Vector3.new((move.toCol - 1) * squareSize + 0.5, 0.03, (move.toRow - 1) * squareSize + 0.5)
				moveHighlight.Color = move.isJump and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100)
				moveHighlight.Material = Enum.Material.Neon
				moveHighlight.Transparency = 0.3
				moveHighlight.Anchored = true
				moveHighlight.CanCollide = false
				moveHighlight.Parent = boardModel

				-- Click to move
				local moveClick = Instance.new("ClickDetector")
				moveClick.MaxActivationDistance = 15
				moveClick.Parent = moveHighlight

				moveClick.MouseClick:Connect(function(clickPlayer)
					if clickPlayer == game.player then
						makeMove(game, move)
					end
				end)
			end
		end
	end
end

-- Select a piece
function selectPiece(game: CheckersGame, row: number, col: number)
	if game.currentTurn ~= "red" or game.gameOver then return end
	if game.board[row][col] <= 0 then return end -- Not player's piece

	game.selectedPiece = { row = row, col = col }
	game.validMoves = getAllValidMoves(game.board, true)

	renderBoard(game)

	if game.player then
		MiniGameRemote:FireClient(game.player, "PIECE_SELECTED", {
			row = row,
			col = col,
		})
	end
end

-- Make a move
function makeMove(game: CheckersGame, move: { fromRow: number, fromCol: number, toRow: number, toCol: number, isJump: boolean, jumpedRow: number?, jumpedCol: number? })
	if game.gameOver then return end

	-- Execute the move
	game.board = executeMove(game.board, move.fromRow, move.fromCol, move.toRow, move.toCol, move.jumpedRow, move.jumpedCol)
	game.selectedPiece = nil

	-- Check for chain jumps
	if move.isJump then
		local chainMoves = getValidMoves(game.board, move.toRow, move.toCol, true)
		local hasChainJump = false
		for _, chainMove in chainMoves do
			if chainMove.isJump then
				hasChainJump = true
				break
			end
		end

		if hasChainJump then
			-- Must continue jumping
			game.selectedPiece = { row = move.toRow, col = move.toCol }
			game.validMoves = getAllValidMoves(game.board, true)
			renderBoard(game)

			if game.player then
				MiniGameRemote:FireClient(game.player, "MUST_JUMP", {
					row = move.toRow,
					col = move.toCol,
				})
			end
			return
		end
	end

	-- Check for winner
	local winner = checkWinner(game.board)
	if winner then
		endGame(game, winner)
		return
	end

	-- AI's turn
	game.currentTurn = "black"
	game.validMoves = {}
	renderBoard(game)

	if game.player then
		MiniGameRemote:FireClient(game.player, "AI_THINKING", {})
	end

	-- AI makes move after delay
	task.delay(1, function()
		aiTurn(game)
	end)
end

-- AI turn
function aiTurn(game: CheckersGame)
	if game.gameOver then return end

	-- Chain jump handling for AI
	local function executeAIChainJumps(fromRow: number, fromCol: number)
		local chainMoves = getValidMoves(game.board, fromRow, fromCol, false)
		for _, chainMove in chainMoves do
			if chainMove.isJump then
				game.board = executeMove(game.board, fromRow, fromCol, chainMove.toRow, chainMove.toCol, chainMove.jumpedRow, chainMove.jumpedCol)
				renderBoard(game)
				task.wait(0.5)

				-- Check for more jumps
				executeAIChainJumps(chainMove.toRow, chainMove.toCol)
				return
			end
		end
	end

	local aiMove = selectAIMove(game.board)

	if not aiMove then
		endGame(game, "red") -- AI can't move, player wins
		return
	end

	-- Execute AI move
	game.board = executeMove(game.board, aiMove.fromRow, aiMove.fromCol, aiMove.toRow, aiMove.toCol, aiMove.jumpedRow, aiMove.jumpedCol)
	renderBoard(game)

	-- Handle chain jumps
	if aiMove.isJump then
		task.wait(0.5)
		executeAIChainJumps(aiMove.toRow, aiMove.toCol)
	end

	-- Check for winner
	local winner = checkWinner(game.board)
	if winner then
		endGame(game, winner)
		return
	end

	-- Player's turn
	game.currentTurn = "red"
	game.validMoves = getAllValidMoves(game.board, true)
	renderBoard(game)

	if game.player then
		MiniGameRemote:FireClient(game.player, "YOUR_TURN", {})
	end
end

-- End the game
function endGame(game: CheckersGame, winner: string)
	game.gameOver = true
	game.winner = winner

	if game.player then
		if winner == "red" then
			-- Player won! Give reward
			local TradingRemote = ReplicatedStorage:FindFirstChild("Trading") :: RemoteEvent?
			if TradingRemote then
				TradingRemote:FireClient(game.player, "GOLD_EARNED", {
					amount = game.reward,
					source = "checkers",
				})
			end

			MiniGameRemote:FireClient(game.player, "GAME_WON", {
				reward = game.reward,
				opponent = game.npcName or "opponent",
			})
			print("[MiniGames]", game.player.Name, "won checkers! Reward:", game.reward, "gold")
		else
			MiniGameRemote:FireClient(game.player, "GAME_LOST", {
				opponent = game.npcName or "opponent",
			})
			print("[MiniGames]", game.player.Name, "lost checkers")
		end

		-- Clean up after delay
		task.delay(5, function()
			if game.player then
				activeGames[game.player] = nil
			end
		end)
	end
end

-- Create a checkers board in the world
local function createCheckersBoard(position: Vector3, npcName: string?, reward: number?): Model
	local board = Instance.new("Model")
	board.Name = "CheckersBoard" .. (npcName or "")

	local finalReward = reward or 75

	-- Table surface
	local tablePart = Instance.new("Part")
	tablePart.Name = "Table"
	tablePart.Size = Vector3.new(10, 1, 10)
	tablePart.Position = position
	tablePart.Color = Color3.fromRGB(80, 50, 30)
	tablePart.Material = Enum.Material.Wood
	tablePart.Anchored = true
	tablePart.Parent = board

	-- Board squares
	local boardSize = 8
	local squareSize = 1
	local boardStart = position + Vector3.new(-3.5, 0.55, -3.5)

	for row = 0, boardSize - 1 do
		for col = 0, boardSize - 1 do
			local square = Instance.new("Part")
			square.Name = "Square_" .. (row + 1) .. "_" .. (col + 1)
			square.Size = Vector3.new(squareSize, 0.1, squareSize)
			square.Position = boardStart + Vector3.new(col * squareSize + 0.5, 0, row * squareSize + 0.5)
			square.Anchored = true
			square.CanCollide = false

			if (row + col) % 2 == 0 then
				square.Color = Color3.fromRGB(240, 220, 180) -- Light
			else
				square.Color = Color3.fromRGB(100, 60, 30) -- Dark
			end

			square.Material = Enum.Material.SmoothPlastic
			square.Parent = board
		end
	end

	-- Chairs
	for i, offset in { Vector3.new(0, 0, 6), Vector3.new(0, 0, -6) } do
		local chair = Instance.new("Part")
		chair.Name = "Chair" .. i
		chair.Size = Vector3.new(3, 2, 2)
		chair.Position = position + offset + Vector3.new(0, 1, 0)
		chair.Color = Color3.fromRGB(60, 40, 25)
		chair.Material = Enum.Material.Wood
		chair.Anchored = true
		chair.Parent = board
	end

	-- Sign
	local signPart = Instance.new("Part")
	signPart.Name = "Sign"
	signPart.Size = Vector3.new(4, 3, 0.3)
	signPart.Position = position + Vector3.new(5.5, 3, 0)
	signPart.Color = Color3.fromRGB(100, 70, 40)
	signPart.Material = Enum.Material.Wood
	signPart.Anchored = true
	signPart.Parent = board

	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = signPart

	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundColor3 = Color3.fromRGB(60, 40, 25)
	container.Parent = signGui

	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.new(1, 0, 0.6, 0)
	signText.BackgroundTransparency = 1
	signText.Text = npcName and ("Challenge\n" .. npcName) or "CHECKERS"
	signText.TextColor3 = Color3.new(1, 1, 1)
	signText.Font = Enum.Font.GothamBold
	signText.TextSize = 20
	signText.Parent = container

	local rewardText = Instance.new("TextLabel")
	rewardText.Size = UDim2.new(1, 0, 0.4, 0)
	rewardText.Position = UDim2.new(0, 0, 0.6, 0)
	rewardText.BackgroundTransparency = 1
	rewardText.Text = "Win: " .. finalReward .. " Gold!"
	rewardText.TextColor3 = Color3.fromRGB(255, 215, 0)
	rewardText.Font = Enum.Font.GothamMedium
	rewardText.TextSize = 14
	rewardText.Parent = container

	-- Proximity prompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Play Checkers"
	prompt.ObjectText = npcName or "Challenge"
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 0.5
	prompt.Parent = tablePart

	board.Parent = workspace

	boardModels[board] = {
		npcName = npcName,
		reward = finalReward,
	}

	-- Connect prompt
	prompt.Triggered:Connect(function(player)
		-- Check if player already in game
		if activeGames[player] then
			MiniGameRemote:FireClient(player, "ALREADY_PLAYING", {})
			return
		end

		-- Start new game
		local game: CheckersGame = {
			board = initializeBoard(),
			currentTurn = "red",
			player = player,
			npcName = npcName,
			gameOver = false,
			winner = nil,
			selectedPiece = nil,
			validMoves = getAllValidMoves(initializeBoard(), true),
			reward = finalReward,
			boardModel = board,
		}

		activeGames[player] = game
		renderBoard(game)

		MiniGameRemote:FireClient(player, "CHECKERS_START", {
			opponent = npcName or "Mysterious Stranger",
			reward = finalReward,
		})

		print("[MiniGames]", player.Name, "started checkers vs", npcName or "stranger", "for", finalReward, "gold")
	end)

	return board
end

-- ==========================================
-- MAZE SYSTEM
-- ==========================================

type MazeData = {
	entrance: Vector3,
	exit: Vector3,
	playersInside: { [Player]: {
		startTime: number,
		completed: boolean,
	} },
	reward: number,
}

local mazes: { [Model]: MazeData } = {}

-- Create a custom hedge maze (not algorithmic!)
local function createMaze(position: Vector3, name: string, difficulty: string): Model
	local maze = Instance.new("Model")
	maze.Name = "Maze_" .. name

	local wallHeight = 10
	local wallColor = Color3.fromRGB(35, 70, 35)

	-- Custom maze layouts based on difficulty
	local layouts = {
		easy = {
			size = 40,
			reward = 50,
			-- Each wall: {startX, startZ, endX, endZ}
			walls = {
				-- Outer walls with openings
				{ 0, 0, 40, 0 }, -- Top
				{ 0, 40, 17, 40 }, { 23, 40, 40, 40 }, -- Bottom with entrance
				{ 0, 0, 0, 40 }, -- Left
				{ 40, 0, 40, 17 }, { 40, 23, 40, 40 }, -- Right with exit

				-- Internal walls
				{ 10, 0, 10, 25 },
				{ 20, 15, 20, 40 },
				{ 10, 25, 30, 25 },
				{ 30, 10, 30, 25 },
			},
		},
		medium = {
			size = 60,
			reward = 100,
			walls = {
				-- Outer walls
				{ 0, 0, 60, 0 },
				{ 0, 60, 25, 60 }, { 35, 60, 60, 60 }, -- Entrance
				{ 0, 0, 0, 60 },
				{ 60, 0, 60, 25 }, { 60, 35, 60, 60 }, -- Exit

				-- Complex internal structure
				{ 15, 0, 15, 35 },
				{ 15, 35, 35, 35 },
				{ 35, 20, 35, 35 },
				{ 25, 20, 35, 20 },
				{ 25, 20, 25, 50 },
				{ 45, 0, 45, 30 },
				{ 45, 30, 60, 30 },
				{ 0, 45, 15, 45 },
				{ 35, 45, 50, 45 },
				{ 50, 45, 50, 60 },
			},
		},
		hard = {
			size = 80,
			reward = 200,
			walls = {
				-- Outer
				{ 0, 0, 80, 0 },
				{ 0, 80, 35, 80 }, { 45, 80, 80, 80 },
				{ 0, 0, 0, 80 },
				{ 80, 0, 80, 35 }, { 80, 45, 80, 80 },

				-- Labyrinthine interior
				{ 15, 0, 15, 50 },
				{ 15, 50, 30, 50 },
				{ 30, 30, 30, 50 },
				{ 30, 30, 50, 30 },
				{ 50, 30, 50, 60 },
				{ 30, 60, 50, 60 },
				{ 0, 65, 30, 65 },
				{ 60, 0, 60, 45 },
				{ 60, 45, 80, 45 },
				{ 45, 15, 45, 30 },
				{ 30, 15, 45, 15 },
				{ 65, 55, 65, 80 },
				{ 15, 70, 50, 70 },
				{ 70, 15, 80, 15 },
				{ 70, 15, 70, 55 },
			},
		},
	}

	local layout = layouts[difficulty] or layouts.easy

	-- Ground
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(layout.size, 1, layout.size)
	floor.Position = position + Vector3.new(layout.size / 2, -0.5, layout.size / 2)
	floor.Color = Color3.fromRGB(80, 120, 60)
	floor.Material = Enum.Material.Grass
	floor.Anchored = true
	floor.Parent = maze

	-- Create walls from layout
	for i, wallData in layout.walls do
		local x1, z1, x2, z2 = wallData[1], wallData[2], wallData[3], wallData[4]

		local wall = Instance.new("Part")
		wall.Name = "Wall_" .. i

		if x1 == x2 then
			-- Vertical wall
			wall.Size = Vector3.new(2, wallHeight, math.abs(z2 - z1))
			wall.Position = position + Vector3.new(x1, wallHeight / 2, (z1 + z2) / 2)
		else
			-- Horizontal wall
			wall.Size = Vector3.new(math.abs(x2 - x1), wallHeight, 2)
			wall.Position = position + Vector3.new((x1 + x2) / 2, wallHeight / 2, z1)
		end

		wall.Color = wallColor
		wall.Material = Enum.Material.Grass
		wall.Anchored = true
		wall.Parent = maze

		-- Add leaves on top
		local leaves = Instance.new("Part")
		leaves.Size = Vector3.new(wall.Size.X + 1, 2, wall.Size.Z + 1)
		leaves.Position = wall.Position + Vector3.new(0, wallHeight / 2 + 0.5, 0)
		leaves.Color = Color3.fromRGB(45, 90, 45)
		leaves.Material = Enum.Material.Grass
		leaves.Anchored = true
		leaves.Parent = maze
	end

	-- Entrance sign
	local entranceSign = Instance.new("Part")
	entranceSign.Name = "EntranceSign"
	entranceSign.Size = Vector3.new(6, 4, 0.5)
	entranceSign.Position = position + Vector3.new(layout.size / 2, 6, layout.size + 3)
	entranceSign.Color = Color3.fromRGB(80, 50, 30)
	entranceSign.Material = Enum.Material.Wood
	entranceSign.Anchored = true
	entranceSign.Parent = maze

	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Back
	signGui.Parent = entranceSign

	local signFrame = Instance.new("Frame")
	signFrame.Size = UDim2.new(1, 0, 1, 0)
	signFrame.BackgroundColor3 = Color3.fromRGB(50, 35, 20)
	signFrame.Parent = signGui

	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.new(1, 0, 0.6, 0)
	signText.BackgroundTransparency = 1
	signText.Text = name .. " MAZE"
	signText.TextColor3 = Color3.new(1, 1, 1)
	signText.Font = Enum.Font.GothamBold
	signText.TextSize = 28
	signText.Parent = signFrame

	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.Size = UDim2.new(1, 0, 0.4, 0)
	rewardLabel.Position = UDim2.new(0, 0, 0.6, 0)
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.Text = "Reward: " .. layout.reward .. " Gold"
	rewardLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	rewardLabel.Font = Enum.Font.GothamMedium
	rewardLabel.TextSize = 18
	rewardLabel.Parent = signFrame

	-- Exit marker
	local exitMarker = Instance.new("Part")
	exitMarker.Name = "ExitMarker"
	exitMarker.Size = Vector3.new(4, 0.5, 4)
	exitMarker.Position = position + Vector3.new(layout.size - 5, 0.5, layout.size / 2)
	exitMarker.Color = Color3.fromRGB(100, 255, 100)
	exitMarker.Material = Enum.Material.Neon
	exitMarker.Anchored = true
	exitMarker.Parent = maze

	local exitLight = Instance.new("PointLight")
	exitLight.Color = Color3.fromRGB(100, 255, 100)
	exitLight.Brightness = 3
	exitLight.Range = 20
	exitLight.Parent = exitMarker

	-- Treasure chest at exit
	local chest = Instance.new("Part")
	chest.Name = "TreasureChest"
	chest.Size = Vector3.new(3, 2, 2)
	chest.Position = exitMarker.Position + Vector3.new(0, 1.5, 0)
	chest.Color = Color3.fromRGB(150, 100, 50)
	chest.Material = Enum.Material.Wood
	chest.Anchored = true
	chest.Parent = maze

	maze.Parent = workspace

	-- Store maze data
	mazes[maze] = {
		entrance = position + Vector3.new(layout.size / 2, 0, layout.size),
		exit = exitMarker.Position,
		playersInside = {},
		reward = layout.reward,
	}

	return maze
end

-- Check maze progress
local function checkMazeProgress()
	for mazeModel, mazeData in mazes do
		if not mazeModel or not mazeModel.Parent then continue end

		local exitMarker = mazeModel:FindFirstChild("ExitMarker") :: BasePart?
		if not exitMarker then continue end

		for _, player in Players:GetPlayers() do
			local character = player.Character
			if not character then continue end

			local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not rootPart then continue end

			local playerPos = rootPart.Position

			-- Check if entered maze
			local distToEntrance = (playerPos - mazeData.entrance).Magnitude
			if distToEntrance < 15 and not mazeData.playersInside[player] then
				mazeData.playersInside[player] = {
					startTime = tick(),
					completed = false,
				}
				MiniGameRemote:FireClient(player, "MAZE_ENTER", {
					mazeName = mazeModel.Name,
					reward = mazeData.reward,
				})
				print("[MiniGames]", player.Name, "entered", mazeModel.Name)
			end

			-- Check if reached exit
			if mazeData.playersInside[player] and not mazeData.playersInside[player].completed then
				local distToExit = (playerPos - exitMarker.Position).Magnitude
				if distToExit < 6 then
					local timeElapsed = tick() - mazeData.playersInside[player].startTime
					mazeData.playersInside[player].completed = true

					-- Award gold
					local TradingRemote = ReplicatedStorage:FindFirstChild("Trading") :: RemoteEvent?
					if TradingRemote then
						TradingRemote:FireClient(player, "GOLD_EARNED", {
							amount = mazeData.reward,
							source = "maze",
						})
					end

					MiniGameRemote:FireClient(player, "MAZE_COMPLETE", {
						mazeName = mazeModel.Name,
						time = math.floor(timeElapsed),
						reward = mazeData.reward,
					})

					print("[MiniGames]", player.Name, "completed", mazeModel.Name, "in", math.floor(timeElapsed), "s! Reward:", mazeData.reward)
				end
			end
		end
	end
end

-- ==========================================
-- SPAWN MINI-GAMES
-- ==========================================

local function spawnMiniGames()
	task.wait(7)

	print("[MiniGames] Spawning mini-games...")

	-- Checkers tables with different opponents and rewards
	createCheckersBoard(Vector3.new(100, 1, 50), "Old Timer Jenkins", 50) -- Easy opponent
	createCheckersBoard(Vector3.new(-80, 1, -100), "Cave Hermit", 100) -- Medium
	createCheckersBoard(Vector3.new(200, 1, 200), "The Grandmaster", 200) -- Hard
	createCheckersBoard(Vector3.new(-150, 1, 150), nil, 75) -- Mystery opponent

	-- Mazes with varying difficulty
	createMaze(Vector3.new(300, 0, 100), "Beginner's", "easy")
	createMaze(Vector3.new(-400, 0, 200), "Twisted", "medium")
	createMaze(Vector3.new(100, 0, -350), "Labyrinth of Doom", "hard")

	print("[MiniGames] Created 4 checkers tables, 3 mazes")
	print("[MiniGames] Checkers is FULLY PLAYABLE with AI!")
end

-- ==========================================
-- REMOTE HANDLERS
-- ==========================================

MiniGameRemote.OnServerEvent:Connect(function(player: Player, action: string, data: any?)
	if action == "FORFEIT" then
		local game = activeGames[player]
		if game then
			endGame(game, "black")
		end
	end
end)

-- Clean up when player leaves
Players.PlayerRemoving:Connect(function(player)
	if activeGames[player] then
		activeGames[player] = nil
	end

	for _, mazeData in mazes do
		mazeData.playersInside[player] = nil
	end
end)

-- ==========================================
-- GAME LOOP
-- ==========================================

local mazeCheckTimer = 0
RunService.Heartbeat:Connect(function(dt)
	mazeCheckTimer += dt
	if mazeCheckTimer >= 0.5 then
		mazeCheckTimer = 0
		checkMazeProgress()
	end
end)

-- Initialize
task.spawn(spawnMiniGames)

print("[MiniGames] Mini-games system initialized!")
print("[MiniGames] - Checkers: FULLY PLAYABLE against AI")
print("[MiniGames] - Mazes: Custom layouts with gold rewards")
