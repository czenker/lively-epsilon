#### to be released

* **[BREAKING]** functions given to `Comms:newReply` had their first argument (`self`) removed. There was no reason
  to use this. Instead of
   
      Comms:newReply("label", function(self, comms_target, comms_source)
          return Comms:screen("Hello World")
      end, function(self, comms_target, comms_source)
          return comms_source:isDocked(comms_target)
      end)
    
  just omit the `self` and use
  
      Comms:newReply("label", function(comms_target, comms_source)
          return Comms:screen("Hello World")
      end, function(comms_target, comms_source)
          return comms_source:isDocked(comms_target)
      end)

* defaults for `Mission:scan`'s `scan` parameter have been changed. Up to now a friend-or-foe detection
  was sufficient to have a ship scanned (this could have happened without player interaction, if the enemy
  attacks the player). Now a `simple` scan is necessary. To get the old behavior back set `scan = "fof"`
  in the mission config.
* `Mission:scan` can now also be used to scan non-ship objects, like Asteroids or Stations. Make sure to call
  `object:setScanningParameters()` on those objects as they don't need to be scanned by default. 
* `Missions:crewForRent` now requires the player to have `Player:withMenu` set
* added `Player:withQuickDial()` to display quick dials on the relay station
* `Station:withStorage` can now handle Scan Probes as products. Use the id `scanProbe`.
* Missions can have event listeners added from outside via `mission:addSuccessListener()`, etc.
* `Mision:newChain()` allows to create chained missions where the next starts when the previous is finished
