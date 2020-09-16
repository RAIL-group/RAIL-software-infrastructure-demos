
def pytest_addoption(parser):
    parser.addoption("--unity_exe_path",
                     action="store",
                     default=None)
