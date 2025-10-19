  # KipuBank Smart Contract

## 📜 Descripción del Contrato

**KipuBank** es un contrato inteligente de bóveda bancaria simple y segura, diseñado para manejar depósitos y retiros de tokens nativos (ETH) en la red Ethereum Virtual Machine (EVM).

Este proyecto cumple con altos estándares de desarrollo, incorporando patrones de seguridad como **Checks-Effects-Interactions**, el uso de **Custom Errors**, y una documentación completa con comentarios **NatSpec**.

### Características Principales:
- **Depósitos Seguros:** Los usuarios pueden depositar ETH en una bóveda personal (`balances`).
- **Límite Global (`bankCap`):** Se impone un límite máximo en el total de ETH que el contrato puede contener, definido en el despliegue.
- **Límite por Transacción:** Los retiros están limitados por un umbral (`maxWithdrawalThreshold`) por transacción (variable `immutable`).
- **Seguimiento:** El contrato registra el total de depósitos y retiros.
- **Transparencia:** Emisión de eventos para cada operación exitosa.

## 🛠️ Instrucciones de Despliegue

### Requisitos
- Node.js y npm
- Herramienta de desarrollo como Hardhat o Foundry (o Remix IDE para un despliegue rápido).
- ETH en una **Testnet** (ej. Sepolia, Holesky) para pagar el gas.

### Usando Remix IDE (Recomendado para la tarea)
1. **Compilación:**
   - Navega a la pestaña de "Solidity Compiler" y selecciona la versión del compilador (`0.8.20+`).
   - Compila `KipuBank.sol`.

2. **Despliegue:**
   - Navega a la pestaña de "Deploy & Run Transactions".
   - Selecciona el entorno `Injected Provider - Metamask` y conéctate a tu testnet.
   - En el campo `DEPLOY` del contrato `KipuBank`, introduce los valores requeridos para el constructor:
     - `bankCap_`: Por ejemplo, `10000000000000000000` (10 ETH en Wei).
     - `maxWithdrawalThreshold_`: Por ejemplo, `1000000000000000000` (1 ETH en Wei).
   - Haz clic en **Deploy** y confirma la transacción en Metamask.

## 🔗 Dirección del Contrato Desplegado

https://sepolia.etherscan.io/address/0x8AB7AC9d041C7Ad4f5eEc955686EA26027A5430e


## 🤝 Cómo Interactuar con el Contrato

| Función | Tipo | Descripción | Ejemplo de Interacción |
| :--- | :--- | :--- | :--- |
| `deposit()` | `external payable` | Envía ETH al contrato. **Debe** adjuntar ETH en el valor de la transacción. | Envía 0.5 ETH a la función `deposit`. |
| `withdraw(uint256 amount)` | `external` | Retira `amount` de ETH de la bóveda. `amount` debe ser $\le$ `maxWithdrawalThreshold`. | Llama con un valor de `500000000000000000` (0.5 ETH en Wei). |
| `getBalance(address user)` | `external view` | Consulta el saldo de la bóveda de una dirección específica. | Llama con tu dirección para ver tu saldo. |
| `getLimits()` | `external view` | Obtiene los límites de `bankCap` y `maxWithdrawalThreshold`. | Llama para verificar los límites establecidos. |
| `totalDeposits` | `public view` | Consulta el número total de depósitos. | Llama directamente a la variable pública. |
