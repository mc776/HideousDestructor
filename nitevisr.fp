void main(){
	vec3 colour = texture( InputTexture, TexCoord ).rgb;
	colour = mix(vec3(dot(colour.rgb, vec3(0.3,0.56,0.14))), colour.rgb, 0.00);
	FragColor = vec4(colour.r * 6.2, colour.g * 0.8, colour.b * 0.8, 1.4);
}
