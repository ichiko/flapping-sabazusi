# flap.coffee

# 1mを何pxで表すか
physScale = 32

fps = 40
stepTime = 1 / fps
stepVelocityIterations = 1
stepPositionIterations = 10

KEYCODE_SPACE = 32
KEYCODE_LEFT = 37
KEYCODE_RIGHT = 39

WINDOW_WIDTH = 480
WINDOW_HEIGHT = 320

# === Box2D ===

# redefine classes
b2Vec2 = Box2D.Common.Math.b2Vec2
b2BodyDef = Box2D.Dynamics.b2BodyDef
b2Body = Box2D.Dynamics.b2Body
b2FixtureDef = Box2D.Dynamics.b2FixtureDef
b2Fixture = Box2D.Dynamics.b2Fixture
b2World = Box2D.Dynamics.b2World
#b2MassData = Box2D.Collision.Shapes.b2MassData
b2PolygonShape = Box2D.Collision.Shapes.b2PolygonShape
#b2CircleShape = Box2D.Collision.Shapes.b2CircleShape
b2DebugDraw = Box2D.Dynamics.b2DebugDraw
b2MouseJointDef =  Box2D.Dynamics.Joints.b2MouseJointDef
b2Listener = Box2D.Dynamics.b2ContactListener

world = new b2World(new b2Vec2(0, 9.8), true)

# フィクスチャー定義：物体の密度、摩擦、反発
fixtureDef = new b2FixtureDef()
fixtureDef.density = 1.0
fixtureDef.friction = 0.5
fixtureDef.restitution = 0.5

createBoxBody = (pWorld, pFixtureDef, pBodyDef, pWidth, pHeight) ->
	pFixtureDef.shape = new b2PolygonShape()
	# set half of width, height
	pFixtureDef.shape.SetAsBox(pWidth / physScale / 2, pHeight / physScale / 2)

	body = pWorld.CreateBody(pBodyDef)
	body.CreateFixture(pFixtureDef)

	return body

createDynamicBoxBody = (pWorld, pFixtureDef, pX, pY, pWidth, pHeight) ->
	bodyDef = new b2BodyDef()
	bodyDef.type = b2Body.b2_dynamicBody
	bodyDef.position.Set(pX / physScale, pY / physScale)

	return createBoxBody(pWorld, pFixtureDef, bodyDef, pWidth, pHeight)

createStaticBoxBody = (pWorld, pFixtureDef, pX, pY, pWidth, pHeight) ->
	bodyDef = new b2BodyDef()
	bodyDef.type = b2Body.b2_staticBody
	bodyDef.position.Set(pX / physScale, pY / physScale)

	return createBoxBody(pWorld, pFixtureDef, bodyDef, pWidth, pHeight)

createSabazusi = (pWorld, pFixtureDef) ->
	return createDynamicBoxBody(pWorld, pFixtureDef, WINDOW_WIDTH / 2, 32, 32, 32)

createGround = (pWorld, pFixtureDef) ->
	return createStaticBoxBody(pWorld, pFixtureDef, WINDOW_WIDTH / 2, 250, 200, 40)

createFrameObject = (pWorld, pFixtureDef) ->
	createStaticBoxBody(pWorld, pFixtureDef, WINDOW_WIDTH / 2, 0, WINDOW_WIDTH, 10)
	createStaticBoxBody(pWorld, pFixtureDef, WINDOW_WIDTH / 2, WINDOW_HEIGHT, WINDOW_WIDTH, 10)

createFrameObject(world, fixtureDef)
sabazusiBody= createSabazusi(world, fixtureDef)
#groundBody = createGround(world, fixtureDef)

# debug用表示の設定
debugDraw = new b2DebugDraw();          # Box2D.Dynamics.b2DebugDraw
debugDraw.SetSprite($("#box2ddebug")[0].getContext("2d")); # canvas 2dのcontextを設定
debugDraw.SetDrawScale(physScale);          # 表示のスケール(1メートル、何pixelか?)
debugDraw.SetFillAlpha(0.5);                # 塗りつぶし透明度を0.5に
debugDraw.SetLineThickness(1.0);            # lineの太さを1.0に
debugDraw.SetFlags(b2DebugDraw.e_shapeBit | b2DebugDraw.e_jointBit); # シェイプとジョイントを表示、他に
# e_aabbBit,e_pairBit,e_centerOfMassBit,e_controllerBitを設定可能
world.SetDebugDraw(debugDraw);              # worldにdebug用表示の設定

