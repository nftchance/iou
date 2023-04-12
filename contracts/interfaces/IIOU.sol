// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.16;

/// @dev Factory dependencies.
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

interface IIOU {
    ////////////////////////////////////////////////////////
    ///                      SCHEMA                      ///
    ////////////////////////////////////////////////////////

    /// @dev The schema of a badge that grants access to users.
    struct Badge {
        ERC1155 token;
        uint256 id;
        uint256 amount;
    }

    ////////////////////////////////////////////////////////
    ///                     EVENTS                       ///
    ////////////////////////////////////////////////////////

    /// @dev Emitted when the signer is updated.
    event DestinationUpdated(
        string indexed destinationChain,
        string indexed destinationAddress,
        uint256 destinationDecimals
    );

    ////////////////////////////////////////////////////////
    ///                     SETTER                       ///
    ////////////////////////////////////////////////////////

    /**
     * @dev Mint the specified amount of tokens to the specified address.
     * @param _to The address to mint the tokens to.
     * @param _amount The amount of tokens to mint.
     * @param _nonce The nonce used to mint the tokens.
     * @param _expiry The expiry of the signature.
     * @param _signature The signature used to mint the tokens.
     */
    function issue(
        address _to,
        uint256 _amount,
        uint256 _nonce,
        uint256 _expiry,
        bytes calldata _signature
    ) external;

    /**
     * @dev Redeem the specified amount of tokens.
     * @param _marketplaceAddress The address of the marketplace.
     * @param _participationId The ID of the participation.
     * @param _participationType The type of the participation.
     * @param _amount The amount of tokens to redeem.
     * @param _signature The signature used to redeem the tokens.
     */
    function redeem(
        address _marketplaceAddress,
        uint256 _participationId,
        string memory _participationType,
        uint256 _amount,
        bytes calldata _signature
    ) external;

    /**
     * @dev Burn the specified amount of tokens.
     * @param _amount The amount of tokens to burn.
     */
    function burn(uint256 _amount) external;
}
