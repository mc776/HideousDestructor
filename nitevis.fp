void main(){
	vec3 colour = texture( InputTexture, TexCoord ).rgb;
	colour = mix(vec3(dot(colour.rgb, vec3(0.56,0.3,0.14))), colour.rgb, 0.00);
	float exp=exposure;
	if(exp<0){
		exp=abs(exp);
		colour.r=atan(atan(colour.r*exp));
		colour.g=0;
	}else{
		colour.r=0;
		colour.g=atan(atan(colour.g*exp));
	}
	FragColor = vec4(colour.r,colour.g,0,1.);
}
