#!/usr/bin/env python3
"""Fetch/verify pinned CC0 Merchant PBR maps. --verify-only never writes/network."""
from __future__ import annotations
import sys
sys.dont_write_bytecode=True
import argparse,datetime,hashlib,json,re,urllib.request
from pathlib import Path
from fetch_environment_materials import ROOT,apply_import_policy,jpeg_dimensions,IMPORT_POLICY
DEST=ROOT/'game/art/assets/merchant_pbr'
ASSETS={'concrete_floor_worn_001':{'creator':'Dimitrios Savva (Photography); Rico Cilliers (Processing)','tile_size_m':3.0,'published_size_mm':[3000,3000.000238418579]},'granite_tile':{'creator':'Charlotte Baglioni','tile_size_m':2.3,'published_size_mm':[2299.999952316284,2299.999952316284]}}
CHANNELS={'albedo':'Diffuse','normal_opengl':'nor_gl','arm':'arm'}
HEADERS={'User-Agent':'TamHawksMaterialResearch/1.0 (source and license inspection)'}
def sha(data):return hashlib.sha256(data).hexdigest()
def policy():return {'mipmaps':True,'filter':'linear anisotropic','maximum_dimension_by_map':{'albedo':2048,'normal_opengl':1024,'arm':1024},'desktop_vram_compression':IMPORT_POLICY['desktop_vram_compression'],'new_bound_map_count':6,'predicted_extra_payload_bytes':9786816,'new_texture_ceiling_bytes':9786816,'combined_additional_texture_ceiling_mib':32,'colour_semantics':{'albedo':'sRGB/source_color','normal_opengl':'linear +Y; reconstruct positiveZ fromRG','arm':'linear R=AO,G=roughness,Bunuseddielectric'}}
def manifest_for(materials,retrieved):return {'schema':1,'licence':'CC0-1.0','licence_urls':['https://polyhaven.com/license','https://creativecommons.org/publicdomain/zero/1.0/'],'retrieved_utc':retrieved,'images_modified':False,'import_policy':policy(),'materials':materials}
def verify(manifest):
 assert manifest['import_policy']==policy();count=0
 for asset,entry in manifest['materials'].items():
  assert asset in ASSETS and entry['tile_size_m']==ASSETS[asset]['tile_size_m']
  for channel,resource in entry['files'].items():
   p=ROOT/resource.removeprefix('res://');data=p.read_bytes();assert sha(data)==entry['file_sha256'][channel] and len(data)==entry['file_bytes'][channel] and jpeg_dimensions(data)==entry['source_dimensions_px'][channel]
   text=Path(str(p)+'.import').read_text();expected={'compress/mode':'2','compress/high_quality':'false','compress/normal_map':'1' if channel=='normal_opengl' else '2','mipmaps/generate':'true','process/normal_map_invert_y':'false','process/size_limit':'2048' if channel=='albedo' else '1024'}
   for k,v in expected.items():assert re.search(rf'^{re.escape(k)}={re.escape(v)}$',text,re.M),f'{p}: {k}'
   assert '.bptc.ctex' not in text and '.astc.ctex' not in text;count+=1
 assert count==6 and manifest_for(manifest['materials'],manifest['retrieved_utc'])==manifest
 print('MERCHANT_MATERIAL_VERIFY:2CC0sets/6exactmaps/repeatpolicy/sourcebytespassed; no network or writes')
def main():
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('--verify-only',action='store_true');args=p.parse_args();file=DEST/'manifest.json'
 if args.verify_only:verify(json.loads(file.read_text()));return
 old=json.loads(file.read_text()) if file.exists() else {};materials={}
 for asset,meta in ASSETS.items():
  urls={};files={};hashes={};sizes={};dims={};md5s={};api=urllib.request.urlopen(urllib.request.Request('https://api.polyhaven.com/files/'+asset,headers=HEADERS),timeout=30).read();provider=json.loads(api)
  for channel,key in CHANNELS.items():
   source=provider[key]['2k']['jpg'];url=source['url'];data=urllib.request.urlopen(urllib.request.Request(url,headers=HEADERS),timeout=30).read();assert hashlib.md5(data).hexdigest()==source['md5'] and len(data)==source['size'],'Provider identity differs'
   previous=old.get('materials',{}).get(asset,{}).get('file_sha256',{}).get(channel);assert not previous or previous==sha(data),'Pinned upstream changed'
   target=DEST/asset/url.rsplit('/',1)[-1];target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data);apply_import_policy(target,asset,channel)
   urls[channel]=url;files[channel]='res://'+target.relative_to(ROOT).as_posix();hashes[channel]=sha(data);sizes[channel]=len(data);dims[channel]=jpeg_dimensions(data);md5s[channel]=source['md5']
  materials[asset]={**meta,'provider':'Poly Haven','licence':'CC0-1.0','source_url':'https://polyhaven.com/a/'+asset,'scale_evidence':'Officialassetpage/API millimetres rounded nominal3.0m/2.3m','download_urls':urls,'files':files,'file_sha256':hashes,'file_bytes':sizes,'source_dimensions_px':dims,'provider_md5':md5s,'files_api_sha256':sha(api)}
 manifest=manifest_for(materials,datetime.datetime.now(datetime.timezone.utc).isoformat());file.write_text(json.dumps(manifest,indent=2)+'\n');verify(manifest)
if __name__=='__main__':main()
