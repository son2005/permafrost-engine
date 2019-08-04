/* *  This file is part of Permafrost Engine. 
 *  Copyright (C) 2019 Eduard Permyakov 
 *
 *  Permafrost Engine is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  Permafrost Engine is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 * 
 *  Linking this software statically or dynamically with other modules is making 
 *  a combined work based on this software. Thus, the terms and conditions of 
 *  the GNU General Public License cover the whole combination. 
 *  
 *  As a special exception, the copyright holders of Permafrost Engine give 
 *  you permission to link Permafrost Engine with independent modules to produce 
 *  an executable, regardless of the license terms of these independent 
 *  modules, and to copy and distribute the resulting executable under 
 *  terms of your choice, provided that you also meet, for each linked 
 *  independent module, the terms and conditions of the license of that 
 *  module. An independent module is a module which is not derived from 
 *  or based on Permafrost Engine. If you modify Permafrost Engine, you may 
 *  extend this exception to your version of Permafrost Engine, but you are not 
 *  obliged to do so. If you do not wish to do so, delete this exception 
 *  statement from your version.
 *
 */

#version 330 core

#define WAVE_STRENGTH   (0.005)
#define WATER_TINT_CLR  vec4(0.0, 0.3, 0.5, 0.1)

#define SPECULAR_STRENGTH  0.15
#define SPECULAR_SHININESS 0.8

/*****************************************************************************/
/* INPUTS                                                                    */
/*****************************************************************************/

in VertexToFrag {
    vec4 clip_space_pos;
    vec2 uv;
    vec3 view_dir;
    vec3 light_dir;
}from_vertex;

/*****************************************************************************/
/* OUTPUTS                                                                   */
/*****************************************************************************/

out vec4 o_frag_color;

/*****************************************************************************/
/* UNIFORMS                                                                  */
/*****************************************************************************/

uniform sampler2D water_dudv_map;
uniform sampler2D water_normal_map;
uniform sampler2D refraction_tex;
uniform sampler2D reflection_tex;

uniform float water_move_factor;

uniform vec3 light_color;

/*****************************************************************************/
/* PROGRAM                                                                   */
/*****************************************************************************/

void main()
{
    vec2 ndc_pos = (from_vertex.clip_space_pos.xy / from_vertex.clip_space_pos.w)/2.0 + 0.5;

    vec2 distorted_uv = vec2(from_vertex.uv.x + water_move_factor, from_vertex.uv.y);
    distorted_uv = texture(water_dudv_map, distorted_uv).rg * 0.1;
    distorted_uv = from_vertex.uv + vec2(distorted_uv.x, distorted_uv.y + water_move_factor);
    vec2 tot_dist = (texture(water_dudv_map, distorted_uv).rg * 2.0 - 1.0) * WAVE_STRENGTH;

    vec2 refract_uv = clamp(ndc_pos + tot_dist, 0.001, 0.999);
    vec4 refract_clr = texture(refraction_tex, refract_uv);

    vec2 reflect_uv = vec2(ndc_pos.x, -ndc_pos.y) + tot_dist;
    reflect_uv.x = clamp(reflect_uv.x, 0.001, 0.999);
    reflect_uv.y = clamp(reflect_uv.y, -0.999, -0.001);
    vec4 reflect_clr = texture(reflection_tex, reflect_uv);

    vec4 norm_map_clr = texture(water_normal_map, distorted_uv);
    vec3 normal = vec3(norm_map_clr.r * 2.0 - 1.0, norm_map_clr.b, norm_map_clr.g * 2.0 - 1.0);

    vec3 reflect_dir = reflect(-from_vertex.light_dir, normal);
    float spec = pow(max(dot(from_vertex.view_dir, reflect_dir), 0.0), SPECULAR_SHININESS);
    vec3 specular = SPECULAR_STRENGTH * spec * light_color;

    o_frag_color = mix(refract_clr, reflect_clr, 0.5);
    o_frag_color = mix(o_frag_color, WATER_TINT_CLR, 0.1) + vec4(specular, 0.0);
}
