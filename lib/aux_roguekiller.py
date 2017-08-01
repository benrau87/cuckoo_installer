#!/usr/bin/env python
import logging
import os
import shlex
import json
import logging
import urllib2
import tempfile

from common.abstracts import Auxiliary
from common.results import NetlogFile
from common.results import upload_to_host
from api.process import Process
from common.defines import KERNEL32

log = logging.getLogger(__name__)

class Roguekiller(Auxiliary):
    """Gather custom data"""

    def __init__(self, options={}, analyzer=None):
        Auxiliary.__init__(self, options, analyzer)
        
    def start(self):
        pass

    def finish(self):        
        # removal scanner
        log.info("RogueKiller: Starting removal")
        try: 
          #download
          response = urllib2.urlopen("http://www.adlice.com/download/roguekiller/?wpdmdl=59&ind=aHR0cDovL2Rvd25sb2FkLmFkbGljZS5jb20vYXBpP2FjdGlvbj1kb3dubG9hZCZhcHA9cm9ndWVraWxsZXImdHlwZT14NjQ")
          f = tempfile.NamedTemporaryFile(delete=False)           
          data = response.read()   
          f.write(data)
           
          #rename
          path = f.name + ".exe"          
          f.close()
          os.rename(f.name, path)
          log.info("Downloaded remover program to %s", path)        
          

          #execute (without injection, too many problems)
          args = "-scan \"-pupismalware -pumismalware -autodelete -portable-license C:\\rk_config.ini -reportpath C:\\rkcmd.log -reportformat txt\" -dont_ask"
          #pid  = self.execute(path, args=shlex.split(args))
          p = Process()
          
          # we need to lock the analyzer while we start and exclude our remover process
          self.analyzer.process_lock.acquire()
          
          if not p.execute(path=path, args=shlex.split(args), free=True):
            raise CuckooPackageError("Unable to execute the initial process, ""analysis aborted.")
          pid = p.pid  
          
          # add to monitored list, so that it will never tried to be injected
          self.analyzer.process_list.add_pid(pid)
          
          # unlock
          self.analyzer.process_lock.release()
          
          log.info("Executing remover program with args: %s", args)

          #wait for end
          while Process(pid=pid).is_alive():
              KERNEL32.Sleep(1000)
          
          #get report
          upload_to_host("C:\\rkcmd.log", "logs/removal.log")
          log.info("Executed remover program with args: %s", args)

        except Exception, e:
          log.exception("Error while loading the remover program")           
