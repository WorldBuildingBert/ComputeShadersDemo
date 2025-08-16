##----------------------##
#This is a demo to show the effectiveness of textures to store envirenment data
#For extra documentation visit the main scene
##----------------------##

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

	
func _exit_tree() -> void:
	rd.free_rid(buffer)
	rd.free_rid(pipeline)
	rd.free_rid(shader)
	rd.free_rid(v_tex)
	rd.free()

func render_ready():
	rd = RenderingServer.get_rendering_device()
	
	shader_file = load("res://cleanExample.glsl")
	shader = rd.shader_create_from_spirv(shader_file.get_spirv())

	var bufferN: =PackedInt32Array([0,0]).to_byte_array()
	buffer = rd.storage_buffer_create(bufferN.size(), bufferN)

	buffer_uniform = RDUniform.new()
	buffer_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	buffer_uniform.binding = 0 
	buffer_uniform.add_id(buffer)
	
	format = RDTextureFormat.new()
	format.width = 1024
	format.height = 1024
	format.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT + RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT + RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT + RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
	format.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	
	var image:=Image.create_empty(1024,1024,false,Image.FORMAT_RF)
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
	$box.get_material_override().set_shader_parameter("effect_texture", texture_rd)

func render_process(bufferN):
	rd.buffer_update(buffer, 0, bufferN.size(), bufferN)
	
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, 128, 128, 1)
	rd.compute_list_end()


##All we need to add to the basic script is this function, were we use a hacky way to turn a global hit position 
##into a UV position.
##There are a lot better ways to do this, but for this simple example this works fine
func hit(pos:Vector3):
	var pos3f:Vector3 = (pos-$box.global_position+Vector3(2,2,2))/Vector3(4,4,4)
	var pos2f:Vector2
	var face:Vector2
	if pos3f.x > 0.98:
		pos2f = Vector2(1-pos3f.z,pos3f.y)
		face = Vector2(1,0) 
	elif pos3f.x < 0.02:
		pos2f = Vector2(pos3f.z, pos3f.y)
		face = Vector2(0,1) 
	elif pos3f.z < 0.02:
		pos2f = Vector2(1-pos3f.x, pos3f.y)
		face = Vector2(2,0) 
	elif pos3f.z > 0.98:
		pos2f = Vector2(pos3f.x, pos3f.y)
		face = Vector2(0,0) 
	
	pos2f = Vector2(pos2f.x,1-pos2f.y)
	pos2f /= Vector2(3,2)

	pos2f += face/Vector2(3,2)
	var pos2 :Vector2i = Vector2i(pos2f*1024)
	var bufferN:= PackedInt32Array([pos2.x,pos2.y]).to_byte_array()
	
	RenderingServer.call_on_render_thread(render_process.bind(bufferN))
