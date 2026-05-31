import pytest
import os

@pytest.fixture(autouse=True)
def clean_up_test_files():
    # Remove files if they exist before test
    tests_dir = os.path.dirname(os.path.abspath(__file__))
    files_to_remove = [
        os.path.join(tests_dir, "python_args.txt"),
        os.path.join(tests_dir, "mock_pwd.txt")
    ]
    for f in files_to_remove:
        if os.path.exists(f):
            os.remove(f)
    yield
    # Remove files if they exist after test
    for f in files_to_remove:
        if os.path.exists(f):
            os.remove(f)
