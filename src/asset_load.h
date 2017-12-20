#ifndef ASSET_LOAD_H
#define ASSET_LOAD_H

#include <stddef.h>


#define MAX_ANIM_SETS 16
#define MAX_LINE_LEN  256

struct entity;

struct pfobj_hdr{
    float    version; 
    unsigned num_verts;
    unsigned num_joints;
    unsigned num_materials;
    unsigned num_as;
    unsigned frame_counts[MAX_ANIM_SETS];
};

struct entity *AL_EntityFromPFObj(const char *base_path, const char *pfobj_name, const char *name);

#endif