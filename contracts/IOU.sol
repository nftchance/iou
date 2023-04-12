// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.16;

/// @dev Factory dependencies.
import {IOUFactory} from "./IOUFactory.sol";

/// @dev Core dependencies.
import {IIOU} from "./interfaces/IIOU.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/// @dev Libraries.
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @dev Single instance implementation of IOU supporting transaction
 *      with assets to be distributed on another chain.
 */
contract IOU is IIOU, ERC20Upgradeable {
    using ECDSA for bytes32;

    ////////////////////////////////////////////////////////
    ///                      STATE                       ///
    ////////////////////////////////////////////////////////

    /// @dev The managing factory that deployed this IOU.
    IOUFactory public factory;

    /// @dev The receipt that was used to deploy this IOU.
    string public destinationChain;

    /// @dev The receipt that was used to deploy this IOU.
    string public destinationAddress;

    /// @dev The amount of decimals the destination token uses.
    uint256 public destinationDecimals;

    /// @dev The nonces used when minting.
    mapping(address => uint256) public nonces;

    ////////////////////////////////////////////////////////
    ///                   CONSTRUCTOR                    ///
    ////////////////////////////////////////////////////////

    constructor() {
        _disableInitializers();
    }

    function initialize(
        IOUFactory.Receipt calldata _receipt
    ) external initializer {
        /// @dev Save the reference to the factory.
        factory = IOUFactory(msg.sender);

        /// @dev Initialize the ERC20.
        __ERC20_init(_receipt.name, _receipt.symbol);

        /// @dev Update the destination.
        destinationChain = _receipt.destinationChain;
        destinationAddress = _receipt.destinationAddress;
        destinationDecimals = _receipt.destinationDecimals;

        /// @dev Emit the event.
        emit DestinationUpdated(
            destinationChain,
            destinationAddress,
            destinationDecimals
        );
    }

    ////////////////////////////////////////////////////////
    ///                     MODIFIERS                     ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Modifier to confirm the user has the badge.
     */
    modifier onlyBadgeHolder() {
        /// @dev Retrieve the active Badge configuration.
        (IERC1155 token, uint256 id, uint256 amount) = factory.badge();

        /// @dev Confirm the user has the badge.
        require(
            token.balanceOf(msg.sender, id) >= amount,
            "IOU: Missing Badge that grants access to mint."
        );

        _;
    }

    ////////////////////////////////////////////////////////
    ///                     SETTERS                      ///
    ////////////////////////////////////////////////////////

    /**
     * See {IIOU-issue}.
     */
    function issue(
        address _to,
        uint256 _amount,
        uint256 _nonce,
        uint256 _expiry,
        bytes calldata _signature
    ) external onlyBadgeHolder {
        /// @dev Confirm the user has not already used the nonce.
        require(nonces[_to] == _nonce, "IOU: Invalid nonce.");

        /// @dev Confirm the signature has not expired.
        require(block.timestamp <= _expiry, "IOU: Signature expired.");

        /// @dev Build the message that would have been signed.
        bytes32 message = keccak256(
            abi.encodePacked(address(this), _to, _amount, _nonce, _expiry)
        );

        /// @dev Confirm the user has a valid signature to mint the requested
        ///      amount to the requested address.
        require(
            message.toEthSignedMessageHash().recover(_signature) ==
                factory.signer(),
            "IOU: Invalid signature."
        );

        unchecked {
            /// @dev Increment the nonce.
            nonces[_to]++;
        }

        /// @dev Mint the tokens.
        _mint(_to, _amount);
    }

    /**
     * See {IIOU-redeem}.
     */
    function redeem(
        address _marketplaceAddress,
        uint256 _participationId,
        string memory _participationType,
        uint256 _amount,
        bytes calldata _signature
    ) external {
        /// @dev Build the message that would have been signed.
        bytes32 message = keccak256(
            abi.encodePacked(
                address(this),
                _marketplaceAddress,
                tx.origin,
                _participationId,
                _participationType,
                _amount
            )
        );

        /// @dev Confirm the user has a valid signature to mint the requested
        ///      amount to the requested address.
        require(
            message.toEthSignedMessageHash().recover(_signature) ==
                factory.signer(),
            "IOU: Invalid signature."
        );

        /// @dev Transfer the token to the IOU vault.
        _transfer(msg.sender, factory.vault(), _amount);
    }

    /**
     * See {IIOU-burn}.
     */
    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }

    ////////////////////////////////////////////////////////
    ///                     GETTERS                      ///
    ////////////////////////////////////////////////////////

    /**
     * See {ERC20-decimals}.
     */
    function decimals() public view virtual override returns (uint8) {
        return uint8(destinationDecimals);
    }
}
