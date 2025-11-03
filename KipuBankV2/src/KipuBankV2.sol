```markdown
# KipuBankV2

> Versión mejorada del contrato KipuBank: control de acceso, Chainlink oracle, mappings anidados, constantes e utilidades de conversión.

---

## ✅ Resumen a alto nivel

`KipuBankV2` es una evolución del contrato `KipuBank` pensada para producción temprana / entornos de testing avanzado. Las mejoras clave:

- **Control de Acceso:** `AccessControl` de OpenZeppelin para roles (ADMIN, BANK_ADMIN), separación de permisos.
- **Declaraciones de Tipos:** `enum` + `struct` para mejorar claridad y tipado (p. ej. `AssetType`, `Stats`).
- **Instancia Chainlink:** `AggregatorV3Interface` para obtener precio ETH/USD y convertir valores.
- **Variables `constant` y `immutable`:** reducción de gas y mejores garantías inmutables (bankCap, thresholds).
- **Mappings anidados:** `mapping(address => mapping(address => uint256)) balances` soporta multi-asset (address(0) = ETH).
- **Funciones de conversión:** `convertEthToUsd`, `convertUsdToEth` para trabajar con precios del oráculo.
- **Patrón Checks-Effects-Interactions:** usado en deposit/withdraw y seguridad general.
- **Eventos y errores personalizados:** para trazabilidad y gas optimizado.

### Por qué estas mejoras
- **Seguridad:** roles permiten operaciones administrativas solo por cuentas autorizadas. Checks-Effects-Interactions y errores personalizados reducen vectores de ataque.
- **Comodidad:** conversiones con Oráculo permiten exponer valor en USD, útil para UX o límites basados en fiat.
- **Escalabilidad:** mappings anidados permiten añadir tokens ERC20 en el futuro sin rehacer estado.

---

## Estructura del repositorio (sugerida)

```

KipuBankV2/
├─ src/
│  └─ KipuBankV2.sol
├─ README.md
└─ LICENSE

````

---

## Archivo principal

`src/KipuBankV2.sol` — contiene el contrato explicado arriba. Usa:
- `pragma solidity ^0.8.20`
- `OpenZeppelin AccessControl` (import)
- `Chainlink AggregatorV3Interface` (import)

> **Nota:** Para verificar en Etherscan usa el archivo **flattened** (Remix -> Flatten) ya que el verificador no resuelve imports remotos directamente.

---

## Despliegue en Sepolia (Remix + MetaMask) — paso a paso (principiante)

### Requisitos
- MetaMask con Sepolia activa
- ETH de prueba en Sepolia (faucet)
- Remix: https://remix.ethereum.org

### 1) Abrir Remix y crear archivo
- En el File Explorer de Remix crea `src/KipuBankV2.sol` y pega el contenido del contrato.

### 2) Compilar
- Abrir la pestaña **Solidity Compiler**.
- Seleccionar versión **0.8.20** (o la que figure en el pragma).
- Activar **Enable optimization** (Runs = 200).
- Compilar.

### 3) Conectar MetaMask
- En **Deploy & Run Transactions** elegir **Injected Provider - MetaMask**.
- Confirmar que MetaMask está en **Sepolia**.

### 4) Desplegar
- En los parámetros del constructor, usa (ejemplo):
  - `bankCapWei`: `10000000000000000000` (10 ETH)
  - `maxWithdrawalThresholdWei`: `1000000000000000000` (1 ETH)
- Haz click en **Deploy** y confirma en MetaMask.
- Copia la dirección del contrato desplegado.

### 5) Verificar en Etherscan (Sepolia)
- En Remix: Archivo -> `Flatten` para obtener un solo archivo que contenga todas las dependencias.
- Ve a `https://sepolia.etherscan.io/verifyContract`.
- Elige:
  - Compiler type: `Solidity (Single file)`
  - Compiler version: `v0.8.20+commit...` (la misma que usaste)
  - Optimization: `Yes` (200 runs)
- Pega el código flatten y completa la verificación.

> Si Etherscan devuelve error `Source not found` o `ParserError`, asegúrate de usar **flatten** y copiar exactamente el contenido flattened.

---

## Interacción básica (Remix)

- `deposit()` — enviar ETH con el **Value** en Remix y llamar a la función (guarda ETH en `balances[msg.sender][address(0)]`).
- `withdraw(uint256 amountWei)` — retirar hasta `maxWithdrawalThresholdWei`.
- `getBalance(address user, address asset)` — consultar balance (address(0) para native).
- `convertEthToUsd(uint256 ethAmountWei)` — obtener USD (8 decimales) para el monto.
- `getLatestEthUsdPrice()` — devuelve precio de Chainlink (8 decimales usualmente).

---

## Notas de diseño / Trade-offs

- **Oracle dependencia:** usar Chainlink mejora exactitud de precios pero añade dependencia externa (si la feed falla/stop de oráculo, las funciones que dependen de precio revertirán).
- **Bank cap (global):** límite útil en testnet/mainnet para minimizar exposición, pero impone un techo que puede necesitar ser actualizado por diseño (no hay función para mutarlo; si la quieres añadir, hazlo con `onlyAdmin` y eventos).
- **Admin withdrawal:** se incluyó una función `adminWithdraw` para emergencias. Esto es una BACKDOOR potencial — debe usarse con cuidado y documentarse claramente en governance.
- **ERC20 soporte futuro:** mappings anidados están listos para ERC20, pero no se incluyen funciones ERC20 (permit/transferFrom) en esta versión; añadir soporte requiere SafeERC20 y validaciones.

---

## Verificación / Transparencia
> Añade aquí la **dirección del contrato desplegado** y el enlace a Etherscan después de desplegar y verificar:

- **Dirección del contrato (Sepolia):** `PASTE_CONTRACT_ADDRESS_HERE`
- **Etherscan (verify) URL:** `https://sepolia.etherscan.io/address/PASTE_CONTRACT_ADDRESS_HERE#code`

---

## Cómo publicar en GitHub (rápido)

```bash
git init
git add .
git commit -m "KipuBankV2: initial smart contract & README"
gh repo create KipuBankV2 --public --source=. --remote=origin --push
````

(O usa la UI de GitHub para crear el repo y empuja tu código).

---

## Licencia

MIT

---

## Soporte

Si quieres que **yo** genere el archivo *flattened* listo para pegar en Etherscan (basado en el código que te entregué) o que adapte el contrato para añadir funciones ERC20, admin-upgradeable cap, o integración con Hardhat/Foundry, dime y te lo preparo.

```
```
