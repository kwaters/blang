import unittest

def suite():
    suite = unittest.TestLoader().discover('tests')
    return suite
