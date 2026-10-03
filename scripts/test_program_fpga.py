"""Check programmer completion rules with a fake executable, without hardware."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


class ProgrammerResultTest(unittest.TestCase):
    def test_completion_rules(self):
        script = Path(__file__).with_name("program_fpga.sh")
        with tempfile.TemporaryDirectory(prefix="tangnano-program-test-") as directory:
            fake = Path(directory) / "fake programmer"
            fake.write_text('#!/bin/sh\nprintf "%s\\n" "$FAKE_OUTPUT"\nexit "$FAKE_EXIT"\n')
            fake.chmod(0o755)
            for output, code, expected in [
                ("Finished", 0, 0),
                ("Error: failed\nFinished", 0, 1),
                ("error: failed", 0, 1),
                ("Incomplete", 0, 1),
                ("Not Finished", 0, 1),
                ("UnFinished", 0, 1),
                ("Finished with errors", 0, 1),
                ("Finished", 50, 1),
                ("Finished", 17, 1),
                ("Error: failed", 1, 1),
            ]:
                with self.subTest(output=output, code=code):
                    env = dict(os.environ, FAKE_OUTPUT=output, FAKE_EXIT=str(code), TMPDIR=directory)
                    result = subprocess.run(
                        [str(script), str(fake), "test-device", "bitstream with spaces.fs"],
                        env=env, capture_output=True, text=True,
                    )
                    self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
                    self.assertEqual(list(Path(directory).glob("tangnano-program.*")), [])


if __name__ == "__main__":
    unittest.main()
