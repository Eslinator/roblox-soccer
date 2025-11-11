#!/usr/bin/env python3
import json, os, sys, pathlib, shlex, subprocess, time, base64, re

CFG_PATH = pathlib.Path("bot/connector.config.json")
RUN_REPORT = pathlib.Path(".connector/run_report.jsonl")

def eprint(*a): print(*a, file=sys.stderr)
def load_cfg():
    if not CFG_PATH.exists(): eprint("[FATAL] missing bot/connector.config.json"); sys.exit(2)
    with CFG_PATH.open("r", encoding="utf-8") as f: return json.load(f)

def allow_bin(cmd, allowlist):
    head = shlex.split(cmd, posix=True)[0] if isinstance(cmd,str) and cmd.strip() else ""
    return os.path.basename(head) in allowlist
def has_deny(cmd, deny_patterns):
    s = cmd if isinstance(cmd,str) else " ".join(cmd)
    return any(pat in s for pat in deny_patterns)

def run_shell(cmd, timeout, cwd, env):
    try:
        p = subprocess.run(cmd, shell=True, cwd=cwd, env=env,
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                           timeout=timeout, text=True, check=False)
        return p.returncode, p.stdout, p.stderr
    except subprocess.TimeoutExpired:
        return 124, "", f"timeout after {timeout}s"
def run_dry(cmd): return 0, f"[dry-run] {cmd}", ""
def log_report(event):
    RUN_REPORT.parent.mkdir(parents=True, exist_ok=True)
    with RUN_REPORT.open("a", encoding="utf-8") as f: f.write(json.dumps(event) + "\n")

def write_files(files_map, repo_root, dry):
    for rel, spec in files_map.items():
        if isinstance(spec, dict):
            content = spec.get("content",""); enc = (spec.get("encoding","utf8") or "utf8").lower()
        else:
            content, enc = str(spec), "utf8"
        if dry: continue
        path = pathlib.Path(repo_root) / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        text = base64.b64decode(content).decode("utf-8") if enc == "b64" else content
        with open(path, "w", encoding="utf-8") as f: f.write(text)

def git_run(cmd, allow, deny, dry, timeout, cwd, env):
    if has_deny(cmd, deny): return 2, "", "deny_pattern"
    if not allow_bin(cmd, allow): return 3, "", f"not_in_allowlist:{shlex.split(cmd)[0] if cmd else ''}"
    return (run_dry(cmd) if dry else run_shell(cmd, timeout, cwd, env))

def validate_checks(checks, repo_root, allow, deny, dry, timeout, cwd, env):
    all_ok = True
    for c in checks:
        op = c.get("op")
        if op == "file_exists":
            p = pathlib.Path(repo_root) / c.get("path",""); ok = p.exists()
            print(f"CHECK {'OK' if ok else 'FAIL'} file_exists:{p}"); all_ok &= ok
        elif op == "text_contains":
            p = pathlib.Path(repo_root) / c.get("path","")
            if not p.exists(): print(f"CHECK FAIL missing:{p}"); all_ok = False; continue
            try: txt = pathlib.Path(p).read_text(encoding="utf-8")
            except UnicodeDecodeError: print(f"CHECK FAIL decode_error:{p}"); all_ok = False; continue
            ok = c.get("substr","") in txt; print(f"CHECK {'OK' if ok else 'FAIL'} text_contains:{p}"); all_ok &= ok
        elif op in ("cmd_success","cmd_contains"):
            cmd = c.get("cmd","").strip()
            if not cmd: print("CHECK FAIL reason=empty_cmd"); all_ok = False; continue
            code, out, err = git_run(cmd, allow, deny, dry, timeout, cwd, os.environ)
            ok = (code == 0) if op == "cmd_success" else (code == 0 and c.get("substr","") in out)
            print(f"CHECK {'OK' if ok else 'FAIL'} cmd:{cmd}")
            if out.strip(): print("STDOUT_BEGIN"); print(out.rstrip()); print("STDOUT_END")
            if err.strip(): print("STDERR_BEGIN"); print(err.rstrip()); print("STDERR_END")
            all_ok &= ok
        else:
            print(f"CHECK FAIL unsupported_op:{op}"); all_ok = False
    return all_ok

