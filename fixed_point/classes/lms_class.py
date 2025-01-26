
class lms_class:

    def __init__(self, step, leak):
        self.step = step
        self.leak = leak

    
    def update(self, errI, errQ, tapsI, shftrI, tapsQ, shftrQ):
        new_tapsI = (tapsI*(1-self.step*self.leak) - 
                      self.step*(errI*shftrI + errQ*shftrQ))
        new_tapsQ = (tapsQ*(1-self.step*self.leak) +
                      self.step*(errI*shftrQ - errQ*shftrI))
        
        return new_tapsI, new_tapsQ
