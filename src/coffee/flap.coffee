# flap.coffee

gravityX = 0
gravityY = 9.8

# 1mを何pxで表すか
physScale = 32

fps = 40
stepTime = 1 / fps
stepVelocityIterations = 10
stepPositionIterations = 10

KEYCODE_SPACE = 32
#KEYCODE_LEFT = 37
#KEYCODE_RIGHT = 39

WINDOW_WIDTH = 480
WINDOW_HEIGHT = 320

TYPE_TUMBLE_BOX = "tumbleBox"
TYPE_TUMBLE_TRI = "tumbleTriangle"
TYPE_SABA = "saba"

WALL_HEIGHT = 5

STAGE_TITLE = 10
STAGE_FLAPPING = 20
STAGE_RESULT = 21

game = {}
game.keyCode = 0
game.stageState = STAGE_TITLE
game.touchdownFlg = false

# === Box2D class Definition ===

b2Vec2 = Box2D.Common.Math.b2Vec2
b2BodyDef = Box2D.Dynamics.b2BodyDef
b2Body = Box2D.Dynamics.b2Body
b2FixtureDef = Box2D.Dynamics.b2FixtureDef
b2Fixture = Box2D.Dynamics.b2Fixture
b2World = Box2D.Dynamics.b2World
#b2MassData = Box2D.Collision.Shapes.b2MassData
b2PolygonShape = Box2D.Collision.Shapes.b2PolygonShape
b2CircleShape = Box2D.Collision.Shapes.b2CircleShape
b2DebugDraw = Box2D.Dynamics.b2DebugDraw
b2MouseJointDef =  Box2D.Dynamics.Joints.b2MouseJointDef
b2Listener = Box2D.Dynamics.b2ContactListener

# === PIXI Graphics object ===

class PIXIShape extends PIXI.Graphics
	constructor: ->
		super

	setSize: (width, height) ->
		@width = width
		@height = height

class PIXIShapeBox extends PIXIShape
	constructor: (pFillColor, pLineColor, pWidth, pHeight) ->
		super
		@buildGraph(pFillColor, pLineColor, pWidth, pHeight)
		@setSize(pWidth, pHeight)

	buildGraph: (pFillColor, pLineColor, pWidth, pHeight) ->
		@beginFill(pFillColor)
		@lineStyle(1, pLineColor, 1)

		@moveTo(0, 0)
		@lineTo(0, pHeight)
		@lineTo(pWidth, pHeight)
		@lineTo(pWidth, 0)
		@lineTo(0, 0)

		@endFill()

class PIXIShapePolygon extends PIXIShape
	# @param pVecs array of vector
	constructor: (pFillColor, pLineColor, radius, pVecs) ->
		super
		@buildGraph(pFillColor, pLineColor, pVecs)
		@setSize(radius, radius)

	buildGraph: (pFillColor, pLineColor, pVecs) ->
		@beginFill(pFillColor)
		@lineStyle(1, pLineColor, 1)

		@moveTo(pVecs[0][0], pVecs[0][1])
		for i in [0..pVecs.length]
			vec = pVecs[i % pVecs.length]
			@lineTo(vec[0], vec[1])

		@endFill()

class FSStage extends PIXI.Stage
	constructor: ->
		super
		@setBackgroundColor(0x696969)

	# 最初に一回だけ呼ばれる処理
	init: ->
		# abstract

	# 表示前の初期化処理
	willAppear: ->
		# abstract

	# リセット時に呼ばれる処理
	didDisappear: ->
		# abstract

	# return next state
	update: (currentState, keyCode) ->
		# abstract
		return false

# = world object 生成関数 =

