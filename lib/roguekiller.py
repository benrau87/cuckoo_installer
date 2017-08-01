import logging
import json

from common.abstracts import Auxiliary
from common.results import NetlogFile

log = logging.getLogger(__name__)

class Custom(Auxiliary):
    """Gather custom data"""

    def __init__(self, options={}, analyzer=None):
        Auxiliary.__init__(self, options, analyzer)

    def start(self):
        log.info("Starting my Custom auxiliary module")
        nf = NetlogFile("logs/initial.json")
        nf.send(json.dumps(['foo', {'bar': ('baz', None, 1.0, 2, False)}]))
