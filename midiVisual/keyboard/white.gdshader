shader_type canvas_item;
uniform sampler2D noise:source_color;
uniform float yMulti;
uniform bool show = false;
uniform float showTime = 10.;
uniform float changer :hint_range(-1., 1.0);
uniform vec4 edgeColor : source_color;
uniform sampler2D edgeColorMap : source_color;
uniform float edgeWidth :hint_range(0,1.) = .3;
//uniform sampler2D edgeColor:source_color;

void fragment() {
	vec2 uv = vec2(UV.x/15. ,UV.y/4.);
	
	float map = 1.-texture(noise,uv).r;
	COLOR.a = clamp(smoothstep(0.-changer,1.-changer,map),0.,1.);
	float mixColor = clamp(1.0-smoothstep(0.5-changer,.5+edgeWidth-changer,map),0.,1.);
	vec4 colorMap = texture(edgeColorMap,vec2(mixColor,0));
	COLOR.rgba = mixColor*colorMap.rgba+(1.0-mixColor)*COLOR;
	COLOR.a *= uv.y;

	
//	float mixColor = smoothstep(1.-changer,1.,map);
//	COLOR.r = 1.-mixColor;
//	COLOR.rgb = mixColor*edgeColor.rgb+(1.0-mixColor)*COLOR.rgb;
	
	
	
}
