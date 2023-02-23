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

    /// @dev Issue the token.
    function issue(
        address _to,
        uint256 _amount,
        uint256 _nonce,
        uint256 _expiry,
        bytes calldata _signature
    ) external;

    /// @dev Redeem the token.
    function redeem(uint256 amount) external;

    /// @dev Burn the token.
    function burn(uint256 amount) external;
}
