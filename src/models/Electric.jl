"""
Modia module with electric component models (inspired from the Modelica Standard Library).

* Developer: Hilding Elmqvist, Mogram AB  
* Copyright (c) 2016-2018: Hilding Elmqvist, Toivo Henningsson, Martin Otter
* License: MIT (expat)

The building blocks for electric components are:

- `Pin` - The main connector representing an electrical node with variables 
    `v` and `i`.
- `OnePort` - Base model for an electric device with two `Pin`s with variables 
    `v`, `i`, `p`, and `n`.

The following functions define variables with appropriate units:

- `Voltage()` - Electric potential
- `Current()` - The main flow quantity
- `Resistance()`
- `Capacitance()`

"""
module Electric

using ..Instantiation
using ..Blocks
using ..Synchronous: positive
using SIUnits

using Modia

export Pin, Ground, OnePort, Resistor, Capacitor, Inductor, 
  ConstantVoltage, StepVoltage, SignalVoltage, SineVoltage, IdealOpAmp3Pin, IdealDiode,
  Voltage, Current, Resistance, Capacitance

"Electric potential, volts"
Voltage(; args...) = Variable(;T=Volt, size=(), start=0.0, args...)
"Electric current, amperes"
Current(; args...) = Variable(;T=Ampere, size=(), start=0.0, args...)
"Electric resistance, ohms"
Resistance(; args...) = Variable(;T=Ohm, size=(), args...)
"Electric capacitance, farads"
Capacitance(; args...) = Variable(;T=Farad, size=(), args...)

@model Pin1 begin
  v=Float()
  i=Float(flow=true)
end 

"""
An electric node for connections.

## Variables 

- `v` : node voltage
- `i` : current into the node (flow variable)
"""
@model Pin begin
  v=Voltage()
  i=Current(flow=true)
end 

"""
Grounded `Pin` with zero voltage.

## Variables 

- `p` : `Pin`
"""
@model Ground begin
  p=Pin()
@equations begin
  p.v = 0
  end
end 

@model OnePort1 begin
  v=Float()
  i=Float()
  p=Pin()
  n=Pin()
@equations begin
  v = p.v - n.v
  0 = p.i + n.i
  i = p.i
  end
end 

"""
Base model for an electric device with two `Pin`s.

## Variables 

- `v` : voltage across the device
- `i` : current through the device
- `p` : positive `Pin`
- `n` : negative `Pin`
"""
@model OnePort begin
#  v=Voltage()
#  i=Current()
  v=Voltage()
  i=Current()
  p=Pin()
  n=Pin()
@equations begin
  v = p.v - n.v
  0 = p.i + n.i
  i = p.i
  end
end 

"""
Ideal linear electric resistor.

## Variables 

- `R` : resistance of the device
- `v` : voltage across the device
- `i` : current through the device
- `p` : positive `Pin`
- `n` : negative `Pin`
"""
@model Resistor begin
  @extends OnePort()
  @inherits i, v
  R=1 # Parameter(start=1.0) # undefined # Resistance
@equations begin
  R*i = v
  end
end

@model Resistor1 begin
  p=Pin()
  n=Pin()
  v=Float()
  i=Float()
  R=Parameter(description="Resistance")
@equations begin
  v = p.v - n.v # Voltage drop
  0 = p.i + n.i # Kirchhoff's current law within component
  i = p.i
  R*i = v
  end
end 


"""
Ideal linear electric capacitor.

## Variables 

- `C` : capacitance of the device
- `v` : voltage across the device
- `i` : current through the device
- `p` : positive `Pin`
- `n` : negative `Pin`
"""
@model Capacitor begin
  @extends OnePort(v=Float(start=0.0))  # Setting state=false for v does not work with extends.
  @inherits i, v
#  C=Capacitance() # undefined
  C=undefined
@equations begin
  C*der(v) = i
#  der(v) = i/C
  end
end 

@model Capacitor1 begin
  p=Pin()
  n=Pin()
  v=Float()
  i=Float()
  C=undefined
@equations begin
  v = p.v - n.v # Voltage drop
  0 = p.i + n.i # Kirchhoff's current law within component
  i = p.i
  C*der(v) = i
  end
end 

