vec3 Tonemap( vec3 color )
{
	ivec3 c		= ivec3( clamp( color, vec3( 0.0 ), vec3( 1.0 )) * 255.0 + 0.5 );
	int index	= ((( c.r << 8 ) + c.g ) << 8 ) + c.b;
	int	tx		= index % 4096 ;
	int ty		= index >> 12 ;
	
	return texelFetch( LUT, ivec2( tx, ty ), 0 ).rgb ;
}

void main()
{
	vec3 colour	= texture( InputTexture, TexCoord ).rgb;
	FragColor = vec4( Tonemap( colour ), 1.0);
}