extends RefCounted
## Actual manual failure plus explicit lifecycle boundaries; no motion/score forcing.
const MainScene=preload("res://game/main.tscn")
const Classic=preload("res://tests/classic_tricks_integration_tests.gd")
const Limbs=preload("res://tests/limb_pose_tests.gd")
class Probe extends Node:
	var rider:CharacterBody3D
	var phases:Array[String]=[]
	var active:=true
	var samples:=0
	var maximum_step:=0.0
	var previous:Vector3
	var minimum_z:=INF
	func _ready()->void:
		process_physics_priority=100;previous=rider.global_position
	func _physics_process(_delta:float)->void:
		if not active:return
		maximum_step=maxf(maximum_step,previous.distance_to(rider.global_position))
		previous=rider.global_position;minimum_z=minf(minimum_z,rider.global_position.z);samples+=1
		if rider.bailing and (phases.is_empty() or phases[-1]!=rider.bail_phase):phases.append(rider.bail_phase)
static func run(tree:SceneTree,check:Callable)->void:
	Classic._release()
	var game=MainScene.instantiate();game.persistence_enabled=false;tree.root.add_child(game)
	game.start_mode(true);await _frames(tree,60)
	var bails:Array=[];var ready:Array=[];var awards:Array[String]=[]
	game.skater.bailed.connect(func():bails.append({'at':game.skater.global_position,'tick':Engine.get_physics_frames()}))
	game.skater.recovered.connect(func():ready.append(Engine.get_physics_frames()))
	game.skater.trick_performed.connect(func(id:String,_points:int):awards.append(id))
	var run_spawn:Vector3=game.skater.spawn_position
	var probe:=Probe.new();probe.rider=game.skater;tree.root.add_child(probe)
	var limbs:=Limbs.Probe.new();limbs.rider=game.skater;tree.root.add_child(limbs)
	Input.action_press('push');await _frames(tree,45);Input.action_release('push')
	var earned:int=game.score.total_score
	Classic._key(KEY_M,true)
	for tick in 400:
		await _frames(tree,1)
		if game.skater.bailing:break
	check.call(bails.size()==1 and game.skater.bailing and not game.skater.manual_active and game.skater.global_position.distance_to(bails[0].at)<.25,
		'recovery: actual uncorrected manual enters one local fall without a spawn snap')
	check.call(game.skater._board_model.get_parent()==game.skater._loose_board and not game.skater._loose_board.freeze and game.skater._loose_board.linear_velocity.length()>1.0 and game.skater._loose_board.angular_velocity.length()>1.0,
		'recovery: real failure detaches the existing board into native translation and tumble')
	var dropped_at:Vector3=game.skater._loose_board.global_position
	var wall:=StaticBody3D.new();var collision:=CollisionShape3D.new();var box:=BoxShape3D.new()
	box.size=Vector3(3,3,.15);collision.shape=box;wall.add_child(collision)
	wall.position=game.skater.global_position+Vector3(0,1.5,-.8);game.world.add_child(wall)
	Input.action_press('ollie');Input.action_press('flip');Input.action_press('grab');Input.action_press('grind')
	check.call(not game.skater.try_special('special_clyde_carousel'),'recovery: special admission is refused during a fall')
	game.skater.recover_to(Vector3(-18,.8,28))
	check.call(bails.size()==1 and game.skater.global_position.distance_to(bails[0].at)<.25,'recovery: repeated recovery requests coalesce without relocation or another failure')
	game.toggle_pause()
	var paused_at:Vector3=game.skater.global_position;var paused_age:float=game.skater.bail_elapsed
	var paused_board:Transform3D=game.skater._loose_board.global_transform
	await _frames(tree,12)
	check.call(game.skater.global_position==paused_at and game.skater.bail_elapsed==paused_age and game.skater._loose_board.global_transform==paused_board,'recovery: scene pause freezes native motion and recovery clocks')
	game.toggle_pause()
	for tick in 240:
		await _frames(tree,1)
		if not game.skater.bailing:break
	check.call(not game.skater.bailing and ready.size()==1 and probe.phases==['fall','slide','get_up','ready'],
		'recovery: supported fall/slide/get-up/board-ready completes once in order')
	check.call(probe.maximum_step<.3 and probe.minimum_z>=wall.position.z+.075+.28-.04 and game.skater.is_on_floor(),
		'recovery: actual slide remains supported and cannot cross solid scenery')
	check.call(game.score.total_score==earned and game.score.get_combo_value()==0 and awards==['Manual'] and bails.size()==1,
		'recovery: one failure loses only pending points and held tricks cannot score or postpone recovery')
	check.call(game.skater._loose_board.freeze and game.skater._board_model.get_parent()==game.skater._board_visual and game.skater._board_model.transform==Transform3D.IDENTITY and game.skater._loose_board.global_position.distance_to(dropped_at)>.15 and game.skater._loose_board.global_position.y>-.1,
		'recovery: loose board moves against world collision, then is reclaimed once with native motion frozen')
	check.call(limbs.maximum_length_error<.01 and limbs.finite,'recovery: fall and get-up keep finite authored limb lengths')
	print('BAIL_RECOVERY phases=',probe.phases,' max_step_m=',probe.maximum_step,' elapsed=',game.skater.bail_elapsed,' length_error=',limbs.maximum_length_error,' bails=',bails.size(),' ready=',ready.size())
	probe.active=false;wall.queue_free();Classic._release();await _frames(tree,3)
	check.call(not game.skater.airborne and awards==['Manual'] and game.skater.spawn_position==run_spawn,
		'recovery: releasing held ollie after recovery cannot launch and run spawn is preserved')
	Input.action_press('ollie');await _frames(tree,24);Input.action_release('ollie');await _frames(tree,2)
	check.call(game.skater.airborne and awards.count('Ollie')==1,'recovery: a fresh charged release works after board-ready')
	await _frames(tree,90)
	game.skater.begin_bail('restart_boundary');game.restart_run()
	check.call(not game.skater.bailing and game.skater.global_position==run_spawn and game.score.get_combo_value()==0,
		'recovery: explicit Restart immediately cancels the sequence and restores the original run')
	await _frames(tree,60)
	var failures:=bails.size();var target:=Vector3(-18,.8,28)
	game.skater.recover_to(target);game.skater.recover_to(Vector3(50,.8,28))
	check.call(bails.size()==failures+1 and game.skater.global_position==target and game.skater.spawn_position==run_spawn,
		'recovery: a validated hazard return uses its destination once without replacing run spawn')
	await _frames(tree,150)
	check.call(not game.skater.bailing and game.skater.is_on_floor(),'recovery: hazard relocation physically lands and completes recovery')
	failures=bails.size();game.skater.recover_to(Vector3(NAN,0,0))
	check.call(bails.size()==failures and not game.skater.bailing,'recovery: invalid hazard destinations do not start or relocate a bail')
	game.skater.begin_bail('clearance_boundary');await _frames(tree,25)
	var ceiling:=StaticBody3D.new();var cap:=CollisionShape3D.new();var slab:=BoxShape3D.new()
	slab.size=Vector3(8,.1,8);cap.shape=slab;ceiling.add_child(cap)
	ceiling.position=game.skater.global_position+Vector3.UP*1.55;game.world.add_child(ceiling)
	await _frames(tree,55)
	check.call(game.skater.bailing and game.skater.bail_phase=='slide','recovery: get-up waits when actual upright headroom is obstructed')
	await _frames(tree,240)
	check.call(game.skater.bailing and game.skater.bail_phase=='blocked' and game.skater.global_position.is_finite() and game._feedback.contains('RESTART'),'recovery: unavailable fallback stays finite, refuses invalid relocation and exposes Restart')
	ceiling.queue_free();await _frames(tree,150)
	check.call(not game.skater.bailing and game.skater.is_on_floor(),'recovery: cleared headroom allows the same failure to finish')
	game.start_mode(false);await _frames(tree,45);game.skater.begin_bail('expiry_boundary')
	game.time_remaining=.01;await _frames(tree,3)
	check.call(game.run_finished and game.score.get_combo_value()==0,'recovery: career expiry cannot gain overtime from a failed combo')
	game.restart_run();check.call(not game.skater.bailing and not game.run_finished,'recovery: Restart also cancels a frozen results-screen fall')
	Classic._release();probe.queue_free();limbs.queue_free();game.queue_free();await tree.process_frame
static func _frames(tree:SceneTree,count:int)->void:
	for tick in count:
		await tree.physics_frame;await tree.process_frame;await tree.create_timer(0.0).timeout
