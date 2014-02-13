# flap.coffee

# 1mを何pxで表すか
physScale = 32

fps = 40
stepTime = 1 / fps
stepVelocityIterations = 1
stepPositionIterations = 10

KEYCODE_LEFT = 37
KEYCODE_RIGHT = 39

# === Box2D ===

# redefine classes
b2Vec2 = Box2D.Common.Math.b2Vec2
b2BodyDef = Box2D.Dynamics.b2BodyDef
b2Body = Box2D.Dynamics.b2Body
b2FixtureDef = Box2D.Dynamics.b2FixtureDef
b2Fixture = Box2D.Dynamics.b2Fixture
b2World = Box2D.Dynamics.b2World
b2MassData = Box2D.Collision.Shapes.b2MassData
b2PolygonShape = Box2D.Collision.Shapes.b2PolygonShape
b2CircleShape = Box2D.Collision.Shapes.b2CircleShape
b2DebugDraw = Box2D.Dynamics.b2DebugDraw
b2MouseJointDef =  Box2D.Dynamics.Joints.b2MouseJointDef

world = new b2World(new b2Vec2(0, 9.8), true)

# フィクスチャー定義：物体の密度、摩擦、反発
fixtureDef = new b2FixtureDef()
fixtureDef.density = 1.0
fixtureDef.friction = 0.5
fixtureDef.restitution = 0.5

createSabazusi = (pWorld, pFixtureDef) ->
	bodyDef = new b2BodyDef()
	bodyDef.type = b2Body.b2_dynamicBody
	bodyDef.position.Set(200 / physScale, 0)

	pFixtureDef.shape = new b2PolygonShape()
	# set half of width, height
	pFixtureDef.shape.SetAsBox(32 / physScale / 2, 32 / physScale / 2)

	boxBody = pWorld.CreateBody(bodyDef)
	boxBody.CreateFixture(pFixtureDef)

	return boxBody

createGround = (pWorld, pFixtureDef) ->
	bodyDef = new b2BodyDef()
	bodyDef.type = b2Body.b2_staticBody
	bodyDef.position.Set(200 / physScale, 250 / physScale)

	pFixtureDef.shape = new b2PolygonShape()
	# set half of width, height
	pFixtureDef.shape.SetAsBox(200 / physScale / 2, 40 / physScale / 2)

	groundBody = pWorld.CreateBody(bodyDef)
	groundBody.CreateFixture(pFixtureDef)

	return groundBody

sabazusiBody= createSabazusi(world, fixtureDef)
groundBody = createGround(world, fixtureDef)

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

renderer = PIXI.autoDetectRenderer(400, 300)

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

graphics = new PIXI.Graphics()

graphics.beginFill(0xff3300)
graphics.lineStyle(1, 0xffd900, 1)

graphics.moveTo(0, 0)
graphics.lineTo(0, 40)
graphics.lineTo(200, 40)
graphics.lineTo(200, 0)
graphics.lineTo(0, 0)
graphics.endFill()

stage.addChild(graphics)

mouseX = mouseY = undefined
mouseXphys = mouseYphys = undefined
isMouseDown = false
mouseJoint = null
keyCode = 0

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

$('body').mousedown(handleMouseDown)
$('body').mouseup(handleMouseUp)

animate = () ->
	requestAnimFrame( animate )

	if (isMouseDown && (! mouseJoint))
		console.log "loop isMouseDown", mouseX, mouseY, mouseXphys, mouseYphys
		mouseJointDef = new b2MouseJointDef()
		mouseJointDef.bodyA = world.GetGroundBody()
		mouseJointDef.bodyB = sabazusiBody
		# ベクトルの開始座標を指定する
		#mouseJointDef.target.Set(mouseXphys, mouseYphys)
		pos = sabazusiBody.GetPosition()
		mouseJointDef.target.Set(pos.x, pos.y)
		mouseJointDef.collideConnected = true
		mouseJointDef.maxForce = 100.0 * sabazusiBody.GetMass()
		mouseJoint = world.CreateJoint(mouseJointDef)
		sabazusiBody.SetAwake(true)

	if (mouseJoint)
		if (isMouseDown)
			# ベクトルの終端を指定する
			mouseJoint.SetTarget(new b2Vec2(mouseXphys, mouseYphys))
		else
			world.DestroyJoint(mouseJoint)
			mouseJoint = null

	# worldの更新、経過時間、速度計算の内部繰り返し回数、位置計算の内部繰り返し回数
	#world.Step(stepTime, stepVelocityIterations, stepPositionIterations)

	pos = sabazusiBody.GetPosition();
	sabazusi.position.x = pos.x * physScale
	sabazusi.position.y = pos.y * physScale
	sabazusi.rotation = sabazusiBody.GetAngle()

	# anchor = left, top
	pos = groundBody.GetPosition()
	graphics.position.x = pos.x * physScale - 100
	graphics.position.y = pos.y * physScale - 20
	#graphics.rotation = groundBody.GetAngle()

	#world.ClearForces()

	renderer.render(stage)

requestAnimFrame( animate )

update = () ->
	world.Step(stepTime, stepVelocityIterations, stepPositionIterations)
	world.DrawDebugData()
	world.ClearForces()


window.setInterval(update, 1000 / fps)
