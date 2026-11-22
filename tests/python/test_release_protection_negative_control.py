"""Temporary negative control for issue 37. This branch must never merge."""
import unittest


class RequiredCoreCheck(unittest.TestCase):
    def test_release_protection_negative_control(self):
        self.fail("Intentional issue 37 branch-protection negative control")
