import setuptools
from distutils.core import setup

with open("README.md", "r") as fh:
    long_description = fh.read()

setup(
    name="CNTtools",
    version="0.1",
    description="Pre-processing toolkit for iEEG data",
    install_requires=[
        "pennprov",
        "pyqt5-sip",
        "pytest",
        "beartype",
        "pytest-html",
    ],
    packages=setuptools.find_packages(),
    package_data={
        "CNTtools": ["test/data/*"],
    },
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/haoershi/CNT_research_tools",
)
