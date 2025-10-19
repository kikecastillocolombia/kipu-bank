// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title KipuBank
 * @dev Contrato bancario simple que permite a los usuarios depositar y retirar
 * fondos nativos (ETH) con límites de seguridad.
 * Sigue el patrón Checks-Effects-Interactions y usa errores personalizados.
 */
contract KipuBank {
    // =========================================================================
    //                            I. Custom Errors
    // =========================================================================

    /**
     * @dev Emitido cuando un depósito excede el límite total del banco.
     * @param requestedAmount Cantidad que el usuario intentó depositar.
     * @param cap Límite máximo de depósito del banco (bankCap).
     */
    error DepositExceedsCap(uint256 requestedAmount, uint256 cap);

    /**
     * @dev Emitido cuando el saldo de un usuario es insuficiente para un retiro.
     * @param availableBalance Saldo actual del usuario en la bóveda.
     * @param requestedAmount Cantidad que el usuario intentó retirar.
     */
    error InsufficientBalance(uint256 availableBalance, uint256 requestedAmount);

    /**
     * @dev Emitido cuando un retiro excede el umbral máximo por transacción.
     * @param requestedAmount Cantidad que el usuario intentó retirar.
     * @param threshold Límite máximo de retiro por transacción (maxWithdrawal).
     */
    error WithdrawalExceedsThreshold(uint256 requestedAmount, uint256 threshold);

    /**
     * @dev Emitido cuando la función solo puede ser ejecutada por el dueño del contrato.
     */
    error NotOwner();

    // =========================================================================
    //                              II. Events
    // =========================================================================

    /**
     * @dev Emitido cuando se realiza un depósito exitoso.
     * @param indexedUser Dirección del depositante.
     * @param amount Cantidad de ETH depositada.
     * @param newBalance Nuevo saldo del usuario.
     */
    event Deposit(address indexedUser, uint256 amount, uint256 newBalance);

    /**
     * @dev Emitido cuando se realiza un retiro exitoso.
     * @param indexedUser Dirección del que retira.
     * @param amount Cantidad de ETH retirada.
     * @param newBalance Nuevo saldo del usuario.
     */
    event Withdrawal(address indexedUser, uint256 amount, uint256 newBalance);

    // =========================================================================
    //                              III. State Variables
    // =========================================================================

    // Variables Immutable || Constant

    /**
     * @dev Dirección del dueño del contrato (definido en el despliegue).
     * @notice Solo el dueño puede realizar acciones administrativas (si las hubiere).
     */
    address private immutable i_owner;

    /**
     * @dev Límite máximo de ETH que se puede retirar en una sola transacción.
     * @notice Una medida de seguridad para limitar la exposición en caso de vulnerabilidad.
     */
    uint256 private immutable i_maxWithdrawalThreshold;

    /**
     * @dev Límite global de ETH que puede contener el banco.
     * @notice Una medida de seguridad para limitar la exposición total del protocolo.
     */
    uint256 private immutable i_bankCap;


    // Variables de almacenamiento (Storage Variables)

    /**
     * @dev Mapeo para almacenar el saldo (bóveda) de cada usuario.
     * @notice `address => uint256` mapea la dirección del usuario a su saldo en Wei.
     */
    mapping(address => uint256) public balances;

    /**
     * @dev Contador para el número total de depósitos exitosos.
     */
    uint256 public totalDeposits;

    /**
     * @dev Contador para el número total de retiros exitosos.
     */
    uint256 public totalWithdrawals;

    // =========================================================================
    //                              IV. Modifiers
    // =========================================================================

    /**
     * @dev Restringe el acceso a la función solo al dueño del contrato.
     */
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    // =========================================================================
    //                              V. Constructor
    // =========================================================================

    /**
     * @dev Establece las variables inmutables en el despliegue.
     * @param bankCap_ Límite total de depósitos que el banco puede contener.
     * @param maxWithdrawalThreshold_ Límite de retiro por transacción para los usuarios.
     */
    constructor(uint256 bankCap_, uint256 maxWithdrawalThreshold_) {
        i_owner = msg.sender;
        i_bankCap = bankCap_;
        i_maxWithdrawalThreshold = maxWithdrawalThreshold_;
    }

    // =========================================================================
    //                              VI. Functions
    // =========================================================================

    /**
     * @dev Permite a los usuarios depositar ETH en su bóveda personal.
     * @custom:security Sigue el patrón Checks-Effects-Interactions y verifica bankCap.
     */
    function deposit() external payable {
        // 1. Checks (Verificaciones)
        if (address(this).balance > i_bankCap) {
            revert DepositExceedsCap(msg.value, i_bankCap);
        }

        // 2. Effects (Efectos - Modificación del estado)
        balances[msg.sender] += msg.value;
        totalDeposits++;

        // 3. Interactions (Interacciones - Eventos)
        emit Deposit(msg.sender, msg.value, balances[msg.sender]);
    }

    /**
     * @dev Permite a los usuarios retirar ETH de su bóveda, limitado por un umbral.
     * @param amount Cantidad de ETH a retirar.
     * @custom:security Sigue el patrón Checks-Effects-Interactions y usa address.call.
     */
    function withdraw(uint256 amount) external {
        // 1. Checks (Verificaciones)
        if (amount > i_maxWithdrawalThreshold) {
            revert WithdrawalExceedsThreshold(amount, i_maxWithdrawalThreshold);
        }
        if (balances[msg.sender] < amount) {
            revert InsufficientBalance(balances[msg.sender], amount);
        }

        // 2. Effects (Efectos - Modificación del estado)
        // Reducir el saldo ANTES de la transferencia (Checks-Effects-Interactions)
        balances[msg.sender] -= amount;
        totalWithdrawals++;
        
        // 3. Interactions (Interacciones)
        // Uso seguro de call para manejar transferencias nativas
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Withdrawal failed"); // Fallback a require por la interacción

        // Emitir Evento
        emit Withdrawal(msg.sender, amount, balances[msg.sender]);
    }

    /**
     * @dev Función privada que contiene lógica interna (ej. para un futuro sistema de auditoría).
     * @notice En este ejemplo, solo verifica si el número de depósitos es par.
     */
    function _checkDepositParity() private view returns (bool) {
        // Lógica de auditoría simple (ejemplo)
        return totalDeposits % 2 == 0;
    }

    /**
     * @dev Función de vista externa para obtener el saldo de un usuario.
     * @param user Dirección del usuario.
     * @return El saldo del usuario en Wei.
     */
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    /**
     * @dev Función de vista externa para obtener la información de límites del contrato.
     * @return _bankCap Límite global de depósitos.
     * @return _maxWithdrawalThreshold Límite de retiro por transacción.
     */
    function getLimits() external view returns (uint256 _bankCap, uint256 _maxWithdrawalThreshold) {
        return (i_bankCap, i_maxWithdrawalThreshold);
    }
}