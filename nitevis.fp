void main(){
	vec3 colour = texture( InputTexture, TexCoord ).rgb;
	colour = mix(vec3(dot(colour.rgb, vec3(0.3,0.56,0.14))), colour.rgb, 0.25);
	FragColor = vec4(colour.r * 15.0, colour.g * 40.0, colour.b * 15.0, 1.0);
}