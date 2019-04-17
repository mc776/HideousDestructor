void main(){
	if(
		int(TexCoord.y*5000)%2==0
		&&TexCoord.y>0
	){
		vec2 texCoord2 = TexCoord.st;
		vec2 offset=vec2(0.,-0.0002);
		texCoord2+=offset;
		vec3 colour=texture(InputTexture,texCoord2).rgb;
		if(exposure>0)colour.r=0.;else colour.g=0.;
		FragColor=vec4(colour.r,colour.g,0,0.9);
		return;
	}
	vec3 colour = texture( InputTexture, TexCoord ).rgb;
	colour = mix(vec3(dot(colour.rgb, vec3(0.56,0.3,0.14))), colour.rgb, 0.00);
	float exp=exposure;
	if(exp<0){
		exp=abs(exp);
		colour.r=clamp(atan(atan(colour.r*exp)),0.,1.);
		colour.g=0;
	}else{
		colour.r=0;
		colour.g=atan(atan(colour.g*exp));
	}
	FragColor = vec4(colour.r,colour.g,0,1.);
}