"""
Ideal linear electric inductor.

## Variables 

- `L` : inductance of the device
- `v` : voltage across the device
- `i` : current through the device
- `p` : positive `Pin`
- `n` : negative `Pin`
"""
@model Inductor begin
  @extends OnePort()
  @inherits i, v
  L=Parameter()
  @equations begin 
  L*der(i) = v
  end
end

@model ConstantVoltage begin
  V=1*Volt
  @extends OnePort()
  @inherits v
@equations begin
  v = V
  end
end

@model StepVoltage begin
  V=1*Volt
  startTime = 0*Seconds
  t = Var(start=0.0)
  @extends OnePort()
  @inherits v
@equations begin
  v = if t < startTime; 0 else V end
  der(t) = 1
  end
end

@model SignalVoltage begin
    # Generic voltage source using the input signal as source voltage
  p=Pin()
  n=Pin()
  v=Float()
  i=Float()
@equations begin 
  v = p.v - n.v
  0 = p.i + n.i
  i = p.i
  end 
end 

@model VoltageSource begin
    # Interface for voltage sources
  @extends OnePort()
  @inherits v
  offset=0 # Voltage offset
  startTime=0 # Time offset 
  signalSource=SignalSource(offset = offset, startTime=startTime)
@equations begin 
  v = signalSource.y
  end 
end 

@model SineVoltage1 begin
    # Sine voltage source
  V=Parameter() # Amplitude of sine wave
  phase=0 # Phase of sine wave
  freqHz=Parameter() # Frequency of sine wave
  @extends VoltageSource(signalSource = Sine(amplitude=V, freqHz=freqHz, phase=phase))
end 

@model SineVoltage begin
    # Sine voltage source
  V=Parameter() # Amplitude of sine wave
  phase=0 # Phase of sine wave
  freqHz=Parameter() # Frequency of sine wave
#  @extends VoltageSource(signalSource = Sine())
  @extends VoltageSource(signalSource = Sine(amplitude=1,freqHz=1, offset=0, startTime=0))
#  @extends VoltageSource(signalSource = Sine(amplitude=V, freqHz=freqHz, phase=phase, 
#    offset=offset, startTime=startTime))
#  @inherits offset, startTime
end 


@model IdealOpAmp3Pin begin
    # Ideal operational amplifier (norator-nullator pair), but 3 pins
  in_p=Pin()
  in_n=Pin()
  out=Pin()
@equations begin 
  in_p.v = in_n.v
  in_p.i = 0
  in_n.i = 0
  end
end

@model IdealDiode begin # Ideal diode
  @extends OnePort()
  @inherits v, i
  s = Float(start=0.0) # Auxiliary variable for actual position on the ideal diode characteristic
#=   s = 0: knee point
     s < 0: below knee point, diode conducting
     s > 0: above knee point, diode locking 
=#
@equations begin
  v = if positive(s); 0 else s end
  i = if positive(s); s else 0 end 
  end
end 

@model IdealDiode2 begin # Ideal diode
  @extends OnePort()
  @inherits v, i
  Ron = 0 # 1.0E-5 # Forward state-on differential resistance (closed diode resistance)
  Goff = 0 # 1.0E-5 # Backward state-off conductance (opened diode conductance)
  Vknee = 0 # Forward threshold voltage
#  off = Variable(start=true) # Switching state
  s = Float(start=0.0) # Auxiliary variable for actual position on the ideal diode characteristic
#=  s = 0: knee point
     s < 0: below knee point, diode conducting
     s > 0: above knee point, diode locking 
=#
@equations begin
#  off := s < 0
  v = s*if ! positive(s); 1 else Ron end + Vknee
  i = s*if ! positive(s); Goff else 1 end + Goff*Vknee
  end
end 

@model IdealDiode1 begin # Ideal diode
  @extends OnePort()
  @inherits v, i
  Ron = 0 # 1.0E-5 # Forward state-on differential resistance (closed diode resistance)
  Goff = 0 # 1.0E-5 # Backward state-off conductance (opened diode conductance)
  Vknee = 0 # Forward threshold voltage
  off = Variable(start=true) # Switching state
  s = Float(start=0) # Auxiliary variable for actual position on the ideal diode characteristic
#=  s = 0: knee point
     s < 0: below knee point, diode conducting
     s > 0: above knee point, diode locking 
=#
@equations begin
  off := positive(-s*1.0)
  v = s*if off; 1 else Ron end + Vknee
  i = s*if off; Goff else 1 end + Goff*Vknee
  end
end 

end
