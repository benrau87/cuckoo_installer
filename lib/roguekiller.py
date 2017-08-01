import os
import json

from cuckoo.common.abstracts import Processing
from cuckoo.common.exceptions import CuckooProcessingError

class Roguekiller(Processing):
    """Roguekiller analysis information."""

    def run(self):
        """Run debug analysis.
        @return: debug information dict.
        """
        self.key = "roguekiller"
        data = {}
        try:
          #initial
          custom_log = os.path.join(self.logs_path, "initial.json")
          with open(custom_log) as json_file:          
            data["initial"] = json.load(json_file)
        except Exception, e:
          raise CuckooProcessingError(str(e))

        try:
          #post
          custom_log = os.path.join(self.logs_path, "post.json")
          with open(custom_log) as json_file:          
            data["post"] = json.load(json_file)
        except Exception, e:
          raise CuckooProcessingError(str(e))

        return data
