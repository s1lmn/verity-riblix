"""Bake ten progression variants from the approved procedural skin recipes.
One sphere and sixteen shared skin images serve the whole 100-level progression.
"""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/verity-elemental/progression-skins'
OUT.mkdir(parents=True,exist_ok=True)
VARIANTS=[('AquaBloom','Aqua',2),('AquaCrest','Aqua',3),('FrostPrism','Frost',2),('FrostAurora','Frost',3),('MagmaBlaze','Magma',2),('MagmaCore','Magma',3),('CyberPulse','Cyber',2),('CyberOverdrive','Cyber',3),('CosmicNova','Cosmic',2),('CosmicNebula','Cosmic',3)]
recipe=(ROOT/'tools/build_verity_elemental.py').read_text().replace('t=(u-.5)*2*np.pi','t=u*2*np.pi')
recipe=recipe.replace("OUT/'skins'/f'{name}.png'","VARIANT_OUT/f'{VARIANT_ID}.png'")
insert='''
 # Sparse, broad new motifs per stage, leaving the emotion area clear.
 if VARIANT_TIER>=2:
  if name=='Aqua':
   c=sphere_stamp(c,(-.72,.55,-.66),.115,'bubble','E3FFFF')
   c=sphere_stamp(c,(.6,-.5,.8),.16,'bubble','9CFFF0')
  elif name=='Frost':
   c=sphere_stamp(c,(-.72,.52,-.6),.20,'snow','BFFAFF')
  elif name=='Magma':
   field=P@np.array([-.56,.58,-.59]);c=blend(c,'FFEF41',smooth(.965,.985,field)*.88)
   c=blend(c,'FFB000',smooth(.98,.995,field))
  elif name=='Cyber':
   emblem=(X<-.55)&(X>-.77)&(Y<-.25)&(Y>-.47)
   c=blend(c,'3DFFFF',emblem.astype(float))
  elif name=='Cosmic':
   c=sphere_stamp(c,(-.63,.63,-.65),.14,'star','C5FFFF')
 if VARIANT_TIER>=3:
  if name=='Aqua':
   c=sphere_stamp(c,(.73,-.32,-.65),.14,'bubble','CAFFEA')
  elif name=='Frost':
   c=sphere_stamp(c,(.63,-.55,-.65),.18,'snow','FFFFFF')
   c=blend(c,'BA89FF',smooth(.8,.95,P@np.array([.4,.75,.5]))*.4)
  elif name=='Magma':
   glow=1-smooth(.06,.16,abs(Y+.62+.09*np.sin(t*3)))
   c=blend(c,'FFE53B',glow*.85)
  elif name=='Cyber':
   emblem=(X>.58)&(X<.73)&(Y<-.42)&(Y>-.60)
   c=blend(c,'C0FF36',emblem.astype(float))
  elif name=='Cosmic':
   c=sphere_stamp(c,(.74,.1,-.65),.16,'star','FFF2A2')
'''
recipe=recipe.replace(' # Explicitly close the UV seam;',' # Explicitly close the UV seam;') if False else recipe
# Insertion point lives before conversion to uint8; all authored patterns are spherical.
recipe=recipe.replace(' # Explicitly close the UV seam;',insert+'\n # Explicitly close the UV seam;')
assert 'Sparse, broad new motifs' in recipe
ns={'__file__':str(ROOT/'tools/build_verity_elemental.py'),'__name__':'progression_bake','VARIANT_OUT':OUT}
exec(compile(recipe,'<progression-skin-recipe>','exec'),ns)
for id,family,tier in VARIANTS:
 ns.update(VARIANT_ID=id,VARIANT_TIER=tier);ns['make_skin'](family)
(OUT/'variants.json').write_text(json.dumps([{'id':id,'family':family,'tier':tier} for id,family,tier in VARIANTS],indent=2))
print('Baked10 shared progression textures,1024x512, using verified Roblox UVs; no geometry or facial art added.')
