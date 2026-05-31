#!/usr/bin/env python3
import subprocess
import sys
import os

test_files = [f for f in os.listdir('test') if f.endswith('.vim')]

all_passed = True
for test_file in test_files:
    print(f"Running {test_file}...")
    res = subprocess.run(["vim", "--clean", "-es", "-S", os.path.join("test", test_file)], capture_output=True, text=True)
    if res.returncode == 0:
        print(f"✅ {test_file} passed")
    else:
        print(f"❌ {test_file} failed")
        print("STDOUT:", res.stdout)
        print("STDERR:", res.stderr)
        all_passed = False

if all_passed:
    sys.exit(0)
else:
    sys.exit(1)
