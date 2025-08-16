extends Node2D

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
	#We want to initialize on the rendering thread since we our working with the main rendering device
	#this line simply executes the function render_ready, but in a different thread
	RenderingServer.call_on_render_thread(render_ready)

func _process(_delta: float) -> void:
	
	##We get the mouse position each frame and convert it to a byte array
	var pos2:Vector2i = get_local_mouse_position()-($Sprite2D.position*0.5)
	var bufferN: =PackedInt32Array([pos2.x,pos2.y+100]).to_byte_array()
	
	##We excecute the following function on the render thread
	RenderingServer.call_on_render_thread(render_process.bind(bufferN))


##NEVER FORGET TO CLEAN UP AFTER USING RIDS
func _exit_tree() -> void:
	rd.free_rid(buffer)
	rd.free_rid(pipeline)
	rd.free_rid(v_tex)
	rd.free_rid(shader)
	rd.free()
##------------------------------------------------------------------------------------##
##THESE FUNCTIONS run on the rendering thread to be safe

#We set as many variables as possible in a cache, because these are too heavy to make each frame
func render_ready():
	##Since we are using texture2dRD we cannot work in a local rendering device and we have to use the main thread
	rd = RenderingServer.get_rendering_device()
	
	shader_file = load("res://example.glsl")
	shader = rd.shader_create_from_spirv(shader_file.get_spirv())
	
	#We create our mouse position buffer (for frame 1 consider the mouse to be at 0,0)
	#Buffers need to be in byte arrays
	var bufferN: =PackedInt32Array([0,0]).to_byte_array()
	buffer = rd.storage_buffer_create(bufferN.size(), bufferN)

	#We need to tell the gpu that this buffer is a uniform, so we make a uniform variable
	buffer_uniform = RDUniform.new()
	buffer_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	#binding refers to the memory plays, make sure this and the binding in the shader line up!
	buffer_uniform.binding = 0 
	buffer_uniform.add_id(buffer)
	
	
	#before we can make a texture we need to set the format for the texture
	#this format is stored in our variable
	format = RDTextureFormat.new()
	format.width = 512
	format.height = 512
	format.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT + RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT + RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT + RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
	#this needs to line up with our image format
	format.format = RenderingDevice.DATA_FORMAT_R32_SFLOAT
	
	var image:=Image.create_empty(512,512,false,Image.FORMAT_RF)
	image.fill(Color(0.0,0.0,0.0,1.0))
	
	#here we make our texture
	v_tex = rd.texture_create(format, RDTextureView.new(), [image.get_data()])
	#once again we need a uniform, this is very similair to the buffer uniform except for the uniform type
	tex_uniform = RDUniform.new()
	tex_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	tex_uniform.binding = 1
	tex_uniform.add_id(v_tex)
	
	#A uniform set allows us to push multiple uniforms at the same time to the gpu
	#This is also were we can change the "set" variable in the shader by changing the last 0
	uniform_set = rd.uniform_set_create([buffer_uniform, tex_uniform], shader, 0) 
	
	#Rendering needs a pipeline we can initialize here already
	pipeline = rd.compute_pipeline_create(shader)
	
	#Now we simply make the texture2drd and setting it to be the image used by the sprite
	texture_rd = Texture2DRD.new()
	texture_rd.texture_rd_rid = v_tex
	$Sprite2D.texture = texture_rd

func render_process(bufferN):
	rd.buffer_update(buffer, 0, bufferN.size(), bufferN)
	
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	#We dispatch 64 groups since our texture is 512x512 and the gpu runs 8x8
	rd.compute_list_dispatch(compute_list, 64, 64, 1)
	rd.compute_list_end()
	
