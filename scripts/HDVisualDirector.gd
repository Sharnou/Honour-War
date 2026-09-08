class_name HDVisualDirector
extends Node3D

# Honour War HD presentation layer.
# Production assets are authored in Blender, textured in Substance 3D Painter,
# then imported into Godot as GLB/GLTF. This director owns the real-time
# Forward+ presentation layer while gameplay remains in the existing systems.

var environment:Environment
var world_environment:WorldEnvironment
var sun:DirectionalLight3D
var rim:DirectionalLight3D
var fill:OmniLight3D
var time:float = 0.0

func _ready() -> void:
	call_deferred("_build_hd_presentation")

func _process(delta:float) -> void:
	time += delta
	if fill != null:
		fill.light_energy = 1.35 + sin(time * 0.55) * 0.10

func _build_hd_presentation() -> void:
	if not is_inside_tree():
		return
	_build_environment()
	_build_lights()
	_build_atmosphere()

func _build_environment() -> void:
	world_environment = get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_environment == null:
		world_environment = WorldEnvironment.new()
		world_environment.name = "WorldEnvironment"
		add_child(world_environment)
	environment = world_environment.environment
	if environment == null:
		environment = Environment.new()
		world_environment.environment = environment
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#08131f")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#a9c5dc")
	environment.ambient_light_energy = 0.82
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_BG
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	# Forward+ quality layer: use these features only on the production renderer.
	environment.ssao_enabled = true
	environment.ssao_radius = 2.2
	environment.ssao_intensity = 2.0
	environment.ssil_enabled = true
	environment.ssil_radius = 5.0
	environment.ssil_intensity = 1.15
	environment.glow_enabled = true
	environment.glow_intensity = 0.85
	environment.glow_bloom = 0.16
	environment.glow_hdr_threshold = 1.0
	environment.glow_hdr_scale = 1.25
	environment.fog_enabled = true
	environment.fog_light_color = Color("#8ca9bd")
	environment.fog_light_energy = 0.38
	environment.fog_density = 0.008
	environment.fog_height = 1.5
	environment.fog_height_density = 0.018
	environment.volumetric_fog_enabled = true
	environment.volumetric_fog_density = 0.006
	environment.volumetric_fog_albedo = Color("#9ab7cc")
	environment.volumetric_fog_emission = Color("#102234")
	environment.volumetric_fog_emission_energy = 0.08
	environment.volumetric_fog_length = 48.0
	environment.volumetric_fog_detail_spread = 1.6
	environment.sdfgi_enabled = true
	environment.sdfgi_cascades = 4
	environment.sdfgi_min_cell_size = 0.2
	environment.sdfgi_max_distance = 64.0
	environment.sdfgi_energy = 1.0

func _build_lights() -> void:
	sun = get_node_or_null("HDSun") as DirectionalLight3D
	if sun == null:
		sun = DirectionalLight3D.new()
		sun.name = "HDSun"
		add_child(sun)
	sun.rotation_degrees = Vector3(-48.0, -35.0, 0.0)
	sun.light_energy = 1.45
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	sun.directional_shadow_fade_start = 0.82
	sun.light_angular_distance = 0.10

	rim = get_node_or_null("HDRim") as DirectionalLight3D
	if rim == null:
		rim = DirectionalLight3D.new()
		rim.name = "HDRim"
		add_child(rim)
	rim.rotation_degrees = Vector3(-25.0, 145.0, 0.0)
	rim.light_energy = 0.52
	rim.light_color = Color("#75b8e8")
	rim.shadow_enabled = false

	fill = get_node_or_null("HDFill") as OmniLight3D
	if fill == null:
		fill = OmniLight3D.new()
		fill.name = "HDFill"
		add_child(fill)
	fill.position = Vector3(4.0, 7.0, 7.0)
	fill.omni_range = 30.0
	fill.light_energy = 1.35
	fill.light_color = Color("#b8dcf5")
	fill.shadow_enabled = true

func _build_atmosphere() -> void:
	var atmosphere:WorldEnvironment = world_environment
	if atmosphere == null:
		return
	var volume:GPUParticles3D = get_node_or_null("AtmosphericParticles") as GPUParticles3D
	if volume != null:
		return
	volume = GPUParticles3D.new()
	volume.name = "AtmosphericParticles"
	volume.amount = 120
	volume.lifetime = 7.0
	volume.randomness = 0.8
	volume.visibility_aabb = AABB(Vector3(-35.0, -1.0, -25.0), Vector3(70.0, 22.0, 50.0))
	var process_material:ParticleProcessMaterial = ParticleProcessMaterial.new()
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(28.0, 8.0, 20.0)
	process_material.direction = Vector3(0.05, 0.22, 0.03)
	process_material.spread = 25.0
	process_material.initial_velocity_min = 0.10
	process_material.initial_velocity_max = 0.35
	process_material.gravity = Vector3(0.0, 0.01, 0.0)
	process_material.scale_min = 0.015
	process_material.scale_max = 0.045
	volume.process_material = process_material
	var draw_pass:SphereMesh = SphereMesh.new()
	draw_pass.radius = 0.035
	draw_pass.height = 0.07
	draw_pass.radial_segments = 6
	draw_pass.rings = 3
	var material:StandardMaterial3D = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.75, 0.90, 1.0, 0.18)
	material.emission_enabled = true
	material.emission = Color("#8fd5ff")
	material.emission_energy_multiplier = 0.7
	draw_pass.material = material
	volume.draw_pass_1 = draw_pass
	add_child(volume)
