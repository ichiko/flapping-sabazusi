(function() {
  var AUDIO_EXT, FSStage, FSb2ShapeGenerator, GameStage, KEYCODE_SPACE, PIXIShape, PIXIShapeBox, PIXIShapePolygon, STAGE_FLAPPING, STAGE_RESULT, STAGE_TITLE, ShowTitleStage, TYPE_SABA, TYPE_TUMBLE_BOX, TYPE_TUMBLE_TRI, WALL_HEIGHT, WINDOW_HEIGHT, WINDOW_WIDTH, animate, audioBackupCount, audioList, b2Body, b2BodyDef, b2CircleShape, b2DebugDraw, b2Fixture, b2FixtureDef, b2Listener, b2MouseJointDef, b2PolygonShape, b2Vec2, b2World, createAudio, createCircle, createFrameObject, createGround, createSabazusi, debugDraw, ditectAudioExt, enableDebugDraw, fixtureDef, flapping, fps, game, generator, getStage, gravityX, gravityY, handleKeyDown, handleTouchEvent, listener, offsetGravity, onClickOrTap, physScale, playAudio, renderer, showTitle, stepPositionIterations, stepTime, stepVelocityIterations, touchStarted, world,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  gravityX = 0;

  gravityY = 9.8;

  physScale = 32;

  fps = 30;

  stepTime = 1 / fps;

  stepVelocityIterations = 10;

  stepPositionIterations = 10;

  enableDebugDraw = false;

  KEYCODE_SPACE = 32;

  WINDOW_WIDTH = 480;

  WINDOW_HEIGHT = 320;

  TYPE_TUMBLE_BOX = "tumbleBox";

  TYPE_TUMBLE_TRI = "tumbleTriangle";

  TYPE_SABA = "saba";

  WALL_HEIGHT = 5;

  STAGE_TITLE = 10;

  STAGE_FLAPPING = 20;

  STAGE_RESULT = 21;

  game = {};

  game.keyCode = 0;

  game.stageState = STAGE_TITLE;

  game.touchdownFlg = false;

  b2Vec2 = Box2D.Common.Math.b2Vec2;

  b2BodyDef = Box2D.Dynamics.b2BodyDef;

  b2Body = Box2D.Dynamics.b2Body;

  b2FixtureDef = Box2D.Dynamics.b2FixtureDef;

  b2Fixture = Box2D.Dynamics.b2Fixture;

  b2World = Box2D.Dynamics.b2World;

  b2PolygonShape = Box2D.Collision.Shapes.b2PolygonShape;

  b2CircleShape = Box2D.Collision.Shapes.b2CircleShape;

  b2DebugDraw = Box2D.Dynamics.b2DebugDraw;

  b2MouseJointDef = Box2D.Dynamics.Joints.b2MouseJointDef;

  b2Listener = Box2D.Dynamics.b2ContactListener;

  PIXIShape = (function(_super) {
    __extends(PIXIShape, _super);

    function PIXIShape() {
      PIXIShape.__super__.constructor.apply(this, arguments);
    }

    PIXIShape.prototype.setSize = function(width, height) {
      this.width = width;
      return this.height = height;
    };

    return PIXIShape;

  })(PIXI.Graphics);

  PIXIShapeBox = (function(_super) {
    __extends(PIXIShapeBox, _super);

    function PIXIShapeBox(pFillColor, pLineColor, pWidth, pHeight) {
      PIXIShapeBox.__super__.constructor.apply(this, arguments);
      this.buildGraph(pFillColor, pLineColor, pWidth, pHeight);
      this.setSize(pWidth, pHeight);
    }

    PIXIShapeBox.prototype.buildGraph = function(pFillColor, pLineColor, pWidth, pHeight) {
      this.beginFill(pFillColor);
      this.lineStyle(1, pLineColor, 1);
      this.moveTo(0, 0);
      this.lineTo(0, pHeight);
      this.lineTo(pWidth, pHeight);
      this.lineTo(pWidth, 0);
      this.lineTo(0, 0);
      return this.endFill();
    };

    return PIXIShapeBox;

  })(PIXIShape);

  PIXIShapePolygon = (function(_super) {
    __extends(PIXIShapePolygon, _super);

    function PIXIShapePolygon(pFillColor, pLineColor, radius, pVecs) {
      PIXIShapePolygon.__super__.constructor.apply(this, arguments);
      this.buildGraph(pFillColor, pLineColor, pVecs);
      this.setSize(radius, radius);
    }

    PIXIShapePolygon.prototype.buildGraph = function(pFillColor, pLineColor, pVecs) {
      var i, vec, _i, _ref;
      this.beginFill(pFillColor);
      this.lineStyle(1, pLineColor, 1);
      this.moveTo(pVecs[0][0], pVecs[0][1]);
      for (i = _i = 0, _ref = pVecs.length; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
        vec = pVecs[i % pVecs.length];
        this.lineTo(vec[0], vec[1]);
      }
      return this.endFill();
    };

    return PIXIShapePolygon;

  })(PIXIShape);

  FSStage = (function(_super) {
    __extends(FSStage, _super);

    function FSStage() {
      FSStage.__super__.constructor.apply(this, arguments);
      this.setBackgroundColor(0x696969);
    }

    FSStage.prototype.init = function() {};

    FSStage.prototype.willAppear = function() {};

    FSStage.prototype.didDisappear = function() {};

    FSStage.prototype.update = function(currentState, keyCode) {
      return false;
    };

    return FSStage;

  })(PIXI.Stage);

  FSb2ShapeGenerator = (function() {
    function FSb2ShapeGenerator(pWorld) {
      this.world = pWorld;
    }

    FSb2ShapeGenerator.prototype.setBoxShape = function(pFixtureDef, pWidth, pHeight) {
      pFixtureDef.shape = new b2PolygonShape();
      return pFixtureDef.shape.SetAsBox(pWidth / physScale / 2, pHeight / physScale / 2);
    };

    FSb2ShapeGenerator.prototype.setCircleShape = function(pFixtureDef, pRadius) {
      return pFixtureDef.shape = new b2CircleShape(pRadius / physScale / 2);
    };

    FSb2ShapeGenerator.prototype.createDynamicBodyDef = function(pX, pY) {
      var bodyDef;
      bodyDef = new b2BodyDef();
      bodyDef.type = b2Body.b2_dynamicBody;
      bodyDef.position.Set(pX / physScale, pY / physScale);
      return bodyDef;
    };

    FSb2ShapeGenerator.prototype.createStaticBodyDef = function(pX, pY) {
      var bodyDef;
      bodyDef = new b2BodyDef();
      bodyDef.type = b2Body.b2_staticBody;
      bodyDef.position.Set(pX / physScale, pY / physScale);
      return bodyDef;
    };

    FSb2ShapeGenerator.prototype.createBody = function(pBodyDef, pFixtureDef) {
      var body;
      body = this.world.CreateBody(pBodyDef);
      body.CreateFixture(pFixtureDef);
      return body;
    };

    FSb2ShapeGenerator.prototype.createDynamicBoxBody = function(pFixtureDef, pX, pY, pWidth, pHeight) {
      var bodyDef;
      bodyDef = this.createDynamicBodyDef(pX, pY);
      this.setBoxShape(pFixtureDef, pWidth, pHeight);
      return this.createBody(bodyDef, pFixtureDef);
    };

    FSb2ShapeGenerator.prototype.createStaticBoxBody = function(pFixtureDef, pX, pY, pWidth, pHeight) {
      var bodyDef;
      bodyDef = this.createStaticBodyDef(pX, pY);
      this.setBoxShape(pFixtureDef, pWidth, pHeight);
      return this.createBody(bodyDef, pFixtureDef);
    };

    FSb2ShapeGenerator.prototype.createDynamicCircleBody = function(pFixtureDef, pX, pY, pRadius) {
      var bodyDef;
      bodyDef = this.createDynamicBodyDef(pX, pY);
      this.setCircleShape(pFixtureDef, pRadius);
      return this.createBody(bodyDef, pFixtureDef);
    };

    return FSb2ShapeGenerator;

  })();

  createSabazusi = function(pGenerator, pFixtureDef) {
    return pGenerator.createDynamicBoxBody(pFixtureDef, WINDOW_WIDTH / 2, 32, 22, 22);
  };

  createGround = function(pGenerator, pFixtureDef) {
    return pGenerator.createStaticBoxBody(pFixtureDef, WINDOW_WIDTH / 2, 250, 200, 40);
  };

  createFrameObject = function(pGenerator, pFixtureDef) {
    pGenerator.createStaticBoxBody(pFixtureDef, WINDOW_WIDTH / 2, 0, WINDOW_WIDTH + 96, 10);
    return pGenerator.createStaticBoxBody(pFixtureDef, WINDOW_WIDTH / 2, WINDOW_HEIGHT, WINDOW_WIDTH + 96, 10);
  };

  createCircle = function(pGenerator, pFixtureDef) {
    return pGenerator.createDynamicCircleBody(pFixtureDef, 100, 32, 64);
  };

  offsetGravity = function(pBody, linearVelocity) {
    pBody.SetLinearVelocity(linearVelocity);
    return pBody.ApplyForce(new b2Vec2(0, pBody.GetMass() * (-gravityY)), pBody.GetPosition());
  };

  world = new b2World(new b2Vec2(gravityX, gravityY), true);

  generator = new FSb2ShapeGenerator(world);

  fixtureDef = new b2FixtureDef();

  fixtureDef.density = 1.0;

  fixtureDef.friction = 0.5;

  fixtureDef.restitution = 0.5;

  if (enableDebugDraw) {
    debugDraw = new b2DebugDraw();
    debugDraw.SetSprite($("#box2ddebug")[0].getContext("2d"));
    debugDraw.SetDrawScale(physScale);
    debugDraw.SetFillAlpha(0.5);
    debugDraw.SetLineThickness(1.0);
    debugDraw.SetFlags(b2DebugDraw.e_shapeBit | b2DebugDraw.e_jointBit);
    world.SetDebugDraw(debugDraw);
  }

  listener = new b2Listener();

  listener.BeginContact = function(contact) {
    var a, b;
    a = contact.GetFixtureA().GetBody().GetUserData();
    b = contact.GetFixtureB().GetBody().GetUserData();
    if (((a != null) && a.type === TYPE_SABA) || ((b != null) && b.type === TYPE_SABA)) {
      return game.touchdownFlg = true;
    }
  };

  world.SetContactListener(listener);

  ditectAudioExt = function() {
    var audio;
    audio = new Audio();
    if (audio.canPlayType("audio/ogg") === 'maybe') {
      return 'ogg';
    } else if (audio.canPlayType("audio/mp3") === 'maybe') {
      return 'mp3';
    } else if (audio.canPlayType("audio/wav") === 'maybe') {
      return 'wav';
    }
    audio = void 0;
    return '';
  };

  AUDIO_EXT = ditectAudioExt();

  audioBackupCount = 2;

  createAudio = function(filepath, count) {
    var i, list, _i;
    list = [];
    for (i = _i = 0; 0 <= count ? _i < count : _i > count; i = 0 <= count ? ++_i : --_i) {
      list.push(new Audio(filepath));
    }
    return list;
  };

  audioList = {
    'score': {
      list: createAudio("sound/SE001." + AUDIO_EXT, audioBackupCount),
      index: 0
    }
  };

  playAudio = function(id) {
    var audioData;
    if (AUDIO_EXT === '') {
      return;
    }
    audioData = audioList[id];
    audioData.list[audioData.index].play();
    audioData.index++;
    if (audioData.index >= audioBackupCount) {
      return audioData.index = 0;
    }
  };

  renderer = PIXI.autoDetectRenderer(WINDOW_WIDTH, WINDOW_HEIGHT);

  $("#pixistage").append(renderer.view);

  ShowTitleStage = (function(_super) {
    __extends(ShowTitleStage, _super);

    function ShowTitleStage() {
      ShowTitleStage.__super__.constructor.apply(this, arguments);
      this.init = function() {
        var board, desc, height, title, width;
        width = WINDOW_WIDTH * 0.6;
        height = WINDOW_HEIGHT / 2;
        board = new PIXIShapeBox(0xdcdcdc, 0x696969, width, height);
        board.position.x = (WINDOW_WIDTH - width) / 2;
        board.position.y = (WINDOW_HEIGHT - height) / 2;
        this.addChild(board);
        title = new PIXI.Text("Flapping SABAZUSI", {
          fill: "blue",
          align: 'center'
        });
        title.width = WINDOW_WIDTH / 2;
        title.height = 60;
        title.position.x = (WINDOW_WIDTH - title.width) / 2;
        title.position.y = (WINDOW_HEIGHT - title.height) / 2 - 30;
        this.addChild(title);
        desc = new PIXI.Text("key SPACE to start", {
          font: "35px Desyrel",
          fill: "black",
          align: 'center'
        });
        desc.width = WINDOW_WIDTH / 2;
        desc.height = 35;
        desc.position.x = (WINDOW_WIDTH - desc.width) / 2;
        desc.position.y = (WINDOW_HEIGHT - desc.height) / 2 + 60;
        return this.addChild(desc);
      };
      this.update = function(currentState, keyCode) {
        if (keyCode === KEYCODE_SPACE) {
          return STAGE_FLAPPING;
        }
        return currentState;
      };
    }

    return ShowTitleStage;

  })(FSStage);

  GameStage = (function(_super) {
    var boxScale;

    __extends(GameStage, _super);

    function GameStage() {
      GameStage.__super__.constructor.apply(this, arguments);
      this.init = function() {
        var getElementPosition, ground, sabazusi, texture;
        getElementPosition = function(element) {
          return {
            x: element.offsetLeft,
            y: element.offsetTop
          };
        };
        this.canvasPosition = getElementPosition($('#pixistage')[0]);
        ground = new PIXIShapeBox(0x808080, 0x696969, WINDOW_WIDTH, 20);
        ground.position.x = 0;
        ground.position.y = 0;
        this.addChild(ground);
        ground = new PIXIShapeBox(0x808080, 0x696969, WINDOW_WIDTH, 20);
        ground.position.x = 0;
        ground.position.y = WINDOW_HEIGHT - 20;
        this.addChild(ground);
        texture = PIXI.Texture.fromImage('image/sabazusi.png');
        sabazusi = new PIXI.Sprite(texture);
        sabazusi.anchor.x = 0.5;
        sabazusi.anchor.y = 0.5;
        this.sabazusiSprite = sabazusi;
        return createFrameObject(generator, fixtureDef);
      };
      this.willAppear = function() {
        console.log("willAppear");
        this.lastTumble = {};
        this.lastTumble.upper = {
          body: void 0,
          size: 0
        };
        this.lastTumble.down = {
          body: void 0,
          size: 0
        };
        this.mouseX = void 0;
        this.mouseY = void 0;
        this.mouseXphys = void 0;
        this.mouseYphys = void 0;
        this.isMouseDown = false;
        this.mouseJoint = null;
        this.jampingTick = 0;
        this.inputTick = 0;
        this.generateTick = 0;
        this.sabazusiBody = void 0;
        game.touchdownFlg = false;
        this.score = 0;
        this.gameOverTick = fps * 0.8;
        this.goAwayTick = this.gameOverTick + fps * 0.5;
        this.goAwayFlg = false;
        this.sabazusiBody = createSabazusi(generator, fixtureDef);
        this.sabazusiBody.SetUserData({
          type: TYPE_SABA,
          renderObj: this.sabazusiSprite
        });
        return this.addChild(this.sabazusiSprite);
      };
      this.didDisappear = function() {
        var body, bodyData;
        console.log("reset");
        if (this.mouseJoint) {
          world.DestroyJoint(this.mouseJoint);
          this.mouseJoint = null;
        }
        body = world.GetBodyList();
        while (body) {
          bodyData = body.GetUserData();
          if ((bodyData != null)) {
            if (bodyData.type === TYPE_TUMBLE_BOX || bodyData.type === TYPE_TUMBLE_TRI || bodyData.type === TYPE_SABA) {
              if ((bodyData.renderObj != null)) {
                this.removeChild(bodyData.renderObj);
              }
              world.DestroyBody(body);
            }
          }
          body = body.GetNext();
        }
        return this.removeResultPanel();
      };
      this.update = function(currentState, keyCode) {
        var body, bodyData, mouseJointDef, obj, pos, sabaX, x;
        if (game.touchdownFlg) {
          if (!this.goAwayFlg) {
            if (this.gameOverTick === 0 && !this.goAwayFlg) {
              this.addResultPanel();
            }
            if (this.goAwayTick === 0) {
              this.goAwayFlg = true;
            }
            if (this.gameOverTick > 0) {
              this.gameOverTick--;
            }
            if (this.goAwayTick > 0) {
              this.goAwayTick--;
            }
          }
          if (this.goAwayFlg && keyCode === KEYCODE_SPACE) {
            return STAGE_TITLE;
          }
        } else {
          if (this.generateTick === 0) {
            this.generateTumble(generator, fixtureDef, this);
            this.generateTick = 1;
          }
          if (this.inputTick === 0 && this.jampingTick === 0 && keyCode === KEYCODE_SPACE && (!this.mouseJoint)) {
            this.jampingTick = fps * 0.2;
            this.inputTick = fps * 0.4;
            this.sabazusiBody.SetLinearVelocity(new b2Vec2(0, 0));
            pos = this.sabazusiBody.GetPosition();
            mouseJointDef = new b2MouseJointDef();
            mouseJointDef.bodyA = world.GetGroundBody();
            mouseJointDef.bodyB = this.sabazusiBody;
            mouseJointDef.target.Set(pos.x, pos.y);
            mouseJointDef.collideConnected = true;
            mouseJointDef.maxForce = 85.0 * this.sabazusiBody.GetMass();
            this.mouseJoint = world.CreateJoint(mouseJointDef);
            this.sabazusiBody.SetAwake(true);
            this.mouseJoint.SetTarget(new b2Vec2(pos.x, pos.y - 1.3));
          } else if (this.mouseJoint) {
            if (this.jampingTick === 0) {
              world.DestroyJoint(this.mouseJoint);
              this.mouseJoint = null;
            }
          }
          if (this.jampingTick > 0) {
            this.jampingTick--;
          }
          if (this.inputTick > 0) {
            this.inputTick--;
          }
          if (this.generateTick > 0) {
            this.generateTick--;
          }
          body = world.GetBodyList();
          while (body) {
            bodyData = body.GetUserData();
            if ((bodyData != null)) {
              obj = bodyData.renderObj;
              if ((obj != null)) {
                pos = body.GetPosition();
                obj.rotation = body.GetAngle();
                obj.position.x = Math.floor(pos.x * physScale);
                obj.position.y = Math.floor(pos.y * physScale);
                if (obj instanceof PIXIShapeBox) {
                  obj.position.x -= Math.floor(obj.width / 2);
                  obj.position.y -= Math.floor(obj.height / 2);
                }
              }
              if (bodyData.type === TYPE_TUMBLE_BOX || bodyData.type === TYPE_TUMBLE_TRI) {
                if (body.GetPosition().x < -2) {
                  this.removeChild(bodyData.renderObj);
                  world.DestroyBody(body);
                } else {
                  offsetGravity(body, new b2Vec2(-1.5, 0));
                  if (!bodyData.isChecked && bodyData.type === TYPE_TUMBLE_BOX) {
                    sabaX = Math.floor(this.sabazusiBody.GetPosition().x * physScale);
                    x = Math.floor(body.GetPosition().x * physScale) + bodyData.renderObj.width / 2;
                    if (x < sabaX) {
                      bodyData.isChecked = true;
                      this.score++;
                      playAudio("score");
                    }
                  }
                }
              }
            }
            body = body.GetNext();
          }
          world.Step(stepTime, stepVelocityIterations, stepPositionIterations);
          world.DrawDebugData();
          world.ClearForces();
        }
        return currentState;
      };
    }

    boxScale = [1, 1, 1, 2, 2, 2, 3, 3, 4, 5];

    GameStage.prototype.setupTriangleVecs = function() {
      var i, v, x, y, _i, _results;
      if ((this.triVecs != null)) {
        return;
      }
      this.triVecs = [];
      v = 3;
      _results = [];
      for (i = _i = 0; _i < 3; i = ++_i) {
        x = Math.cos(Math.PI * 2 / v * i);
        y = Math.sin(Math.PI * 2 / v * i);
        _results.push(this.triVecs.push({
          x: x,
          y: y
        }));
      }
      return _results;
    };

    GameStage.prototype.generateTumble = function(pGenerator, pFixtureDef, pStage) {
      var bodyDef, box, down, downRadius, g_vecs, gvec, height, i, scaleNum, size, triangle, upper, v, vec, vecs, width, x, y, _i;
      this.setupTriangleVecs();
      if (this.lastTumble.upper.body === void 0 || this.lastTumble.upper.body.GetPosition().x < (WINDOW_WIDTH - this.lastTumble.upper.size / 2) / physScale) {
        scaleNum = Math.floor(Math.random() * boxScale.length);
        size = boxScale[scaleNum] * 32;
        x = WINDOW_WIDTH + size / 2;
        y = size / 2 + WALL_HEIGHT;
        width = size / 2;
        height = size;
        upper = pGenerator.createDynamicBoxBody(pFixtureDef, x, y, width, height);
        box = new PIXIShapeBox(0x2f4f4f, 0x000000, width, height);
        upper.SetLinearVelocity(new b2Vec2(-1.5, 0));
        upper.SetUserData({
          type: TYPE_TUMBLE_BOX,
          renderObj: box,
          isChecked: false
        });
        this.lastTumble.upper.body = upper;
        this.lastTumble.upper.size = size;
        this.addChild(box);
      }
      if (this.lastTumble.down.body === void 0 || this.lastTumble.down.body.GetPosition().x < (WINDOW_WIDTH - this.lastTumble.down.size / 2) / physScale) {
        downRadius = Math.floor((Math.random() + 0.1) * (WINDOW_HEIGHT / 6)) + 32;
        v = 3;
        vecs = [];
        g_vecs = [];
        for (i = _i = 0; _i < 3; i = ++_i) {
          x = downRadius * this.triVecs[i].x;
          y = downRadius * this.triVecs[i].y;
          vec = new b2Vec2(x / physScale / 2, y / physScale / 2);
          gvec = [x / 2, y / 2];
          vecs.push(vec);
          g_vecs.push(gvec);
        }
        bodyDef = pGenerator.createDynamicBodyDef(WINDOW_WIDTH + downRadius, WINDOW_HEIGHT - downRadius / 2);
        pFixtureDef.shape = new b2PolygonShape();
        pFixtureDef.shape.SetAsArray(vecs, vecs.length);
        down = pGenerator.createBody(bodyDef, pFixtureDef);
        triangle = new PIXIShapePolygon(0x2f4f4f, 0x000000, downRadius, g_vecs);
        down.SetLinearVelocity(new b2Vec2(-1.5, 0));
        down.SetUserData({
          type: TYPE_TUMBLE_TRI,
          renderObj: triangle,
          isChecked: false
        });
        this.lastTumble.down.body = down;
        this.lastTumble.down.size = downRadius;
        return this.addChild(triangle);
      }
    };

    GameStage.prototype.addResultPanel = function() {
      var board, height, score, title, width;
      if ((this.resultPanel != null)) {
        return;
      }
      width = WINDOW_WIDTH * 0.6;
      height = WINDOW_HEIGHT / 2;
      board = new PIXIShapeBox(0xdcdcdc, 0x696969, width, height);
      board.position.x = (WINDOW_WIDTH - width) / 2;
      board.position.y = (WINDOW_HEIGHT - height) / 2;
      this.addChild(board);
      title = new PIXI.Text("RESULT", {
        font: "35px Desyrel",
        fill: "black",
        align: 'center'
      });
      title.width = WINDOW_WIDTH / 3;
      title.height = 35;
      title.position.x = (WINDOW_WIDTH - title.width) / 2;
      title.position.y = (WINDOW_HEIGHT - title.height) / 2 - 20;
      this.addChild(title);
      score = new PIXI.Text("Score: " + this.score, {
        font: "35px Desyrel",
        fill: "black",
        align: 'center'
      });
      score.width = WINDOW_WIDTH / 4;
      score.height = 35;
      score.position.x = (WINDOW_WIDTH - score.width) / 2;
      score.position.y = (WINDOW_HEIGHT - score.height) / 2 + 20;
      this.addChild(score);
      this.resultPanel || (this.resultPanel = {});
      this.resultPanel.back = board;
      this.resultPanel.title = title;
      return this.resultPanel.score = score;
    };

    GameStage.prototype.removeResultPanel = function() {
      if ((this.resultPanel != null)) {
        this.removeChild(this.resultPanel.back);
        this.removeChild(this.resultPanel.title);
        this.removeChild(this.resultPanel.score);
        return this.resultPanel = void 0;
      }
    };

    return GameStage;

  })(FSStage);

  handleKeyDown = function(e) {
    console.log(e.keyCode);
    return game.keyCode = e.keyCode;
  };

  $('body').keydown(handleKeyDown);

  onClickOrTap = function(e) {
    e.preventDefault();
    console.log("ClickOrTap");
    return game.keyCode = KEYCODE_SPACE;
  };

  $('body').mousedown(onClickOrTap);

  touchStarted = false;

  handleTouchEvent = function(e) {
    if (e.type === 'touchstart') {
      return touchStarted = true;
    } else if (e.type === 'touchmove') {
      return touchStarted = false;
    } else if (e.type === 'touchend') {
      onClickOrTap(e);
      return touchStarted = false;
    }
  };

  $('body').on('touchstart touchmove touchend', handleTouchEvent);

  showTitle = new ShowTitleStage();

  showTitle.init();

  flapping = new GameStage();

  flapping.init();

  getStage = function(stageState) {
    switch (stageState) {
      case STAGE_TITLE:
        return showTitle;
      case STAGE_FLAPPING:
        return flapping;
    }
    return void 0;
  };

  animate = function() {
    var prevState, stage;
    requestAnimFrame(animate);
    prevState = game.stageState;
    stage = getStage(game.stageState);
    game.stageState = stage.update(game.stageState, game.keyCode);
    if (game.stageState !== prevState) {
      stage = getStage(game.stageState);
      console.log("state changed", prevState, game.stageState);
      stage.didDisappear();
      stage.willAppear();
    }
    game.keyCode = 0;
    return renderer.render(stage);
  };

  requestAnimFrame(animate);

}).call(this);
