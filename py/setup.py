from setuptools import setup, find_packages

setup(
    name='blang',
    version='1.0.0',
    url='https://github.com/kwaters/blang',

    author='Kenneth Waters',
    author_email='kwwaters@gmail.com',

    license='MIT',

    packages=find_packages(exclude=['tests']),
    install_requires = [],

    test_suite = 'tests.suite'
)