# === PIXI ===

stage = new PIXI.Stage(0x66ff99)

renderer = PIXI.autoDetectRenderer(WINDOW_WIDTH, WINDOW_HEIGHT)

# add the renderer view element to the DOM.
$("#pixistage").append(renderer.view)

# create texture
texture = PIXI.Texture.fromImage('image/sabazusi.png')

sabazusi = new PIXI.Sprite(texture)
sabazusi.anchor.x = 0.5
sabazusi.anchor.y = 0.5

pos = sabazusiBody.GetPosition()
sabazusi.position.x = pos.x * physScale
sabazusi.position.y = pos.y * physScale

stage.addChild(sabazusi)

mouseX = mouseY = undefined
mouseXphys = mouseYphys = undefined
isMouseDown = false
mouseJoint = null
keyCode = 0
jampingTick = 0
inputTick = 0

getElementPosition = (element) ->
	return {x: element.offsetLeft, y: element.offsetTop}

canvasPosition = getElementPosition($('#pixistage')[0])

handleMouseDown = (e) ->
	console.log "mouseDown", e.clientX, e.clientY
	isMouseDown = true
	handleMouseMove(e)
	$('body').mousemove(handleMouseMove)

handleMouseUp = (e) ->
	console.log "mouseUp", e.clientX, e.clientY
	$('body').unbind("mousemove", handleMouseMove)
	isMouseDown = false
	mouseX = mouseY = undefined
	mouseXphys = mouseYphys = undefined

handleMouseMove = (e) ->
	console.log "mouseMove", e.clientX, e.clientY
	mouseX = e.clientX - canvasPosition.x
	mouseY = e.clientY - canvasPosition.y
	mouseXphys = mouseX / physScale
	mouseYphys = mouseY / physScale

handleKeyDown = (e) ->
	console.log e.keyCode
	keyCode = e.keyCode

$('body').mousedown(handleMouseDown)
$('body').mouseup(handleMouseUp)
$('body').keydown(handleKeyDown)

animate = () ->
	requestAnimFrame( animate )

	if (inputTick == 0 && jampingTick == 0 && keyCode > 0 && (! mouseJoint))
		jampingTick = fps * 0.2
		inputTick = fps * 0.5

		sabazusiBody.SetLinearVelocity(new b2Vec2(0, 0))
		pos = sabazusiBody.GetPosition()
		console.log "loop keyCode is set", pos.x, pos.y
		mouseJointDef = new b2MouseJointDef()
		mouseJointDef.bodyA = world.GetGroundBody()
		mouseJointDef.bodyB = sabazusiBody
		# ベクトルの開始座標を指定する
		mouseJointDef.target.Set(pos.x, pos.y)
		mouseJointDef.collideConnected = true
		mouseJointDef.maxForce = 80.0 * sabazusiBody.GetMass()
		mouseJoint = world.CreateJoint(mouseJointDef)
		sabazusiBody.SetAwake(true)

		switch keyCode
			when KEYCODE_SPACE
				mouseJoint.SetTarget(new b2Vec2(pos.x, pos.y - 1.5))
			when KEYCODE_LEFT
				mouseJoint.SetTarget(new b2Vec2(pos.x - 0.2, pos.y - 1))
			when KEYCODE_RIGHT
				mouseJoint.SetTarget(new b2Vec2(pos.x + 0.2, pos.y - 1))

	else if (mouseJoint)
		if (jampingTick == 0)
			world.DestroyJoint(mouseJoint)
			mouseJoint = null
			keyCode = 0

	if (jampingTick > 0)
		jampingTick--
	if (inputTick > 0)
		inputTick--

	# worldの更新、経過時間、速度計算の内部繰り返し回数、位置計算の内部繰り返し回数
	world.Step(stepTime, stepVelocityIterations, stepPositionIterations)

	pos = sabazusiBody.GetPosition();
	sabazusi.position.x = pos.x * physScale
	sabazusi.position.y = pos.y * physScale
	sabazusi.rotation = sabazusiBody.GetAngle()

	world.DrawDebugData()
	world.ClearForces()

	renderer.render(stage)

requestAnimFrame( animate )
