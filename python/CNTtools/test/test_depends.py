"""
A simple test script to check if all dependencies are installed
"""
import traceback
import pytest

print("---- Running Dependencies Test ----")

dep = ["pandas", "numpy", "beartype", "typing", "seaborn", "ieeg"]

print("\n~ Requires: " + str(dep)[1:-1] + "\n")

passed = True


@pytest.mark.parametrize("case", list(range(len(dep))))
def test_case(case):
    global passed
    try:
        print("~ Checking dependency:", dep[case])
        if case == 0:
            import pandas as pd
        elif case == 1:
            import numpy as np
        elif case == 2:
            from beartype import beartype
        elif case == 3:
            from typing import Union
        elif case == 4:
            import seaborn as sns
        elif case == 5:
            from ieeg.auth import Session
        print("~ Import successful.")
    except:
        print(traceback.format_exc())
        print("~ Import failed!")
        passed = False


if passed:
    print("\nDependencies Test PASSED! :)\n")
else:
    print("\n~ Dependencies Test failed :(\n")
