from pathlib import Path
import argparse,hashlib,json,os,tempfile
here=Path(__file__).resolve().parent
args=argparse.ArgumentParser();args.add_argument("--root",type=Path,required=True);args.add_argument("--apply",action="store_true");opt=args.parse_args()
manifest=json.loads((here/"manifest.json").read_text())
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None
for e in manifest["entries"]:
 target=opt.root/e["path"];payload=here/"payload"/e["path"]
 if sha(payload)!=e["after_sha256"]:raise SystemExit("bad payload "+e["path"])
 if sha(target) not in [e["before_sha256"],e["after_sha256"]]:raise SystemExit("preimage changed "+e["path"])
if opt.apply:
 for e in manifest["entries"]:
  target=opt.root/e["path"]
  if sha(target)==e["after_sha256"]:continue
  target.parent.mkdir(parents=True,exist_ok=True)
  fd,temp=tempfile.mkstemp(prefix=".round-install-",dir=target.parent)
  try:
   with os.fdopen(fd,"wb") as out:out.write((here/"payload"/e["path"]).read_bytes())
   os.chmod(temp,(target.stat().st_mode&0o777) if target.exists() else 0o644)
   os.replace(temp,target)
  finally:
   if os.path.exists(temp):os.unlink(temp)
 for e in manifest["entries"]:
  if sha(opt.root/e["path"])!=e["after_sha256"]:raise SystemExit("postimage failed "+e["path"])
print("ROUND_ADMISSION_GUARD_OK",len(manifest["entries"]),"applied" if opt.apply else "read-only")
