void main(){
	vec3 colour = texture( InputTexture, TexCoord ).rgb;
	colour.r=max(colour.r,colour.g);
	colour.g=colour.r;
	FragColor = vec4(colour.r,colour.g,colour.b,1.);
}
