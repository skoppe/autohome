module openzwave;

import std.traits;
import utils;

enum GenericClass : ubyte {
  RemoteController = 0x01,
    StaticController = 0x02,
    AVControlPoint = 0x03,
    Display,
    NetworkExtender,
    Appliance,
    NotificationSensor,
    Thermostat,
    WindowCovering,
    RepeaterSlave = 0x0f,
    BinarySwitch,
    MultilevelSwitch,
    RemoteSwitch,
    ToggleSwitch,
    ZIPGateway,
    ZIPNode,
    Ventilation,
    SecurityPanel,
    WallController,
    BinarySensor = 0x20,
    MultilevelSensor,
    PulseMeter = 0x30,
    Meter,
    EntryControl = 0x40,
    SemiInteroperable = 0x50,
    AlarmSensor = 0xa1,
    NonInteroperable = 0xff
    }
auto getGenericClass(SpecificClass cls) {
  return cast(GenericClass)(cls >> 8);
}

enum CommandClass {
  ThermostatSetpoint = 0x43,
  SensorMultilevelV2 = 0x31,
  SwitchMultilevelV2 = 0x26,
  Battery  = 0x80,
  SwitchBinary = 0x25
}

enum SpecificClass : ushort {
  PortableRemoteController = ( GenericClass.RemoteController << 8 ) + 1,
    PortableSceneController,
    PortableInstallerTool,
    RemoveControlAV,
    RemoveControlSimple,
    StaticPCController = ( GenericClass.StaticController << 8 ) + 1,
    StaticSceneController,
    StaticInstallerTool,
    SetTopBox,
    SubSystemControler,
    TV,
    Gateway,
    SoundSwitch = ( GenericClass.AVControlPoint << 8 ) + 1,
    SatelliteReceiver,
    SatelliteReceiverV2,
    Doorbell,
    SimpleDisplay = ( GenericClass.Display << 8 ) + 1,
    SecureExtender = ( GenericClass.NetworkExtender << 8 ) + 1,
    GeneralAppliance = ( GenericClass.Appliance << 8 ) + 1,
    KitchenAppliance,
    LaundryAppliance,
    NotificationSensor = ( GenericClass.NotificationSensor << 8 ) + 1,
    HeatingThermostat = ( GenericClass.Thermostat << 8 ) + 1,
    GeneralThermostat,
    SetbackScheduleThermostate,
    SetpointThermostat,
    SetbackThermostat,
    GeneralThermostatV2,
    SimpleWindowCovering = (GenericClass.WindowCovering << 8) + 1,
    BasicRepeaterSlave = (GenericClass.RepeaterSlave << 8) + 1,
    VirtualNode,
    BinaryPowerSwitch = (GenericClass.BinarySwitch << 8) + 1,
    BinaryTunableColorLight,
    BinarySceneSwitch,
    PowerStrip,
    Siren,
    ValveOpenClose,
    IrrigrationControl,
    MultilevelPowerSwitch = (GenericClass.MultilevelSwitch << 8) + 1,
    MultilevelTunableColorLight,
    MultipositionMotor,
    MultilevelSceneSwitch,
    MotorControlClassA,
    MotorControlClassB,
    MotorControlClassC,
    FanSwitch,
    BinaryRemoteSwitch = (GenericClass.RemoteSwitch << 8) + 1,
    MultilevelRemoteSwitch,
    BinaryToggleRemoteSwitch,
    MultilevelToggleRemoteSwitch,
    BinaryToggleSwitch = (GenericClass.ToggleSwitch << 8) + 1,
    MultilevelToggleSwitch,
    ZIPTunnelingGateway = (GenericClass.ZIPGateway << 8) + 1,
    ZIPAdvancedGateway,
    ZIPTunnelingNode = (GenericClass.ZIPNode << 8) + 1,
    ZIPAdvancedNode,
    ResidentialHeatRecoveryVentilation = (GenericClass.Ventilation << 8) + 1,
    ZonedSecurityPanel = (GenericClass.SecurityPanel << 8) + 1,
    BasicWallController = (GenericClass.WallController << 8) + 1,
    RoutingBinarySensor = (GenericClass.BinarySensor << 8) + 1,
    RoutingMultilevelSensor = (GenericClass.MultilevelSensor << 8) + 1,
    ChimneyFan,
    SimpleMeter = (GenericClass.Meter << 8) + 1,
    AdvancedEnergyControl,
    WholeHomeMeterSimple,
    DoorLock = (GenericClass.EntryControl << 8) + 1,
    AdvancedDoorLock,
    SecureKeypadDoorLock,
    SecureKeypadDoorLockDeadBolt,
    SecureDoor,
    SecureGate,
    SecureBarrierAddOn,
    SecureBarrierOpenOnly,
    SecureBarrierCloseOnly,
    SecureLockBox,
    SecureKeypad,
    EnergyProduction = ( GenericClass.SemiInteroperable << 8 ) + 1,
    BasicRoutingAlarmSensor = ( GenericClass.AlarmSensor << 8 ) + 1,
    RoutingAlarmSensor,
    BasicZensorAlarmSensor,
    ZensorAlarmSensor,
    AdvancedZensorAlarmSensor,
    BasicRoutingSmokeSensor,
    RoutingSmokeSensor,
    BasicZensorSmokeSensor,
    ZensorSmokeSensor,
    AdvancedZensorSmokeSensor,
    AlarmSensor
    }

struct ZWaveNode {
  ubyte basic;
  SpecificClass specific;
  GenericClass generic;
  uint homeId;
  ubyte nodeId;
  ushort manufacturerId;
  ushort productId;
  string manufacturerName;
  string productName;
  string id;
}

struct ZWaveValue {
  uint homeId;
  ubyte nodeId;
  string label;
  CommandClass commandClass;
  ubyte instance;
  ushort index;
  ValueGenre genre;
  ValueType type;
  string value;
  string id;
}

auto get(T)(ref const ZWaveValue value) {
  static if (is(T == bool)) {
    return value.value == "true";
  } else static if (isNumeric!(T)) {
    return value.value.to!T;
  } else if (is(T : string)) {
    return value.value;
  } else
    static assert("Not implemented for"~T.stringof);
}

enum ValueGenre { Basic,
                  User,
                  Config,
                  System
}

enum ValueType { Bool,
                 Byte,
                 Decimal,
                 Int,
                 List,
                 Schedule,
                 Short,
                 String,
                 Button,
                 Raw,
                 BitSet
}
