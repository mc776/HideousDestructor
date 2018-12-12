void main(){
	vec3 colour = texture( InputTexture, TexCoord ).rgb;
	colour = mix(vec3(dot(colour.rgb, vec3(0.3,0.56,0.14))), colour.rgb, 0.00);
	FragColor = vec4(colour.r * 2.4, colour.g * 6.2, colour.b * 2.4, 1.0);
}
