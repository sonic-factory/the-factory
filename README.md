# 🏭 The Factory

**A comprehensive smart contract factory suite for rapid blockchain deployment of tokens, NFTs, and financial instruments.**

The Factory is a modular ecosystem of factory contracts that enable one-click deployment of standardized smart contracts with customizable parameters. Built with security, gas efficiency, and developer experience in mind.

## 🌟 Features

### 🪙 Token Factories
- **Standard ERC20**: Deploy feature-complete ERC20 tokens with minting and burning capabilities
- **Tax Token**: Create ERC20 tokens with configurable transfer taxes and exemption lists
- Upgradeable implementations using OpenZeppelin's proven patterns
- Built-in fee collection and treasury management

### 🎨 NFT Factory
- **Standard NFT**: Deploy ERC721 collections with metadata management
- Configurable base URI with optional metadata locking
- Owner-controlled minting with built-in supply tracking

### 🔒 Vesting & Locking
- **Token Vesting**: Time-locked token release schedules for team tokens and investor allocations
- Supports both native ETH and ERC20 token vesting
- Configurable start times and vesting durations

## 🏗️ Architecture

The Factory uses a **Clone Factory Pattern** for gas-efficient deployments:

1. **Implementation Contracts**: Immutable logic contracts deployed once
2. **Factory Contracts**: Create minimal proxy clones of implementations
3. **Initialization**: Each clone is initialized with custom parameters
4. **Fee System**: Configurable creation fees collected by treasury

## 🛡️ Security Features

- **OpenZeppelin Contracts**: Built on battle-tested, audited libraries
- **Reentrancy Protection**: All state-changing functions protected
- **Access Control**: Role-based permissions with ownership patterns
- **Pausable Factories**: Emergency pause functionality
- **Input Validation**: Comprehensive parameter validation and error handling

## 📊 Gas Efficiency

The Factory uses several gas optimization techniques:

- **Minimal Proxy Pattern**: ~2,000 gas per deployment vs. full contract deployment
- **Packed Structs**: Optimized storage layouts
- **Batch Operations**: Multi-token operations in single transaction
- **Event Optimization**: Efficient event emission patterns

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Make changes with tests
4. Submit a pull request

## 📄 License

This project is licensed under the Business Source License 1.1 - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Website**: [https://www.sonicfactory.dev/]
- **Documentation**: [https://sonicfactory.gitbook.io/docs/]
- **Telegram**: [https://t.me/FactorySonic]
- **Discord**: [https://discord.gg/KSv7z4gDDN]
- **Twitter**: [https://x.com/FactorySonic]

---

Built with ❤️ by the Sonic Factory team
