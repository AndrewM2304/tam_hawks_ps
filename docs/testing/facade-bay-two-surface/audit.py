#!/usr/bin/env python3
"""Verify retained disposable previews without an engine or current recipe assumptions."""
import hashlib
import json
from pathlib import Path
import subprocess
from PIL import Image

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]

def digest(data):
    return hashlib.sha256(data).hexdigest()

def main():
    manifest=json.loads((HERE/'retention.json').read_text())
    results={}
    for name,trial in manifest['trials'].items():
        folder=HERE/name
        for relative,expected in trial['retained_sha256'].items():
            assert digest((HERE/relative).read_bytes())==expected,relative
        receipt=json.loads((folder/'receipt.json').read_text())
        report=json.loads((folder/'report.json').read_text())
        inputs=json.loads((folder/'input-manifest.json').read_text())
        assert receipt['sources_sha256']==inputs['sources_sha256']
        assert set(receipt['sources_sha256'])==set(trial['source_bindings'])
        for path,expected in receipt['sources_sha256'].items():
            binding=trial['source_bindings'][path]
            if binding['kind']=='git':
                data=subprocess.check_output(['git','show',binding['commit']+':'+path],cwd=ROOT)
            else:
                data=(HERE/binding['path']).read_bytes()
            assert digest(data)==expected==binding['sha256'],path
        for path,expected in inputs['staged_executed_recipes_sha256'].items():
            assert digest((folder/path).read_bytes())==expected,path
        assert receipt['render_report_sha256']==digest((folder/'report.json').read_bytes())
        assert not report['errors'] and len(report['images'])==trial['scene_images']==16
        assert len(report['native_lod_samples'])==trial['native_lod_checks']==22
        assert len(receipt['decoded_imported_mips'])==trial['mip_images']==23
        for item in report['native_lod_samples']:
            assert item['actual_visible_primitives']==item['expected_triangles']
        for item in report['images']:
            assert item['actual_holder_primitive_delta']==item['expected_triangles']
            assert item['visible_primitives_including_fixture']-item['fixture_only_primitives']==item['expected_triangles']
        records=[(x['file'],x['dimensions'],x) for x in receipt['images']]
        records += [(x['image'],x['size'],x) for x in receipt['decoded_imported_mips']]
        for filename,dimensions,item in records:
            path=folder/filename
            assert digest(path.read_bytes())==item['sha256'],filename
            with Image.open(path) as image:
                image.load()
                assert image.format=='PNG' and list(image.size)==dimensions,filename
                assert digest(image.convert('RGB').tobytes())==item['decoded_rgb_sha256'],filename
        for item in report['meshes']+report['textures']:
            relative=item['path'].removeprefix('res://')+'.import'
            assert digest((folder/'staged-imports'/relative).read_bytes())==item['import_sha256'],relative
        for filename in ('engine.log','import-initial.log','import-configured.log'):
            text=(folder/filename).read_text()
            assert not any(x in text for x in ('ERROR:','SCRIPT ERROR:','Parse Error:')),filename
        assert receipt['performance_measurement'] is False and receipt['mac_result'] is False
        assert receipt['unchanged_sources']==trial['stable_inputs']==26
        results[name]={'source_inputs':26,'scene_pngs':16,'mip_pngs':23,'native_lod_checks':22,
                       'source_artifact_decode_checks_pass':True,'disposition':trial['disposition']}
    assert digest((HERE/'diagnose_paint.py').read_bytes())==manifest['paint_diagnostic_recipe_sha256']
    result={'accepted_capture_evidence':True,'trials':results,'visual_acceptance':False,
            'live_integration':False,'fps_or_mac_claim':False,
            'manifest_sha256':digest((HERE/'retention.json').read_bytes()),
            'audit_sha256':digest(Path(__file__).read_bytes())}
    (HERE/'AUDIT.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2))

if __name__=='__main__':
    main()
