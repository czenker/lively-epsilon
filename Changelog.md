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
  
* added `Player:withQuickDial()` to display quick dials on the relay station