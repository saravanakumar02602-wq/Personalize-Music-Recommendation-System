import os
import subprocess
import sys


ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
APP_PATH = os.path.join(ROOT_DIR, "python", "app.py")


def main() -> int:
    if not os.path.exists(APP_PATH):
        print(f"Application entry point not found: {APP_PATH}")
        return 1

    cmd = [sys.executable, APP_PATH]
    if len(sys.argv) > 1:
        cmd.extend(sys.argv[1:])

    try:
        return subprocess.run(cmd, cwd=ROOT_DIR).returncode
    except KeyboardInterrupt:
        print("\nApplication interrupted by user.")
        return 130


if __name__ == "__main__":
    raise SystemExit(main())
