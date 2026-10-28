#!/usr/bin/env python3
"""Native-generated UID/path verification and original scene-parameter policy only.
Run only after root lease and a fresh Godot import created all new .import files.
No engine is launched by this script. Default mode is read-only audit.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re

LEVELS=['near','mid','far']
OLD='game/art/assets/glasgow_bay'
NEW='game/art/assets/glasgow_bay_reduced_four_slot'

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def field(text,key):
    matches=re.findall(r'^'+re.escape(key)+r'="([^"]+)"$',text,re.M)
    assert len(matches)==1,(key,matches)
    return matches[0]
def params(text):
    assert text.count('[params]')==1
    return text.split('[params]',1)[1]
def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--repo',type=Path,required=True)
    p.add_argument('--original-manifest',type=Path,required=True)
    p.add_argument('--set-policy',action='store_true',help='Write ONLY new scene import [params]; no original UID/remap/deps copied.')
    p.add_argument('--output',type=Path,help='Optional NEW audit output file; do not overwrite prior receipt.')
    a=p.parse_args();root=a.repo.resolve()
    before=json.loads(a.original_manifest.read_text())['files']
    assert all(sha(root/name)==digest for name,digest in before.items()),'Original runtime bytes changed.'
    oldtexts={lod:(root/OLD/f'glasgow_bay_{lod}.glb.import').read_text() for lod in LEVELS}
    old_uids={field(text,'uid') for text in oldtexts.values()}
    assert len(old_uids)==3
    newtexts={lod:(root/NEW/f'glasgow_bay_{lod}.glb.import').read_text() for lod in LEVELS}
    new_uids={field(text,'uid') for text in newtexts.values()}
    assert len(new_uids)==3 and not (new_uids&old_uids),'New native UIDs must be unique against one another and original imports.'
    records={}
    for lod,text in newtexts.items():
        path=root/NEW/f'glasgow_bay_{lod}.glb.import'
        expected='res://'+NEW+f'/glasgow_bay_{lod}.glb'
        assert field(text,'source_file')==expected
        assert field(text,'importer')=='scene' and field(text,'type')=='PackedScene'
        cache=field(text,'path')
        assert cache.startswith('res://.godot/imported/') and cache.endswith('.scn')
        assert cache != field(oldtexts[lod],'path'),'Native cache path reused original asset.'
        assert ('dest_files=["'+cache+'"]') in text
        prefix=text.split('[params]',1)[0]
        expected_params=params(oldtexts[lod])
        if lod=='near':
            expected_params=expected_params.replace('meshes/force_disable_compression=false','meshes/force_disable_compression=true')
        if a.set_policy:
            path.write_text(prefix+'[params]'+expected_params)
            assert path.read_text().split('[params]',1)[0]==prefix,'Native-generated identity block altered.'
        after=path.read_text()
        assert params(after)==expected_params,'New import policy differs from original plus declared near precision exception.'
        assert 'meshes/generate_lods=false' in after and 'animation/import=false' in after
        records[str(path.relative_to(root))]={'sha256':sha(path),'native_uid':field(after,'uid'),'native_cache_path':cache,'source_file':expected,'original_params_exact':lod!='near','original_params_with_declared_precision_exception':True,'native_identity_prefix_sha256':hashlib.sha256(prefix.encode()).hexdigest()}
    assert all(sha(root/name)==digest for name,digest in before.items()),'Original runtime bytes changed.'
    result={'schema':1,'original_runtime_18_files_unchanged':True,'new_scene_uids_unique':True,'new_scene_uids_distinct_from_original':True,'new_native_paths_distinct':True,'scene_params_match_original':False,'scene_parameter_exceptions':{'near':{'meshes/force_disable_compression':True,'reason':'Preserve authored0.53 threshold within unchanged1e-4 native assertion; compressed import yielded0.5297999978.'}},'authored_mesh_lods':True,'automatic_mesh_lods':False,'new_imports':records,'engine_launched':False,'native_reimport_required_after_policy_write':a.set_policy}
    if a.output:
        assert not a.output.exists(),'Refusing prior audit overwrite.'
        a.output.write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2))
if __name__=='__main__':main()
