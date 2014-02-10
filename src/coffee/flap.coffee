# flap.coffee

stage = new PIXI.Stage(0x66ff99)

renderer = PIXI.autoDetectRenderer(400, 300)

# add the renderer view element to the DOM.
$("#pixistage").append(renderer.view)

# create texture
texture = PIXI.Texture.fromImage('image/sabazusi.png')

sabazusi = new PIXI.Sprite(texture)
sabazusi.anchor.x = 0.5
sabazusi.anchor.y = 0.5

sabazusi.position.x = 200
sabazusi.position.y = 150

stage.addChild(sabazusi)

animate = () ->
	requestAnimFrame( animate )

	sabazusi.rotation += 0.1

	renderer.render(stage)

requestAnimFrame( animate )
