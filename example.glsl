#[compute]
#version 450

//Tell the gpu how many threads we need
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

//make a buffr to hold our mouse position, 
//we read only, and only acces the memory directly so we use restrict_
layout(set = 0, binding = 0, std430) restrict readonly buffer mousePostion {
    int x;
    int y;
}
mouseposition;

//We make a texture uniform_, again we only use the memory directly so we use restrict_
layout(set = 0, binding = 1, r32f) uniform restrict image2D texture;


//Lets define a helper function to keep the code clean
float length_squared(ivec2 v){
    return v.x*v.x+v.y*v.y;
}

//our main function, this is what gets excecuted
void main() {

    //First we set some variables
    ivec2 UV = ivec2(gl_GlobalInvocationID.xy);
    ivec2 mouse = ivec2(mouseposition.x,mouseposition.y);
    float storecolor = imageLoad(texture, UV).r;
    float lSquared = length_squared(UV-mouse);

    //We fade the color
    storecolor *= 0.99;

    //We check whether or not the pixel is inside the cirkel. 
    //If it is, we fade it quadraticly based on distance
    //We make sure to set the storecolor to the highest possible value!
    if (lSquared < 25*25){
        float storev = sqrt(1.0-((lSquared)*0.0016));
        storecolor = max(storecolor, storev);
    }

    //We store our colour
    imageStore(texture, UV, vec4(storecolor, storecolor, storecolor, 1));
}