// (C) 2019 Sterling Parker (aka "Caligari87")
// This software is provided 'as-is', without any express or implied warranty. In no event will the authors be held liable for any damages arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose, including commercial applications, and to alter it and redistribute it freely, subject to the following restrictions:
//
// 	The origin of this software must not be misrepresented; you must not claim that you wrote the original software. If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.
// 	Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
// 	This notice may not be removed or altered from any source distribution.
//
// zlib License: https://opensource.org/licenses/Zlib
// Original source: https://gist.github.com/caligari87/daa5b127a3bc522794eb050067b5a95e

// ------------------------ //
// USER CONFIGURABLE VALUES //
// u_name = script uniforms //
// ------------------------ //

// Resolution reduction
// 4 = 1/4th screen resolution
int resfactor = u_resfactor;

// Enable horizontal and/or vertical scanlines
// scanstrength is thickness of lines (0 = none, 1.0 = stupid thicc)
bool hscan = bool(u_hscan);
bool vscan = bool(u_vscan);
int scanfactor = u_scanfactor;
float scanstrength = u_scanstrength * (u_scanfactor * 4.0);

// Posterization / palette filter
// This sets number of color levels
int posterize = u_posterize;

// Color filter
// Values are the relative strengths of the RGB channels
// Filter colors are normalized so don't worry about unbalanced values
// All zeros means greyscale / monochrome filter
// Whiteclip is how white the brightest areas are. This can be negative.
// Desat is the pre-filter monochromacity of the colors (usually this should be zero)
vec3 posfilter = normalize(u_posfilter); // primary NVG color (positive exposure)
vec3 negfilter = normalize(u_negfilter); // secondary NVG color (negative exposure)
float whiteclip = u_whiteclip;
float desat = u_desat;

// ----------------------------------- //
// USER CONFIGURABLE VALUES STOP HERE  //
// ----------------------------------- //

// Custom nitevision shader for HD by Caligari87
void main(){
	// copy exposure uniform
	float exp = max(abs(exposure), 1);

	// Limit resfactor and scanfactor
	resfactor = max(resfactor, 1);
	scanfactor = max(scanfactor, 1);

	// Downsample coordinate system
	vec2 res = TexCoord;
	res *= textureSize(InputTexture,0).xy / resfactor;
	res = vec2(int(res.x),int(res.y));
	res /= textureSize(InputTexture,0).xy / resfactor;

	// Get pixels
	vec3 color  = texture(InputTexture, res).rgb;

	// Desaturate and multiply
	color = mix(vec3(dot(color.rgb, vec3(0.56, 0.3, 0.14))), color.rgb, desat);
	color = atan(atan(color * exp)); // amplify by HD's original formula

	// Posterize
	color *= posterize;
	color.rgb = vec3(
		int(color.r),
		int(color.g),
		int(color.b));
	color /= posterize;

	// Clamp
	color = vec3(
		clamp(color.r, 0.0, 1.0),
		clamp(color.g, 0.0, 1.0),
		clamp(color.b, 0.0, 1.0));

	// Filter channels for preferred color
	if (exposure > 0) { color *= clamp(posfilter + (color * whiteclip), 0.0, 1.0); }
	if (exposure < 0) { color *= clamp(negfilter + (color * whiteclip), 0.0, 1.0); }

	// Scanlines
	if (scanfactor > 1) {
		color *= 1 - int(hscan) * pow((1.0/float(scanfactor)) * mod(TexCoord.y * textureSize(InputTexture,0).y, scanfactor), scanfactor / scanstrength);
		color *= 1 - int(vscan) * pow((1.0/float(scanfactor)) * mod(TexCoord.x * textureSize(InputTexture,0).x, scanfactor), scanfactor / scanstrength);
	}

	// Output
	FragColor = vec4(color, 1.0);
}
