# flap.coffee

# Box2Dに対するスケール(m/px)
SCALE = 1 / 30

stepTime = 1 / 30
stepVelocityIterations = 10
stepPositionIterations = 10

# === Box2D ===

# redefine class
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

world = new b2World(new b2Vec2(0, 9.8), true)

createSabazusi = () ->
	# フィクスチャー定義：物体の密度、摩擦、反発
	boxFixDef = new b2FixtureDef()
	boxFixDef.density = 1.0
	boxFixDef.friction = 0.5
	boxFixDef.restitution = 0.5

	# シェープ定義：形状(ここでは、一辺1m(30px)の正方形)
	boxShape = new b2PolygonShape()
	boxShape.SetAsBox(30 * SCALE, 30 * SCALE)

	boxFixDef.shape = boxShape

	# ボディ定義：座標、傾き、静動
	boxBodyDef = new b2BodyDef()
	boxBodyDef.position.Set(0, 0)
	boxBodyDef.type = b2Body.b2_dynamicBody

	# ボディをworldに生成し、フィクスチャーを追加する
	boxBody = world.CreateBody(boxBodyDef)
	boxBody.CreateFixture(boxFixDef)

	return boxBody

createGround = () ->
	# 地面
	groundFixDef = new b2FixtureDef()
	#groundFixDef.density = 1.0
	#groundFixDef.friction = 0.5
	#groundFixDef.restitution = 0.5

	groundShape = new b2PolygonShape()
	#groundShape.SetAsBox(300 * SCALE, 40 * SCALE)
	groundShape.SetAsBox(30 * SCALE, 30 * SCALE)

	groundFixDef.shape = groundShape

	groundBodyDef = new b2BodyDef()
	#groundBodyDef.position.Set(200 * SCALE, 250 * SCALE)
	groundBodyDef.position.Set(200 * SCALE, 100 * SCALE)
	groundBodyDef.type = b2BodyDef.b2_staticBody

	groundBody = world.CreateBody(groundBodyDef)
	groundBody.CreateFixture(groundFixDef)

	return groundBody

# positionで設定されるのは、bodyの中心座標?
boxBody = createSabazusi()
boxBody.SetPosition(new b2Vec2(200 * SCALE, 0 * SCALE))
groundBody = createGround()
#groundBody.SetPosition(new b2Vec2(200 * SCALE, 100 * SCALE))

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

pos = boxBody.GetPosition()
sabazusi.position.x = pos.x / SCALE
sabazusi.position.y = pos.y / SCALE

stage.addChild(sabazusi)

graphics = new PIXI.Graphics()

graphics.beginFill(0xff3300)
graphics.lineStyle(1, 0xffd900, 1)

graphics.moveTo(0, 0)
graphics.lineTo(0, 40)
graphics.lineTo(300, 40)
graphics.lineTo(300, 0)
graphics.lineTo(0, 0)
graphics.endFill()

stage.addChild(graphics)

animate = () ->
	requestAnimFrame( animate )

	world.Step(stepTime)
	pos = boxBody.GetPosition();
	sabazusi.position.x = pos.x / SCALE
	sabazusi.position.y = pos.y / SCALE
	sabazusi.rotation = boxBody.GetAngle()

	# anchor = left, top
	pos = groundBody.GetPosition()
	graphics.position.x = pos.x / SCALE - 300 / 2
	graphics.position.y = pos.y / SCALE - 40 / 2
	graphics.rotation = groundBody.GetAngle()

	renderer.render(stage)

requestAnimFrame( animate )
