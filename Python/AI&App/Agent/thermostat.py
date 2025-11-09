class ThermoStatReflexAgent:
    def __init__(self,set_point:float):
        self.set_point=set_point
        
    def act(self,current_temp:float):
        if current_temp < self.set_point:
            return 'HEATER_ON'
        else:
            return 'HERATER_OFF'


class AutoDoorReflexAgent:
    def act(self,motion_detected:bool):
        return 'OPEN' if motion_detected else 'CLOSE'
    
if __name__ == "__main__":  
    thermo=ThermoStatReflexAgent(set_point=22.0)
    for temp in [20.5, 22.0, 23.5]:
        action=thermo.act(current_temp=temp)
        print(f"Current Temp: {temp}°C -> Action: {action}")

    door=AutoDoorReflexAgent()
    for motion in [True, False]:
        action=door.act(motion_detected=motion)
        print(f"Motion Detected: {motion} -> Action: {action}")