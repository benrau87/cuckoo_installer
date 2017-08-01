import os
import shlex
import json
import logging

from common.abstracts import Package
from common.results import NetlogFile

log = logging.getLogger("analyzer")

class CustomExe(Package):
    """RogueKiller analysis package."""

    def start(self, path):
        args = self.options.get("arguments", "")

        name, ext = os.path.splitext(path)
        if not ext:
            new_path = name + ".exe"
            os.rename(path, new_path)
            path = new_path

        return self.execute(path, args=shlex.split(args))

    # Post execution
    def finish(self):
        nf = NetlogFile("logs/post.json")
        nf.send(json.dumps(['foo', {'bar': ('baz', None, 1.0, 2, False)}]))
        return True