def handle_git_ops(ops, allow, deny, dry, timeout, cwd, env):
    for op in ops:
        name = op.get("op")
        if name == "ensure_repo":
            code, _, _ = git_run("git rev-parse --is-inside-work-tree", allow, deny, dry, timeout, cwd, env)
            if code != 0:
                code, _, err = git_run("git init", allow, deny, dry, timeout, cwd, env)
                if code != 0: return False, f"git init failed: {err}"
            print("GIT ensure_repo OK")
        elif name == "create_branch":
            br = op.get("name"); base = op.get("base",""); if_exists = op.get("if_exists","checkout")
            if not br: return False, "create_branch missing name"
            code, _, _ = git_run(f"git rev-parse --verify {shlex.quote(br)}", allow, deny, dry, timeout, cwd, env)
            if code == 0:
                if if_exists == "checkout":
                    code, _, err = git_run(f"git checkout {shlex.quote(br)}", allow, deny, dry, timeout, cwd, env)
                    if code != 0: return False, f"checkout failed: {err}"
                elif if_exists == "reset":
                    code, _, err = git_run(f"git checkout {shlex.quote(br)}", allow, deny, dry, timeout, cwd, env)
                    if code != 0: return False, f"checkout failed: {err}"
                    if base:
                        code, _, err = git_run(f"git reset --hard {shlex.quote(base)}", allow, deny, dry, timeout, cwd, env)
                        if code != 0: return False, f"reset failed: {err}"
                elif if_exists == "skip":
                    print("GIT create_branch: exists, skipping")
                else:
                    return False, f"unknown if_exists: {if_exists}"
            else:
                cmd = f"git checkout -B {shlex.quote(br)} {shlex.quote(base)}" if base else f"git checkout -b {shlex.quote(br)}"
                code, _, err = git_run(cmd, allow, deny, dry, timeout, cwd, env)
                if code != 0: return False, f"branch create failed: {err}"
            print(f"GIT create_branch OK name={br}")
        elif name == "checkout":
            br = op.get("name"); 
            if not br: return False, "checkout missing name"
            code, _, err = git_run(f"git checkout {shlex.quote(br)}", allow, deny, dry, timeout, cwd, env)
            if code != 0: return False, f"checkout failed: {err}"
            print(f"GIT checkout OK name={br}")
        elif name == "add":
            paths = op.get("paths", [])
            if not paths: return False, "add missing paths"
            quoted = " ".join(shlex.quote(p) for p in paths)
            code, _, err = git_run(f"git add {quoted}", allow, deny, dry, timeout, cwd, env)
            if code != 0: return False, f"add failed: {err}"
            print(f"GIT add OK paths={len(paths)}")
        elif name == "commit":
            msg = op.get("message","").replace('"','\\"')
            if not msg: return False, "commit missing message"
            code, out, err = git_run(f'git commit -m "{msg}"', allow, deny, dry, timeout, cwd, env)
            if code != 0: return False, f"commit failed: {err or out or 'no output'}"
            print("GIT commit OK")
        elif name == "status":
            code, out, err = git_run("git status --porcelain=v1 -b", allow, deny, dry, timeout, cwd, env)
            if out.strip(): print("STDOUT_BEGIN"); print(out.rstrip()); print("STDOUT_END")
            if err.strip(): print("STDERR_BEGIN"); print(err.rstrip()); print("STDERR_END")
            if code != 0: return False, "status failed"
        else:
            return False, f"unsupported git_op: {name}"
    return True, "ok"

def handle_rojo_build(step, allow, deny, dry, timeout, cwd, env, repo_root):
    project = step.get("project","default.project.json")
    output  = step.get("output",".connector/out/roblox-soccer.rbxlx")
    pathlib.Path(repo_root, ".connector/out").mkdir(parents=True, exist_ok=True)
    cmd = f'rojo build -o {shlex.quote(output)} {shlex.quote(project)}'
    if has_deny(cmd, deny): return False, "deny_pattern"
    if not allow_bin(cmd, allow): return False, f"not_in_allowlist:{shlex.split(cmd)[0]}"
    code, out, err = (run_dry(cmd) if dry else run_shell(cmd, timeout, cwd, env))
    if out.strip(): print("STDOUT_BEGIN"); print(out.rstrip()); print("STDOUT_END")
    if err.strip(): print("STDERR_BEGIN"); print(err.rstrip()); print("STDERR_END")
    return (code == 0), (out or err or "ok")

def detect_rbxcloud(cwd, env):
    # Try common flags in order; accept first success
    for cmd in ("rbxcloud --version", "rbxcloud -V", "rbxcloud --help"):
        code, out, err = run_shell(cmd, 20, cwd, env)
        if code == 0:
            text = (out or err).strip()
            return True, f"{cmd.split()[0]} {text}"
    return False, (err.strip() if 'err' in locals() else "")

def handle_rbx_preflight(step, env, cwd):
    u = str(step.get("universe_id") or env.get("UNIVERSE_ID","")).strip()
    p = str(step.get("place_id")    or env.get("PLACE_ID","")).strip()
    ok = True
    if not re.fullmatch(r"\d+", u or ""): print("PREFLIGHT FAIL universe_id_missing_or_invalid"); ok = False
    else: print(f"PREFLIGHT OK universe_id={u}")
    if not re.fullmatch(r"\d+", p or ""): print("PREFLIGHT FAIL place_id_missing_or_invalid"); ok = False
    else: print(f"PREFLIGHT OK place_id={p}")
    print("PREFLIGHT OK rojo_version/local: attempting 'rojo --version'")
    # Tools
    code, out, err = run_shell("rojo --version", 20, cwd, env)
    print(("ROJO_OK " + out.strip()) if code == 0 else ("ROJO_FAIL " + (err.strip() or out.strip())))
    ok2, text = detect_rbxcloud(cwd, env)
    print(("RBXCLOUD_OK " + text) if ok2 else ("RBXCLOUD_FAIL " + text))
    return ok and code == 0 and ok2

