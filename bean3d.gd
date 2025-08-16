##-------------------------##
#This is a demo to showcase what the "painting" tutorial can be used for
#For extensive comments, visit the main painting demo
##------------------------##


extends Node3D

var texture_rd:Texture2DRD

var rd:RenderingDevice
var shader_file
var shader
var pipeline
var buffer:RID= RID()
var uniform_set
var buffer_uniform
var tex_uniform
var v_tex:RID = RID()
var format


func _ready():
	RenderingServer.call_on_render_thread(render_ready)
	

func _process(delta:float) -> void:
	
	##instead of the mouse position we use the bean position 
	var event_position:Vector3 = $bean.global_position
	var pos2f:Vector2 = (Vector2(event_position.x,event_position.z) + Vector2(1,1))*0.5
	var pos2 :Vector2i = Vector2i(pos2f*512)
	var bufferN:= PackedInt32Array([pos2.x,pos2.y]).to_byte_array()
	
	RenderingServer.call_on_render_thread(render_process.bind(bufferN))
	
	##A very simple controller for the bean
	if Input.is_action_pressed("ui_right"):
		$bean.global_position += Vector3(0.6*delta,0,0)
	if Input.is_action_pressed("ui_left"):
		$bean.global_position += Vector3(-0.6*delta,0,0)
	if Input.is_action_pressed("ui_up"):
		$bean.global_position += Vector3(0,0,-0.6*delta)
	if Input.is_action_pressed("ui_down"):
		$bean.global_position += Vector3(0,0,0.6*delta)
	
func _exit_tree() -> void:
	rd.free_rid(buffer)
	rd.free_rid(pipeline)
	rd.free_rid(shader)
	rd.free_rid(v_tex)
	rd.free()

func render_ready():
	rd = RenderingServer.get_rendering_device()
	
	shader_file = load("res://example.glsl")
	shader = rd.shader_create_from_spirv(shader_file.get_spirv())

	var bufferN: =PackedInt32Array([0,0]).to_byte_array()
	buffer = rd.storage_buffer_create(bufferN.size(), bufferN)

	buffer_uniform = RDUniform.new()
	buffer_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	buffer_uniform.binding = 0 
	buffer_uniform.add_id(buffer)
	
	format = RDTextureFormat.new()
	format.width = 512
	format.height = 512
	format.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT + RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT + RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT + RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
	format.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	
	var image:=Image.create_empty(512,512,false,Image.FORMAT_RF)
	image.fill(Color(0.0,0.0,0.0,1.0))
	
	v_tex = rd.texture_create(format, RDTextureView.new(), [image.get_data()])
	tex_uniform = RDUniform.new()
	tex_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	tex_uniform.binding = 1
	tex_uniform.add_id(v_tex)
	
	uniform_set = rd.uniform_set_create([buffer_uniform, tex_uniform], shader, 0) 
	
	pipeline = rd.compute_pipeline_create(shader)
	
	texture_rd = Texture2DRD.new()
	texture_rd.texture_rd_rid = v_tex
	$MeshInstance3D.get_material_override().set_shader_parameter("effect_texture", texture_rd)

func render_process(bufferN):
	rd.buffer_update(buffer, 0, bufferN.size(), bufferN)
	
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, 64, 64, 1)
	rd.compute_list_end()
