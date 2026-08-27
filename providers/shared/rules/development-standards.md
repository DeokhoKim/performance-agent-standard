# Development Standards

Section: Environment && Toolchain Resolution
Req: Local Environment Primacy: Enforce local project toolchains over system-level defaults to guarantee reproducible build, test, && execution tasks.
- Rule: Precedence Hierarchy: Build, test, run, && artifact validation MUST strictly follow: `Local Environment > System Environment > General Assumption`.
- Rule: Python Environment Resolution: Local virtual environment (`.venv/` || `venv/`) MUST take absolute precedence (e.g., `.venv/bin/python`, `.venv/bin/pip`, || `uv` targeting `.venv`); if `pyproject.toml` && `uv` exist → use `uv run`; if `requirements.txt` exists → use `uv pip` || `.venv/bin/pip`.
- Rule: Native && Polyglot Resolution: For C/C++, local toolchain definitions (`CC`, `CXX`, `CMakeLists.txt`, `Makefile`, local build artifacts) MUST override system compilers. For polyglot projects (Rust, Node, Go), local manifests (`Cargo.toml`, `package.json` with local package managers, `go.mod`) override global tools.
- Rule: README Fallback Protocol: If NO local environment || toolchain configuration is detected, a SINGLE targeted read of `README.md` (read once) is permitted to extract build/test/run instructions before falling back to general assumptions.