def read_plan(arg):
    if arg == "-":
        try: return json.loads(sys.stdin.read())
        except Exception as e: eprint(f"[FATAL] failed to read plan from stdin: {e}"); sys.exit(4)
    p = pathlib.Path(arg)
    if not p.exists(): eprint(f"[FATAL] plan not found: {p}"); sys.exit(3)
    with p.open("r", encoding="utf-8") as f: return json.load(f)

def main():
    cfg = load_cfg()
    print("BOT_OK"); print("CONFIG_OK")

    if len(sys.argv) < 3 or sys.argv[1] != "--plan":
        print("USAGE: bot_runner.py --plan <path|->"); sys.exit(0)

    plan = read_plan(sys.argv[2])
    dry_default = bool(cfg.get("dry_run_default", True))
    dry = bool(plan.get("dry_run", dry_default))
    allow = set(cfg.get("allowlist_bins", []))
    deny = list(cfg.get("deny_patterns", []))
    timeouts = cfg.get("timeouts", {})
    run_timeout = int(timeouts.get("run_sec", 120))
    cwd = cfg.get("workdir", ".")
    repo_root = cfg.get("repo_root",".")
    print(f"PLAN_OK dry_run={str(dry).lower()} steps={len(plan.get('steps',[]))}")

    idx = 0
    for step in plan.get("steps", []):
        idx += 1
        stype = step.get("type"); print(f"STEP {idx} TYPE={stype}")

        if stype == "run":
            cmd = step.get("cmd","").strip()
            if not cmd: print(f"STEP {idx} FAIL reason=empty_cmd"); sys.exit(10)
            if has_deny(cmd, deny): print(f"STEP {idx} FAIL reason=deny_pattern"); sys.exit(11)
            if not allow_bin(cmd, allow): print(f"STEP {idx} FAIL reason=not_in_allowlist bin={shlex.split(cmd)[0]}"); sys.exit(12)
            t0 = time.time()
            code, out, err = (run_dry(cmd) if dry else run_shell(cmd, run_timeout, cwd, os.environ))
            dt = round(time.time() - t0, 3)
            log_report({"step": idx, "type": "run", "cmd": cmd, "code": code, "ms": int(dt*1000)})
            if code == 0:
                print(f"STEP {idx} OK code=0 dur_s={dt}")
                if out.strip(): print("STDOUT_BEGIN"); print(out.rstrip()); print("STDOUT_END")
                if err.strip(): print("STDERR_BEGIN"); print(err.rstrip()); print("STDERR_END")
            else:
                print(f"STEP {idx} FAIL code={code} dur_s={dt}"); sys.exit(20)

        elif stype == "write_files":
            files_map = step.get("files", {})
            if not isinstance(files_map, dict) or not files_map:
                print(f"STEP {idx} FAIL reason=empty_files"); sys.exit(30)
            t0 = time.time()
            for rel, spec in files_map.items():
                enc = (spec.get("encoding","utf8").lower() if isinstance(spec,dict) else "utf8")
                print(f"PLAN_WRITE {rel} encoding={enc}")
            write_files(files_map, repo_root, dry)
            dt = round(time.time() - t0, 3)
            log_report({"step": idx, "type": "write_files", "count": len(files_map), "ms": int(dt*1000)})
            print(f"STEP {idx} OK dur_s={dt}")

        elif stype == "git_ops":
            ops = step.get("ops", [])
            if not isinstance(ops, list) or not ops:
                print(f"STEP {idx} FAIL reason=empty_ops"); sys.exit(50)
            ok, msg = handle_git_ops(ops, allow, deny, dry, run_timeout, cwd, os.environ)
            if ok: print(f"STEP {idx} OK")
            else: print(f"STEP {idx} FAIL reason={msg}"); sys.exit(51)

        elif stype == "rojo_build":
            ok, msg = handle_rojo_build(step, allow, deny, dry, run_timeout, cwd, os.environ, repo_root)
            if ok: print(f"STEP {idx} OK")
            else: print(f"STEP {idx} FAIL reason={msg}"); sys.exit(60)

        elif stype == "rbx_preflight":
            ok = handle_rbx_preflight(step, os.environ, cwd)
            if ok: print(f"STEP {idx} OK")
            else: print(f"STEP {idx} FAIL reason=preflight"); sys.exit(70)

        elif stype == "validate":
            checks = step.get("checks", [])
            if not isinstance(checks, list) or not checks:
                print(f"STEP {idx} FAIL reason=empty_checks"); sys.exit(40)
            all_ok = validate_checks(checks, repo_root, allow, deny, dry, run_timeout, cwd, os.environ)
            if all_ok: print(f"STEP {idx} OK")
            else: print(f"STEP {idx} FAIL reason=validation"); sys.exit(41)

        else:
            print(f"STEP {idx} FAIL reason=unsupported_type:{stype}"); sys.exit(13)

    print("PLAN_DONE status=ok"); sys.exit(0)

if __name__ == "__main__":
    main()
