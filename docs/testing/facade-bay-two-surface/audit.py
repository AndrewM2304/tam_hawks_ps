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
            assert receipt['sources_sha256']['art_source/glasgow_bay/two_surface/preview/'+path]==expected
        assert receipt['verified_staged_executed_recipes_sha256']==inputs['staged_executed_recipes_sha256']
        assert receipt['render_report_sha256']==digest((folder/'report.json').read_bytes())
        assert not report['errors'] and len(report['images'])==trial['scene_images']==16
        assert len(report['native_lod_samples'])==trial['native_lod_checks']==22
        assert len(receipt['decoded_imported_mips'])==trial['mip_images']==23
        for item in report['native_lod_samples']:
            assert item['actual_visible_primitives']==item['expected_triangles']
        expected_counts={'fitted':{'near':18392,'mid':3544,'far':648},
                         'candidate':{'near':9864,'mid':3544,'far':648}}
        meshes={item['path']:item for item in report['meshes']}
        assert len(meshes)==6 and report['performance_measurement'] is False
        for item in report['images']:
            assert item['actual_holder_primitive_delta']==item['expected_triangles']
            assert item['visible_primitives_including_fixture']-item['fixture_only_primitives']==item['expected_triangles']
            variant,lod=item['variant'],item['expected_native_lod']
            mesh=meshes['res://'+variant+'/glasgow_bay_'+lod+'.glb']
            assert item['expected_triangles']==mesh['triangles']==expected_counts[variant][lod]
            assert item['source_sha256']==mesh['sha256']
            assert mesh['surfaces']==(2 if variant=='candidate' else 4) and mesh['auto_mesh_lods'] is False
        for texture in report['textures']:
            if texture['path'].endswith('/accent_orm.png'):
                assert texture['size']==[128,128] and texture['has_mipmaps'] is False
                assert texture['mipmap_count']==0 and texture['imported_data_bytes']==8192
                assert texture['compressed'] is True
            else:
                assert texture['size']==[1024,1024] and texture['has_mipmaps'] is True
                assert texture['mipmap_count']==10
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
        diagnostic=folder/'paint-diagnostic.json'
        if diagnostic.exists():
            paint=json.loads(diagnostic.read_text())
            assert digest((folder/'diagnose_paint.py').read_bytes())==paint['script_sha256']
            staged={item['path']:item['sha256'] for item in inputs['assets']+inputs['textures']}
            for path,expected in paint['input_sha256'].items():
                actual=digest((folder/path).read_bytes()) if (folder/path).exists() else staged[path]
                assert actual==expected,path
        results[name]={'source_inputs':26,'scene_pngs':16,'mip_pngs':23,'native_lod_checks':22,
                       'source_artifact_decode_checks_pass':True,'disposition':trial['disposition']}
    assert digest((HERE/'diagnose_paint.py').read_bytes())==manifest['paint_diagnostic_recipe_sha256']
    tradeoff=None
    if 'lossless-colour' in manifest['trials']:
        assert digest((HERE/'compare_lossless.py').read_bytes())==manifest['lossless_comparison_recipe_sha256']
        comparison=json.loads((HERE/'lossless-colour/lossless-comparison.json').read_text())
        assert comparison['script_sha256']==manifest['lossless_comparison_recipe_sha256']
        compressed=json.loads((HERE/'production-sky/report.json').read_text())
        lossless=json.loads((HERE/'lossless-colour/report.json').read_text())
        for path,expected in comparison['input_sha256'].items():
            source=Path(path)
            trial=next(name for name,value in manifest['trials'].items() if value['original_run']==source.parent.name)
            assert digest((HERE/trial/source.name).read_bytes())==expected,path
        old={Path(t['path']).stem:t for t in compressed['textures']}
        new={Path(t['path']).stem:t for t in lossless['textures']}
        for key in old:
            fields=['source_sha256','size','role','mipmap_count','has_mipmaps']
            if key!='accent_basecolor': fields+=['compressed','image_format','imported_data_bytes']
            assert {f:old[key][f] for f in fields}=={f:new[key][f] for f in fields}
        assert old['accent_basecolor']['compressed'] is True and new['accent_basecolor']['compressed'] is False
        assert lossless['import_policy']['accent_colour']=='lossless'
        assert lossless['import_policy']['default_is_vram_compressed'] is True
        for filename in (item['image'] for item in compressed['images'] if item['variant']=='fitted'):
            assert digest((HERE/'production-sky'/filename).read_bytes())==digest((HERE/'lossless-colour'/filename).read_bytes())
        names=['sandstone_basecolor','sandstone_normal_opengl','sandstone_orm','accent_basecolor','accent_orm']
        old_total=sum(old[n]['imported_data_bytes'] for n in names)
        new_total=sum(new[n]['imported_data_bytes'] for n in names)
        assert comparison['candidate_total_imported_data_bytes']=={'compressed':old_total,'lossless':new_total,'delta':new_total-old_total}
        tradeoff={'compressed_candidate_imported_bytes':old_total,'lossless_candidate_imported_bytes':new_total,
                  'additional_imported_bytes':new_total-old_total,'identical_fitted_controls':8,
                  'resident_gpu_memory_measured':False,'coarse_colour_mips_resolved':False}
    result={'accepted_capture_evidence':True,'trials':results,'visual_acceptance':False,
            'live_integration':False,'fps_or_mac_claim':False,
            'lossless_colour_tradeoff':tradeoff,
            'manifest_sha256':digest((HERE/'retention.json').read_bytes()),
            'audit_sha256':digest(Path(__file__).read_bytes())}
    (HERE/'AUDIT.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2))

if __name__=='__main__':
    main()
