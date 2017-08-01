import os
import json
import codecs

from cuckoo.common.abstracts import Report
from cuckoo.common.exceptions import CuckooReportError

class Roguekiller(Report):
    """Saves custom results in JSON format."""   
    def run(self, results):
        """Writes report.
        @param results: Cuckoo results dict.
        @raise CuckooReportError: if fails to write report.
        """

        try:
            path = os.path.join(self.reports_path, "custom.json")

            with codecs.open(path, "w", "utf-8") as report:
                json.dump(results["custom"], report, sort_keys=False, indent=4)
        except (UnicodeError, TypeError, IOError) as e:
            raise CuckooReportError("Failed to generate JSON report: %s" % e)
