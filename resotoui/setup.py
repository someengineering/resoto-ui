import resotoui
from setuptools import setup, find_packages


with open("README.md") as f:
    readme = f.read()


setup(
    name=resotoui.__title__,
    version=resotoui.__version__,
    description=resotoui.__description__,
    license=resotoui.__license__,
    packages=find_packages(),
    long_description=readme,
    long_description_content_type="text/markdown",
    include_package_data=True,
    zip_safe=False,
    install_requires=[],
    setup_requires=[],
    tests_require=[],
    classifiers=[
        # Current project status
        "Development Status :: 4 - Beta",
        # Audience
        "Intended Audience :: System Administrators",
        "Intended Audience :: Information Technology",
        # License information
        "License :: OSI Approved :: Apache Software License",
        # Supported python versions
        "Programming Language :: Python :: 3.9",
        # Supported OS's
        "Operating System :: POSIX :: Linux",
        "Operating System :: Unix",
        # Extra metadata
        "Environment :: Console",
        "Natural Language :: English",
        "Topic :: Security",
        "Topic :: Utilities",
    ],
    keywords="cloud security",
)
