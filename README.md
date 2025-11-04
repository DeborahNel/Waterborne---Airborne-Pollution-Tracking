A blockchain-based pollution monitoring system that provides immutable, sensor-verified environmental data with automated compliance enforcement.

## 🎯 Problem Statement

Industries often underreport pollution levels, causing significant harm to ecosystems and communities. Traditional monitoring systems lack transparency and can be manipulated.

## 💡 Solution

This smart contract creates an immutable blockchain ledger of pollution data verified through IoT sensors, with automatic penalty mechanisms for non-compliance.

## ⚡ Key Features

- 📊 **Real-time Sensor Data Logging**: IoT sensors submit pollution readings directly to blockchain
- 🏭 **Automated Compliance Monitoring**: Automatic violation detection based on configurable thresholds
- 💰 **Token-based Penalty System**: Violators receive penalty tokens that can be tracked publicly
- 🔒 **Stake-based Sensor Registration**: Operators must stake STX to ensure data integrity
- 👮 **Role-based Access Control**: Only authorized operators can register and manage sensors
- 📈 **Environmental Scoring**: Calculate environmental performance scores for locations
- 🔄 **Sensor Ownership Transfer**: Seamlessly transfer sensor ownership between authorized operators
- 🔄 **Dynamic Sensor Updates**: Modify sensor metadata without re-registration

## 🛠️ Technical Stack

- **Blockchain**: Stacks (Bitcoin L2)
- **Smart Contract**: Clarity
- **Development**: Clarinet
- **Token Standard**: Custom fungible token for penalties

## 📋 Contract Functions

### Public Functions

#### Sensor Management
- `register-sensor(location, sensor-type)` - Register new pollution sensor
- `deactivate-sensor(sensor-id)` - Deactivate sensor and withdraw stake
- `transfer-sensor-ownership(sensor-id, new-owner)` - Transfer sensor ownership to another authorized operator
- `update-sensor-info(sensor-id, new-location, new-sensor-type)` - Update sensor location and type
- `submit-pollution-reading(...)` - Submit sensor readings with auto-violation detection

#### Administration
- `initialize-thresholds()` - Set default pollution thresholds
- `authorize-operator(operator)` - Authorize sensor operators
- `revoke-operator(operator)` - Revoke operator authorization
- `update-compliance-threshold(type, level)` - Update pollution limits
- `emergency-shutdown-sensor(sensor-id)` - Emergency sensor shutdown

### Read-only Functions

- `get-sensor(sensor-id)` - Retrieve sensor information
- `get-pollution-reading(sensor-id, timestamp)` - Get specific reading
- `get-compliance-threshold(pollution-type)` - Get threshold values
- `calculate-environmental-score(sensor-id)` - Calculate performance score
- `is-authorized-operator(operator)` - Check operator authorization

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet) installed
- Stacks wallet for testing

### Installation

1. Clone the repository:
```bash
git clone https://github.com/DeborahNel/Waterborne---Airborne-Pollution-Tracking.git
cd Waterborne---Airborne-Pollution-Tracking
```

2. Initialize Clarinet (if not already done):
```bash
clarinet check
```

3. Run tests:
```bash
clarinet test
```

### Usage Examples

#### 1. Initialize Contract (Owner Only)
```bash
# Set default pollution thresholds
(contract-call? .pollution-tracker initialize-thresholds)
```

#### 2. Authorize Sensor Operator
```bash
# Owner authorizes an operator
(contract-call? .pollution-tracker authorize-operator 'SP1ABCD...)
```

#### 3. Register Sensor
```bash
# Operator registers a sensor (requires 10,000 µSTX stake)
(contract-call? .pollution-tracker register-sensor "Downtown River, Sector 7" "water-quality")
```

#### 4. Submit Pollution Reading
```bash
# Submit sensor data (pH as 7.2, DO as 8.5 mg/L, PM2.5 as 25 µg/m³, etc.)
(contract-call? .pollution-tracker submit-pollution-reading
    u1          ; sensor-id
    u720        ; water-pH (7.20)
    u850        ; dissolved-oxygen (8.50 mg/L)
    u2500       ; air-PM2.5 (25.00 µg/m³)
    u4000       ; air-PM10 (40.00 µg/m³)
    u38000      ; air-CO2 (380.00 ppm)
    u2500       ; temperature (25.00°C)
    u6500       ; humidity (65.00%)
)
```

#### 5. Update Sensor Information
#### 6. Transfer Sensor Ownership
```bash
# Current owner transfers sensor to another authorized operator
(contract-call? .pollution-tracker transfer-sensor-ownership u1 'SP2EFGH...)
```
```bash
# Operator updates sensor location and type
(contract-call? .pollution-tracker update-sensor-info u1 "New Downtown River, Sector 8" "advanced-water-quality")
```

## 📊 Data Format

### Pollution Reading Parameters
- **Water pH**: Stored as `pH × 100` (e.g., 7.2 pH = 720)
- **Dissolved Oxygen**: Stored as `DO × 100` mg/L (e.g., 8.5 mg/L = 850)
- **PM2.5**: Stored as `concentration × 100` µg/m³ (e.g., 25 µg/m³ = 2500)
- **PM10**: Stored as `concentration × 100` µg/m³
- **CO2**: Stored as `concentration × 100` ppm
- **Temperature**: Stored as `temp × 100` °C
- **Humidity**: Stored as `humidity × 100` %

### Default Compliance Thresholds
- **Water pH**: 6.5 - 8.5
- **Dissolved Oxygen**: ≥ 5.0 mg/L
- **PM2.5**: ≤ 35 µg/m³
- **PM10**: ≤ 50 µg/m³
- **CO2**: ≤ 400 ppm

## 🏆 Token Economics
- Sensor ownership transfer capabilities

- **Stake Requirement**: 10,000 µSTX per sensor
- **Penalty Rate**: 1,000 compliance tokens per violation
- **Environmental Score**: 100 - (violations × 10), minimum 50

## 🔐 Security Features

- Operator authorization system
- Stake-based sensor registration
- Emergency shutdown capabilities
- Immutable data logging
- Automatic penalty enforcement

## 🌍 Environmental Impact

This system promotes:
- 🎯 **Transparency**: All pollution data publicly verifiable
- ⚖️ **Accountability**: Automatic penalties for violations
- 📊 **Data Integrity**: Blockchain immutability prevents tampering
- 🏭 **Industry Compliance**: Economic incentives for better practices

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For support, email support@pollutiontracker.com or join our Discord community.

---

Built with ❤️ for a cleaner planet 🌱