class FSb2ShapeGenerator
	constructor: (pWorld) ->
		@world = pWorld

	setBoxShape: (pFixtureDef, pWidth, pHeight) ->
		pFixtureDef.shape = new b2PolygonShape()
		# set half of width, height
		pFixtureDef.shape.SetAsBox(pWidth / physScale / 2, pHeight / physScale / 2)

	setCircleShape: (pFixtureDef, pRadius) ->
		pFixtureDef.shape = new b2CircleShape(pRadius / physScale / 2)

	createDynamicBodyDef: (pX, pY) ->
		bodyDef = new b2BodyDef()
		bodyDef.type = b2Body.b2_dynamicBody
		bodyDef.position.Set(pX / physScale, pY / physScale)

		return bodyDef

	createStaticBodyDef: (pX, pY) ->
		bodyDef = new b2BodyDef()
		bodyDef.type = b2Body.b2_staticBody
		bodyDef.position.Set(pX / physScale, pY / physScale)

		return bodyDef

	createBody: (pBodyDef, pFixtureDef) ->
		body = @world.CreateBody(pBodyDef)
		body.CreateFixture(pFixtureDef)

		return body

	createDynamicBoxBody: (pFixtureDef, pX, pY, pWidth, pHeight) ->
		bodyDef = @createDynamicBodyDef(pX, pY)
		@setBoxShape(pFixtureDef, pWidth, pHeight)
		return @createBody(bodyDef, pFixtureDef)

	createStaticBoxBody: (pFixtureDef, pX, pY, pWidth, pHeight) ->
		bodyDef = @createStaticBodyDef(pX, pY)
		@setBoxShape(pFixtureDef, pWidth, pHeight)
		return @createBody(bodyDef, pFixtureDef)

	createDynamicCircleBody: (pFixtureDef, pX, pY, pRadius) ->
		bodyDef = @createDynamicBodyDef(pX, pY)
		@setCircleShape(pFixtureDef, pRadius)
		return @createBody(bodyDef, pFixtureDef)

createSabazusi = (pGenerator, pFixtureDef) ->
	return pGenerator.createDynamicBoxBody(pFixtureDef, WINDOW_WIDTH / 2, 32, 22, 22)

createGround = (pGenerator, pFixtureDef) ->
	return pGenerator.createStaticBoxBody(pFixtureDef, WINDOW_WIDTH / 2, 250, 200, 40)

createFrameObject = (pGenerator, pFixtureDef) ->
	pGenerator.createStaticBoxBody(pFixtureDef, WINDOW_WIDTH / 2, 0, WINDOW_WIDTH + 96, 10)
	pGenerator.createStaticBoxBody(pFixtureDef, WINDOW_WIDTH / 2, WINDOW_HEIGHT, WINDOW_WIDTH + 96, 10)

createCircle = (pGenerator, pFixtureDef) ->
	pGenerator.createDynamicCircleBody(pFixtureDef, 100, 32, 64)

# 重力の相殺(各Step実行前に設定されている必要がある)
offsetGravity = (pBody, linearVelocity) ->
	pBody.SetLinearVelocity(linearVelocity)
	pBody.ApplyForce(new b2Vec2(0, pBody.GetMass() * (-gravityY)), pBody.GetPosition())

world = new b2World(new b2Vec2(gravityX, gravityY), true)

generator = new FSb2ShapeGenerator(world)

# フィクスチャー定義：物体の密度、摩擦、反発
fixtureDef = new b2FixtureDef()
fixtureDef.density = 1.0
fixtureDef.friction = 0.5
fixtureDef.restitution = 0.5

# debug用表示の設定
debugDraw = new b2DebugDraw();          # Box2D.Dynamics.b2DebugDraw
debugDraw.SetSprite($("#box2ddebug")[0].getContext("2d")); # canvas 2dのcontextを設定
debugDraw.SetDrawScale(physScale);          # 表示のスケール(1メートル、何pixelか?)
debugDraw.SetFillAlpha(0.5);                # 塗りつぶし透明度を0.5に
debugDraw.SetLineThickness(1.0);            # lineの太さを1.0に
debugDraw.SetFlags(b2DebugDraw.e_shapeBit | b2DebugDraw.e_jointBit); # シェイプとジョイントを表示、他に
# e_aabbBit,e_pairBit,e_centerOfMassBit,e_controllerBitを設定可能
world.SetDebugDraw(debugDraw);              # worldにdebug用表示の設定

# 衝突イベントリスナの設定
listener = new b2Listener()

# 接触した場合に一度だけ発生する
listener.BeginContact = (contact) ->
	a = contact.GetFixtureA().GetBody().GetUserData();
	b = contact.GetFixtureB().GetBody().GetUserData();
	if ((a? && a.type == TYPE_SABA) || (b? && b.type == TYPE_SABA))
		game.touchdownFlg = true

