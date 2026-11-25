import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))

import system

BIG = "MemTotal:       16314364 kB\n"
SMALL = "MemTotal:        2048000 kB\n"
GPU = ["/dev/dri/renderD128"]


class LowEnd(unittest.TestCase):
    def test_capable_machine(self):
        self.assertFalse(system.low_end({}, BIG, GPU))

    def test_small_ram(self):
        self.assertTrue(system.low_end({}, SMALL, GPU))

    def test_no_render_node(self):
        self.assertTrue(system.low_end({}, BIG, []))

    def test_software_backends(self):
        self.assertTrue(system.low_end({"QT_QUICK_BACKEND": "software"}, BIG, GPU))
        self.assertTrue(system.low_end({"GALLIUM_DRIVER": "llvmpipe"}, BIG, GPU))
        self.assertTrue(system.low_end({"LIBGL_ALWAYS_SOFTWARE": "1"}, BIG, GPU))
        self.assertFalse(system.low_end({"LIBGL_ALWAYS_SOFTWARE": "0"}, BIG, GPU))

    def test_override_wins(self):
        self.assertFalse(system.low_end({"WEKA_LOW_END": "0", "QT_QUICK_BACKEND": "software"}, SMALL, []))
        self.assertTrue(system.low_end({"WEKA_LOW_END": "1"}, BIG, GPU))

    def test_garbage_override_ignored(self):
        self.assertFalse(system.low_end({"WEKA_LOW_END": "maybe"}, BIG, GPU))

    def test_meminfo_parse(self):
        self.assertEqual(system.mem_total_kb(BIG), 16314364)
        self.assertIsNone(system.mem_total_kb(""))
        self.assertIsNone(system.mem_total_kb("MemTotal: lots kB"))


class Reduced(unittest.TestCase):
    def test_follows_low_end(self):
        self.assertTrue(system.reduced_motion({}, low=True))
        self.assertFalse(system.reduced_motion({}, low=False))

    def test_override(self):
        self.assertFalse(system.reduced_motion({"WEKA_REDUCE_MOTION": "0"}, low=True))
        self.assertTrue(system.reduced_motion({"WEKA_REDUCE_MOTION": "1"}, low=False))


if __name__ == "__main__":
    unittest.main()
