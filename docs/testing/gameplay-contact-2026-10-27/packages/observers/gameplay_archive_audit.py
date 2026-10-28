"""Audit local exports against explicit required-suite and clean-source inputs.

This observer does not build, launch Godot/Music, sign, publish or use a network.
Its successful result certifies source/archive consistency, not Mac execution.

Adapted from the committed pt24-next strong audit: full required/package union
Git-blob verification, exact notices, resources and native archive structure.
This gameplay continuation additionally requires the actual short-script Music
isolation guard (2/0), and identical cross-platform resource-pack bytes.
"""
from __future__ import annotations

import argparse
import configparser
import hashlib
import json
from pathlib import Path, PurePosixPath
import plistlib
import re
import shutil
import stat
import struct
import subprocess
import sys
import zipfile


class AuditError(Exception):
    pass


def require(condition, message):
    if not condition:
        raise AuditError(message)


def sha(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        while block := stream.read(2 * 1024 * 1024):
            digest.update(block)
    return digest.hexdigest()


def stream_sha(stream, size=None):
    digest = hashlib.sha256()
    remaining = size
    while remaining is None or remaining:
        block = stream.read(2 * 1024 * 1024 if remaining is None else min(remaining, 2 * 1024 * 1024))
        if not block:
            require(remaining in (None, 0), "Unexpected truncated byte stream")
            break
        digest.update(block)
        if remaining is not None:
            remaining -= len(block)
    return digest.hexdigest()


def load_json(path):
    return json.loads(path.read_text())


def relative_key(name):
    require(isinstance(name, str) and name and not any(c in name for c in "\\\n\r\0"), "Invalid source/archive path")
    value = PurePosixPath(name)
    require(not value.is_absolute() and ".." not in value.parts and value.parts, f"Unsafe relative path: {name}")
    return name


def manifest(raw):
    require(isinstance(raw, dict) and raw, "Missing source hash map")
    for name, digest in raw.items():
        relative_key(name)
        require(isinstance(digest, str) and re.fullmatch(r"[0-9a-f]{64}", digest), f"Invalid SHA256: {name}")
    return raw


def required_files(root, receipt):
    paths = {root / "project.godot", root / "docs/testing/horizon-background/observers/run_checked.py"}
    for folder in ("game", "tests", "tools"):
        paths.update(p for p in (root / folder).rglob("*") if p.is_file() and "__pycache__" not in p.parts)
    for argument in receipt["command"]:
        path = (root / argument).resolve()
        if path.suffix in (".py", ".sh", ".gd") and path.is_file() and path.is_relative_to(root):
            paths.add(path)
    return {str(path.relative_to(root)): sha(path) for path in sorted(paths)}


def package_files(root):
    paths = {root / name for name in ("project.godot", "export_presets.cfg", "tools/export.sh", "docs/PLAYER-GUIDE.md")}
    for folder in ("game", "docs/licences"):
        paths.update(path for path in (root / folder).rglob("*") if path.is_file())
    return {str(path.relative_to(root)): sha(path) for path in sorted(paths)}


def verify_git_blobs(root, commit, expected):
    require(re.fullmatch(r"[0-9a-f]{40}|[0-9a-f]{64}", commit), "Build metadata has no complete Git commit")
    resolved = subprocess.check_output(["git", "rev-parse", "--verify", commit + "^{commit}"], cwd=root, text=True).strip()
    require(resolved == commit, "Build commit does not resolve to the recorded commit")
    # One process, bounded streaming reads; no hundreds of separate git-show
    # calls and no asset contents printed into the audit log.
    child = subprocess.Popen(["git", "cat-file", "--batch"], cwd=root, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    try:
        for name, digest in sorted(expected.items()):
            child.stdin.write((commit + ":" + relative_key(name) + "\n").encode())
            child.stdin.flush()
            fields = child.stdout.readline().rstrip(b"\n").split()
            require(len(fields) == 3 and fields[1] == b"blob", f"Missing committed source blob: {name}")
            actual = stream_sha(child.stdout, int(fields[2]))
            require(child.stdout.read(1) == b"\n", f"Malformed Git blob boundary: {name}")
            require(actual == digest, f"Committed source hash differs: {name}")
        child.stdin.close()
        require(child.wait(timeout=30) == 0, "Git object audit failed")
    finally:
        if child.poll() is None:
            child.terminate()
            child.wait(timeout=10)
        child.stdout.close()


def export_settings(root):
    config = configparser.ConfigParser(interpolation=None)
    config.read(root / "export_presets.cfg")
    sections = [name for name in config.sections() if not name.endswith(".options")
                and config.get(name, "platform", fallback="") == '"macOS"']
    require(len(sections) == 1, "Expected one explicit macOS export preset")
    options = config[sections[0] + ".options"]
    extra = json.loads(options["application/additional_plist_content"])
    plist = plistlib.loads(("<plist version=\"1.0\"><dict>" + extra + "</dict></plist>").encode())
    description = plist.get("NSAppleEventsUsageDescription")
    require(isinstance(description, str) and "Music" in description, "Source export lacks Music Automation usage description")
    return {
        "description": description,
        "bundle_identifier": json.loads(options["application/bundle_identifier"]),
        "codesign_enabled": json.loads(options["codesign/codesign"]) != 0,
        "notarization_enabled": json.loads(options["notarization/notarization"]) != 0,
        "apple_events_entitlement_configured": json.loads(options["codesign/entitlements/apple_events"]),
    }


def signature_entitlements(data):
    result = {"signature_blob_structure_readable": False, "xml_entitlements_present": False,
              "der_entitlements_present": False, "apple_events_entitlement_in_xml": None}
    if len(data) < 12:
        return result
    magic, length, count = struct.unpack_from(">III", data)
    if magic != 0xFADE0CC0 or not 12 + count * 8 <= length <= len(data):
        return result
    result["signature_blob_structure_readable"] = True
    for index in range(count):
        kind, offset = struct.unpack_from(">II", data, 12 + index * 8)
        require(offset + 8 <= length, "Embedded code-signature index is outside its blob")
        blob_magic, blob_length = struct.unpack_from(">II", data, offset)
        require(8 <= blob_length <= length - offset, "Embedded code-signature blob is truncated")
        if kind == 5 and blob_magic == 0xFADE7171:
            entitlements = plistlib.loads(data[offset + 8:offset + blob_length].rstrip(b"\0"))
            result["xml_entitlements_present"] = True
            result["apple_events_entitlement_in_xml"] = entitlements.get("com.apple.security.automation.apple-events")
        if kind == 7:
            result["der_entitlements_present"] = True
    return result


def mac_architectures(z, executable):
    observations = []
    with z.open(executable) as stream:
        magic, count = struct.unpack(">II", stream.read(8))
        require(magic == 0xCAFEBABE and count == 2, "Expected two-slice universal macOS executable")
        records = [struct.unpack(">IIIII", stream.read(20)) for _ in range(count)]
        require({item[0] for item in records} == {0x01000007, 0x0100000C}, "Mac executable lacks x86_64/arm64 slices")
        total_size = z.getinfo(executable).file_size
        for cpu, _subtype, offset, size, _alignment in sorted(records, key=lambda item: item[2]):
            require(offset + size <= total_size, "Mac architecture slice exceeds executable")
            stream.seek(offset)
            header = stream.read(32)
            require(header[:4] == b"\xcf\xfa\xed\xfe", "Mac slice is not little-endian Mach-O64")
            require(struct.unpack_from("<I", header, 4)[0] == cpu, "Mach-O CPU differs from universal architecture table")
            commands_count, commands_size = struct.unpack_from("<II", header, 16)
            require(commands_count <= 10000 and commands_size <= size - 32, "Invalid Mach-O load-command bounds")
            commands = stream.read(commands_size)
            cursor = 0
            signature = None
            for _ in range(commands_count):
                require(cursor + 8 <= len(commands), "Truncated Mach-O load command")
                command, length = struct.unpack_from("<II", commands, cursor)
                require(8 <= length <= len(commands) - cursor, "Invalid Mach-O command size")
                if command == 0x1D:
                    require(length >= 16, "Invalid code-signature load command")
                    signature = struct.unpack_from("<II", commands, cursor + 8)
                cursor += length
            observation = {"architecture": "arm64" if cpu == 0x0100000C else "x86_64",
                           "code_signature_load_command_present": signature is not None,
                           "cryptographic_signature_validity": "not_verified"}
            if signature is not None:
                data_offset, data_size = signature
                require(data_offset + data_size <= size, "Mac signature extends outside architecture slice")
                stream.seek(offset + data_offset)
                observation.update(signature_entitlements(stream.read(data_size)))
            observations.append(observation)
    return observations


def verify_resources(report):
    require(report.get("main_scene_loaded") is True, "Native pack probe did not load main/scripts")
    require(set(report.get("voice_streams", {})) == {"landing", "cone", "again"}, "Pack probe lacks the three voice resources")
    require(len(report.get("textures", {})) == 4 and len(report.get("human_meshes", {})) == 4, "Pack probe lacks reviewed textures/human meshes")
    for texture in report["textures"].values():
        require(0 < texture["width"] <= 1024 and 0 < texture["height"] <= 1024 and texture["mipmaps"] >= 1,
                "Pack texture has invalid bounds/mipmaps")
    for mesh in report["human_meshes"].values():
        require(mesh["surfaces"] > 0 and mesh["vertices"] >= 50, "Pack anatomical mesh is absent/truncated")


def notice_sources(root, meta):
    sources = {p.name: p for p in (root / "docs/licences/third-party").glob("*.txt")}
    sources.update({"TEXTURE-PROVENANCE.json": root / "game/art/assets/zc_textures/manifest.json",
                    "HUMAN-MESH-PROVENANCE.json": root / "game/art/assets/makehuman_hm08/manifest.json",
                    "VOICE-PROVENANCE.json": root / "game/audio/generated/manifest.json",
                    "PROVENANCE.md": root / "docs/licences/REGISTER.md"})
    for name, source in meta["template_verification"]["notice_sources"].items():
        path = root / ".local/export-notices" / relative_key(name)
        require(sha(path) == source[1], f"Godot notice differs from verified template provenance: {name}")
        sources[name] = path
    require(len(sources) == 13, "The reviewed thirteen-notice/provenance contract changed")
    return sources


def safe_zip_paths(z):
    names = z.namelist()
    require(len(names) == len(set(names)), "ZIP contains duplicate member names")
    for entry in z.infolist():
        relative_key(entry.filename.rstrip("/"))
        mode = entry.external_attr >> 16
        if stat.S_ISLNK(mode):
            target = z.read(entry).decode()
            require(not PurePosixPath(target).is_absolute() and "\\" not in target, "Unsafe ZIP symlink target")
            stack = list(PurePosixPath(entry.filename).parent.parts)
            for part in PurePosixPath(target).parts:
                if part == "..":
                    require(stack, "ZIP symlink escapes the archive")
                    stack.pop()
                elif part != ".":
                    stack.append(part)


def audit_archive(root, build, platform, meta, settings, notices):
    archive = build / f"TamHawksProSkater-{platform}.zip"
    report = load_json(build / f"{platform}-resources.json")
    packaged = load_json(build / platform / "PACKAGED-RESOURCES.json")
    verify_resources(report)
    verify_resources(packaged)
    require(all(packaged.get(key) == value for key, value in report.items()), "Packaged resource report differs from native inspection")
    pack_path = relative_key(packaged["pack_path"])
    require(sha(build / platform / pack_path) == packaged["pack_sha256"], "Local PCK changed after native resource inspection")
    record = {"platform": platform, "file": archive.name, "bytes": archive.stat().st_size, "sha256": sha(archive)}
    with zipfile.ZipFile(archive) as z:
        safe_zip_paths(z)
        require(z.testzip() is None, "ZIP CRC failed")
        require(json.loads(z.read("BUILD-METADATA.json")) == meta, "ZIP build metadata differs")
        require(json.loads(z.read("PACKAGED-RESOURCES.json")) == packaged, "ZIP native resource receipt differs")
        require(z.read("PLAYER-GUIDE.md") == (root / "docs/PLAYER-GUIDE.md").read_bytes(), "ZIP player guide differs")
        with z.open(pack_path) as stream:
            require(stream_sha(stream) == packaged["pack_sha256"], "ZIP PCK differs from native-inspected pack")
        members = {name for name in z.namelist() if name.startswith("NOTICES/") and not name.endswith("/")}
        require(members == {"NOTICES/" + name for name in notices}, "ZIP notice/provenance membership differs")
        for name, source in notices.items():
            require(hashlib.sha256(z.read("NOTICES/" + name)).hexdigest() == sha(source), f"ZIP notice/provenance differs: {name}")
        if platform == "linux":
            executable = "TamHawksProSkater.x86_64"
            with z.open(executable) as stream:
                header = stream.read(64)
            require(header[:6] == b"\x7fELF\x02\x01" and struct.unpack_from("<H", header, 18)[0] == 62, "Linux executable is not x86_64 ELF64")
            record["architectures"] = ["x86_64"]
        else:
            app = "Tam Hawks Pro Skater.app/Contents/"
            info = plistlib.loads(z.read(app + "Info.plist"))
            require(info.get("NSAppleEventsUsageDescription") == settings["description"], "Actual archived Info.plist lacks the source Music Automation description")
            require(info.get("CFBundleIdentifier") == settings["bundle_identifier"], "Mac bundle identity differs from source preset")
            executable = app + "MacOS/" + info["CFBundleExecutable"]
            record["architecture_signature_observations"] = mac_architectures(z, executable)
            record["architectures"] = sorted(item["architecture"] for item in record["architecture_signature_observations"])
            record["music_automation_usage_description"] = info["NSAppleEventsUsageDescription"]
            record["main_app_code_resources_present"] = app + "_CodeSignature/CodeResources" in z.namelist()
            record["apple_events_entitlement_configured"] = settings["apple_events_entitlement_configured"]
            record["effective_automation_entitlement_or_consent_verified"] = False
        require((z.getinfo(executable).external_attr >> 16) & stat.S_IXUSR, "Archived executable lacks Unix execute mode")
    record.update({"crc_valid": True, "safe_member_paths": True, "executable_mode_valid": True,
                   "notice_records": len(notices), "pack_sha256": packaged["pack_sha256"],
                   "native_pack_resource_report_verified": True})
    return record


def audit(args):
    root, build = args.root.resolve(), args.build.resolve()
    receipt = load_json(args.receipt)
    tested, after = manifest(load_json(args.source_before)), manifest(load_json(args.source_after))
    log = args.log or args.receipt.parent / "console.log"
    text = log.read_text()
    counts = [[int(a), int(b)] for a, b in re.findall(r"RESULT: (\d+) passed, (\d+) failed", text)]
    require(receipt.get("valid") is True and receipt.get("exit_code") == 0 and receipt.get("source_stable") is True
            and receipt.get("clean_log") is True, "Required suite receipt was not admitted")
    require(counts and all(passed > 0 and failed == 0 for passed, failed in counts), "Required log lacks clean passing assertions")
    require(counts == [[int(a), int(b)] for a, b in receipt["result_counts"]], "Required receipt/log assertion counts differ")
    music_counts = [[int(a), int(b)] for a, b in re.findall(r"SCRIPT LAUNCH: (\d+) passed, (\d+) failed", text)]
    require(music_counts == [[2, 0]], "Required log lacks the actual Music short-script isolation guard2/0")
    launch_arguments = [json.loads(raw) for raw in re.findall(r"ACTUAL_ENGINE_ARGUMENTS (\[[^\n]+\])", text)]
    require(any("-s" in arguments and "tests/support/music_launch_guard.gd" in arguments
                for arguments in launch_arguments), "Music guard log does not witness the actual -s script option")
    require("PASS: actual script alias: Main defaults to isolated profile before entering tree" in text
            and "PASS: actual script alias: Music stays inert even if persistence is requested" in text,
            "Actual Music script guard did not attest both profile and personal-Music isolation")
    require(not any(marker in text for marker in ("SCRIPT ERROR", "ERROR:", "FAIL:", "Parse Error")), "Required suite log contains an error")
    require(any(Path(arg).name == "check.sh" for arg in receipt["command"]), "Receipt does not identify the required check.sh suite")
    require(tested == after and len(tested) == receipt["source_inputs"], "Required before/after source membership differs")
    require(sha(args.source_before) == receipt["source_manifest_sha256"], "Required source manifest fingerprint differs")
    require(required_files(root, receipt) == tested, "Full required-tested input membership or hashes changed")
    meta = load_json(build / "BUILD-METADATA.json")
    packaged_inputs = manifest(meta["source_files_sha256"])
    require(meta.get("working_tree_dirty") is False, "Export was not made from a clean commit")
    require(package_files(root) == packaged_inputs, "Full package-source input membership or hashes changed")
    fingerprint = hashlib.sha256(json.dumps(packaged_inputs, sort_keys=True).encode()).hexdigest()
    require(fingerprint == meta["runtime_source_sha256"], "Package runtime-source fingerprint differs")
    overlap = set(tested) & set(packaged_inputs)
    require(all(tested[name] == packaged_inputs[name] for name in overlap), "Tested/package input overlap differs")
    require({"project.godot", "game/main.gd", "game/audio/apple_music.gd"} <= overlap, "Current Main/Music runtime was not both tested and packaged")
    commit_inputs = dict(tested)
    commit_inputs.update(packaged_inputs)
    verify_git_blobs(root, meta["git_commit"], commit_inputs)
    settings = export_settings(root)
    require(not settings["codesign_enabled"] and not settings["notarization_enabled"], "This local audit expects explicitly unsigned, unnotarized exports")
    require(settings["apple_events_entitlement_configured"] is True, "Mac source preset lacks configured Apple Events entitlement")
    require(meta.get("macos_signed") is False and meta.get("macos_notarized") is False
            and meta.get("macos_launch_tested") is False, "Metadata claims unsupported Mac signing/notarization/execution")
    notices = notice_sources(root, meta)
    records = [audit_archive(root, build, platform, meta, settings, notices) for platform in ("linux", "macos")]
    require(records[0]["pack_sha256"] == records[1]["pack_sha256"], "Linux/Mac resource pack bytes differ")
    sums = {}
    for line in (build / "SHA256SUMS.txt").read_text().splitlines():
        digest, name = line.split(maxsplit=1)
        require(name not in sums, "Duplicate archive checksum entry")
        sums[name] = digest
    require(sums == {record["file"]: record["sha256"] for record in records}, "Archive checksum manifest differs")
    for name in ("linux-export.log", "macos-export.log", "linux-resources.log", "macos-resources.log"):
        require(not any(marker in (build / name).read_text() for marker in ("SCRIPT ERROR", "ERROR:", "Parse Error")), f"Export/resource log contains an error: {name}")
    result = {"valid": True, "git_commit": meta["git_commit"], "receipt_parent_git_head": receipt["git_head"],
              "working_tree_clean_at_export": True, "required_assertion_counts": counts,
              "actual_music_script_guard_counts": music_counts,
              "actual_music_script_short_option_and_isolation_verified": True,
              "audit_observer_sha256": sha(Path(__file__).resolve()),
              "required_input_count": len(tested), "package_input_count": len(packaged_inputs),
              "package_test_overlap": len(overlap), "committed_source_blobs_verified": len(commit_inputs),
              "all_required_and_package_memberships_match_checkout": True,
              "all_required_and_package_inputs_match_commit_objects": True,
              "required_suite_receipt_sha256": sha(args.receipt), "required_suite_log_sha256": sha(log),
              "required_source_before_sha256": sha(args.source_before), "required_source_after_sha256": sha(args.source_after),
              "runtime_source_sha256": fingerprint, "checks_run_by_export_script": meta["checks_run_by_export_script"],
              "archives": records, "cross_platform_pack_bytes_identical": records[0]["pack_sha256"] == records[1]["pack_sha256"],
              "macos_export_signing_enabled": False, "macos_export_notarization_enabled": False,
              "macos_signature_cryptographically_verified": False, "macos_executable_launched": False,
              "target_performance_accepted": False,
              "limits": ["Unsigned export settings and a Music usage description do not certify an effective signed Automation entitlement or TCC consent.",
                         "Any embedded template signature/entitlement observations are structural only; signature validity is not verified on Linux.",
                         "Linux-loaded Mac resource packs do not execute the Mac binary or certify Music playback, physical controllers, audio, saves, performance or human acceptance."]}
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    observers = output / "observers"
    observers.mkdir(exist_ok=True)
    observer_target = observers / "gameplay_archive_audit.py"
    if Path(__file__).resolve() != observer_target.resolve():
        shutil.copy2(Path(__file__).resolve(), observer_target)
    for name in ("BUILD-METADATA.json", "SHA256SUMS.txt", "linux-resources.json", "macos-resources.json",
                 "linux-export.log", "macos-export.log", "linux-resources.log", "macos-resources.log"):
        shutil.copy2(build / name, output / name)
    for source, name in ((args.receipt, "required-suite-receipt.json"), (args.source_before, "required-source-before.json"),
                         (args.source_after, "required-source-after.json"), (log, "required-suite-console.log")):
        if source.resolve() != (output / name).resolve():
            shutil.copy2(source, output / name)
    (output / "ARCHIVE-AUDIT.json").write_text(json.dumps(result, indent=2) + "\n")
    return result


def arguments():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path.cwd(), help="Repository checkout containing the tested source")
    parser.add_argument("--build", type=Path, required=True, help="Completed tools/export.sh build directory")
    parser.add_argument("--receipt", type=Path, default=Path(".local/gameplay-contact-required-06/receipt.json"), help="Admitted full-suite receipt.json")
    parser.add_argument("--source-before", type=Path, default=Path(".local/gameplay-contact-required-06/source-before.json"), help="Full required-suite before hash map")
    parser.add_argument("--source-after", type=Path, default=Path(".local/gameplay-contact-required-06/source-after.json"), help="Full required-suite after hash map")
    parser.add_argument("--log", type=Path, help="Full-suite console log; defaults beside receipt")
    parser.add_argument("--output", type=Path, default=Path("docs/testing/gameplay-contact-2026-10-27/packages"), help="Portable audit evidence directory")
    return parser.parse_args()


if __name__ == "__main__":
    options = arguments()
    try:
        print(json.dumps(audit(options), indent=2))
    except (AuditError, OSError, ValueError, KeyError, subprocess.SubprocessError, zipfile.BadZipFile, struct.error) as error:
        options.output.mkdir(parents=True, exist_ok=True)
        failure = {"valid": False, "error": str(error), "build_directory": str(options.build), "receipt": str(options.receipt)}
        (options.output / "ARCHIVE-AUDIT.json").write_text(json.dumps(failure, indent=2) + "\n")
        print("ARCHIVE AUDIT FAILED: " + str(error), file=sys.stderr)
        raise SystemExit(1)