world.SetContactListener(listener)

# === PIXIの初期化 ===

renderer = PIXI.autoDetectRenderer(WINDOW_WIDTH, WINDOW_HEIGHT)

# add the renderer view element to the DOM.
$("#pixistage").append(renderer.view)

# === レンダリング:スタート画面 ===

class ShowTitleStage extends FSStage
	constructor: ->
		super

		@init = ->
			width = WINDOW_WIDTH * 0.6
			height = WINDOW_HEIGHT / 2
			board = new PIXIShapeBox(0xdcdcdc, 0x696969, width, height)
			board.position.x = (WINDOW_WIDTH - width) / 2
			board.position.y = (WINDOW_HEIGHT - height) / 2
			@addChild(board)

			title = new PIXI.Text("Flapping SABAZUSI", {fill: "blue", align:'center'})
			title.width = WINDOW_WIDTH / 2
			title.height = 60
			title.position.x = (WINDOW_WIDTH - title.width) / 2
			title.position.y = (WINDOW_HEIGHT - title.height) / 2 - 30
			@addChild(title)

			desc = new PIXI.Text("key SPACE to start", {font: "35px Desyrel", fill: "black", align:'center'})
			desc.width = WINDOW_WIDTH / 2
			desc.height = 35
			desc.position.x = (WINDOW_WIDTH - desc.width) / 2
			desc.position.y = (WINDOW_HEIGHT - desc.height) / 2 + 60
			@addChild(desc)

		@update = (currentState, keyCode) ->
			if (keyCode == KEYCODE_SPACE)
				return STAGE_FLAPPING
			return currentState

# === レンダリング:ゲーム画面 ===

class GameStage extends FSStage
	constructor: ->
		super

		@init = ->
			getElementPosition = (element) ->
				return {x: element.offsetLeft, y: element.offsetTop}

			@canvasPosition = getElementPosition($('#pixistage')[0])

			ground = new PIXIShapeBox(0x808080, 0x696969, WINDOW_WIDTH, 20)
			ground.position.x = 0
			ground.position.y = 0
			@addChild(ground)

			ground = new PIXIShapeBox(0x808080, 0x696969, WINDOW_WIDTH, 20)
			ground.position.x = 0
			ground.position.y = WINDOW_HEIGHT - 20
			@addChild(ground)

			# create texture
			texture = PIXI.Texture.fromImage('image/sabazusi.png')

			sabazusi = new PIXI.Sprite(texture)
			sabazusi.anchor.x = 0.5
			sabazusi.anchor.y = 0.5
			@sabazusiSprite = sabazusi

			createFrameObject(generator, fixtureDef)

		@willAppear = ->
			console.log "willAppear"

			@lastTumble = {}
			@lastTumble.upper = {body: undefined, size: 0}
			@lastTumble.down = {body: undefined, size: 0}

			@mouseX = undefined
			@mouseY = undefined
			@mouseXphys = undefined
			@mouseYphys = undefined
			@isMouseDown = false
			@mouseJoint = null
			@jampingTick = 0
			@inputTick = 0
			@generateTick = 0
			@sabazusiBody = undefined

			game.touchdownFlg = false
			@score = 0
			@gameOverTick = fps * 0.8
			@goAwayTick = @gameOverTick + fps * 0.5
			@goAwayFlg = false

			@sabazusiBody = createSabazusi(generator, fixtureDef)
			@sabazusiBody.SetUserData({type: TYPE_SABA, renderObj: @sabazusiSprite})

			@addChild(@sabazusiSprite)

		@didDisappear = ->
			console.log "reset"

			# 片付け
			if (@mouseJoint)
				world.DestroyJoint(@mouseJoint)
				@mouseJoint = null

			body = world.GetBodyList()
			while body
				bodyData = body.GetUserData()
				if (bodyData?)
					if (bodyData.type == TYPE_TUMBLE_BOX || bodyData.type == TYPE_TUMBLE_TRI || bodyData.type == TYPE_SABA)
						if (bodyData.renderObj?)
							@removeChild(bodyData.renderObj)
						world.DestroyBody(body)

				body = body.GetNext()

			@removeResultPanel()

		@update = (currentState, keyCode) ->
			if (game.touchdownFlg)
				# game over
				if (! @goAwayFlg)
					if (@gameOverTick == 0 && ! @goAwayFlg)
						@addResultPanel()

					if (@goAwayTick == 0)
						@goAwayFlg = true

					if (@gameOverTick > 0)
						@gameOverTick--
					if (@goAwayTick > 0)
						@goAwayTick--

				if (@goAwayFlg && keyCode == KEYCODE_SPACE)
					return STAGE_TITLE

			else
				if (@generateTick == 0)
					@generateTumble(generator, fixtureDef, @)
					@generateTick = 1

				if (@inputTick == 0 && @jampingTick == 0 && keyCode == KEYCODE_SPACE && (! @mouseJoint))
					@jampingTick = fps * 0.2
					@inputTick = fps * 0.4

					@sabazusiBody.SetLinearVelocity(new b2Vec2(0, 0))
					pos = @sabazusiBody.GetPosition()
					mouseJointDef = new b2MouseJointDef()
					mouseJointDef.bodyA = world.GetGroundBody()
					mouseJointDef.bodyB = @sabazusiBody
					# ベクトルの開始座標を指定する
					mouseJointDef.target.Set(pos.x, pos.y)
					mouseJointDef.collideConnected = true
					mouseJointDef.maxForce = 85.0 * @sabazusiBody.GetMass()
					@mouseJoint = world.CreateJoint(mouseJointDef)
					@sabazusiBody.SetAwake(true)

					@mouseJoint.SetTarget(new b2Vec2(pos.x, pos.y - 1.1))

				else if (@mouseJoint)
					if (@jampingTick == 0)
						world.DestroyJoint(@mouseJoint)
						@mouseJoint = null

				if (@jampingTick > 0)
					@jampingTick--
				if (@inputTick > 0)
					@inputTick--
				if (@generateTick > 0)
					@generateTick--

				body = world.GetBodyList()
				while body
					bodyData = body.GetUserData()
					if (bodyData?)
						# 位置の更新
						obj = bodyData.renderObj
						if (obj?)
							pos = body.GetPosition()
							obj.rotation = body.GetAngle()
							obj.position.x = Math.floor(pos.x * physScale)
							obj.position.y = Math.floor(pos.y * physScale)
							if (obj instanceof PIXIShapeBox)
								obj.position.x -= Math.floor(obj.width / 2)
								obj.position.y -= Math.floor(obj.height / 2)
						# 削除と方向修正
						if (bodyData.type == TYPE_TUMBLE_BOX || bodyData.type == TYPE_TUMBLE_TRI)
							if (body.GetPosition().x < -2)
								# 範囲外にきたときに削除
								@removeChild(bodyData.renderObj)
								world.DestroyBody(body)
							else
								# 重力の相殺
								offsetGravity(body, new b2Vec2(-1.5, 0))
								# スコア計算
								if (! bodyData.isChecked)
									sabaX = Math.floor(@sabazusiBody.GetPosition().x * physScale)
									if (bodyData.type == TYPE_TUMBLE_BOX)
										x = Math.floor(body.GetPosition().x * physScale) + bodyData.renderObj.width / 2
										if (x < sabaX)
											bodyData.isChecked = true
											@score++

					body = body.GetNext()

				# worldの更新、経過時間、速度計算の内部繰り返し回数、位置計算の内部繰り返し回数
				world.Step(stepTime, stepVelocityIterations, stepPositionIterations)

				world.DrawDebugData()
				world.ClearForces()

			return currentState

	boxScale = [1,1,1,2,2,2,3,3,4,5]

	generateTumble: (pGenerator, pFixtureDef, pStage) ->
		if (@lastTumble.upper.body == undefined || @lastTumble.upper.body.GetPosition().x < (WINDOW_WIDTH - @lastTumble.upper.size / 2) / physScale)
			scaleNum = Math.floor( Math.random() * boxScale.length )
			size = boxScale[scaleNum] * 32
			x = WINDOW_WIDTH + size / 2
			y = size / 2 + WALL_HEIGHT
			width = size / 2
			height = size
			upper = pGenerator.createDynamicBoxBody(pFixtureDef, x, y, width, height)
			box = new PIXIShapeBox(0x2f4f4f, 0x000000, width, height)

			upper.SetLinearVelocity(new b2Vec2(-1.5, 0))
			upper.SetUserData({type: TYPE_TUMBLE_BOX, renderObj: box, isChecked: false})
			@lastTumble.upper.body = upper
			@lastTumble.upper.size = size

			@addChild(box)

		if (@lastTumble.down.body == undefined || @lastTumble.down.body.GetPosition().x < (WINDOW_WIDTH - @lastTumble.down.size / 2) / physScale)
			downRadius = Math.floor((Math.random() + 0.1) * (WINDOW_HEIGHT / 6)) + 32
			v = 3
			vecs = []
			g_vecs = []
			for i in [0...3]
				x = downRadius * Math.cos(Math.PI * 2 / v * i)
				y = downRadius * Math.sin(Math.PI * 2 / v * i)
				vec = new b2Vec2( x / physScale / 2, y / physScale / 2)
				gvec = [x / 2, y / 2]
				vecs.push(vec)
				g_vecs.push(gvec)
			bodyDef = pGenerator.createDynamicBodyDef(WINDOW_WIDTH + downRadius, WINDOW_HEIGHT - downRadius / 2)
			pFixtureDef.shape = new b2PolygonShape()
			pFixtureDef.shape.SetAsArray(vecs, vecs.length)
			down = pGenerator.createBody(bodyDef, pFixtureDef)

			triangle = new PIXIShapePolygon(0x2f4f4f, 0x000000, downRadius, g_vecs)

			down.SetLinearVelocity(new b2Vec2(-1.5, 0))
			down.SetUserData({type: TYPE_TUMBLE_TRI, renderObj: triangle, isChecked: false})
			@lastTumble.down.body = down
			@lastTumble.down.size = downRadius

			@addChild(triangle)

	addResultPanel: ->
		if (@resultPanel?)
			return

		width = WINDOW_WIDTH * 0.6
		height = WINDOW_HEIGHT / 2
		board = new PIXIShapeBox(0xdcdcdc, 0x696969, width, height)
		board.position.x = (WINDOW_WIDTH - width) / 2
		board.position.y = (WINDOW_HEIGHT - height) / 2
		@addChild(board)

		title = new PIXI.Text("RESULT", {font: "35px Desyrel", fill: "black", align:'center'})
		title.width = WINDOW_WIDTH / 3
		title.height = 35
		title.position.x = (WINDOW_WIDTH - title.width) / 2
		title.position.y = (WINDOW_HEIGHT - title.height) / 2 - 20
		@addChild(title)

		score = new PIXI.Text("Score: " + @score, {font: "35px Desyrel", fill: "black", align:'center'})
		score.width = WINDOW_WIDTH / 4
		score.height = 35
		score.position.x = (WINDOW_WIDTH - score.width) / 2
		score.position.y = (WINDOW_HEIGHT - score.height) / 2 + 20
		@addChild(score)

		@resultPanel or= {}
		@resultPanel.back = board
		@resultPanel.title = title
		@resultPanel.score = score

	removeResultPanel: ->
		if (@resultPanel?)
			@removeChild(@resultPanel.back)
			@removeChild(@resultPanel.title)
			@removeChild(@resultPanel.score)
			@resultPanel = undefined

# === キーイベントの設定 ===

handleKeyDown = (e) ->
	console.log e.keyCode
	game.keyCode = e.keyCode

$('body').keydown(handleKeyDown)

# === レンダリングループ ===

showTitle = new ShowTitleStage()
showTitle.init()
flapping = new GameStage()
flapping.init()

getStage = (stageState) ->
	switch stageState
		when STAGE_TITLE
			return showTitle
		when STAGE_FLAPPING
			return flapping
	return undefined

animate = () ->
	requestAnimFrame( animate )

	prevState = game.stageState

	stage = getStage(game.stageState)

	game.stageState = stage.update(game.stageState, game.keyCode)

	if (game.stageState != prevState)
		stage = getStage(game.stageState)
		console.log "state changed", prevState, game.stageState
		stage.didDisappear()
		stage.willAppear()

	game.keyCode = 0

	renderer.render(stage)

requestAnimFrame( animate )
