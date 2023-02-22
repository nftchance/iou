// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.16;

/// @dev Factory dependencies.
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {IOU} from "../IOU.sol";

interface IIOUFactory {
    ////////////////////////////////////////////////////////
    ///                      SCHEMA                      ///
    ////////////////////////////////////////////////////////

    /// @dev The schema of a badge that grants access to users.
    struct Badge {
        IERC1155 token;
        uint256 id;
        uint256 amount;
    }

    /// @dev The schema of declaration of an IOU.
    struct Receipt {
        string name;
        string symbol;
        string destinationChain;
        string destinationAddress;
    }

    ////////////////////////////////////////////////////////
    ///                     EVENTS                       ///
    ////////////////////////////////////////////////////////

    /// @dev Emitted when the signer is updated.
    event SignerUpdated(address indexed signer);

    /// @dev Emitted when the vault is updated.
    event VaultUpdated(address indexed vault);

    /// @dev Emitted when the badge is updated.
    event BadgeUpdated(Badge indexed badge);

    /// @dev Emitted when a new IOU is created.
    event IOUCreated(
        IOU indexed iou,
        address indexed deployer,
        uint256 indexed iouId
    );

    ////////////////////////////////////////////////////////
    ///                     SETTER                       ///
    ////////////////////////////////////////////////////////

    /// @dev Update the signer.
    function setSigner(address signer) external;

    /// @dev Update the vault.
    function setVault(address vault) external;

    /// @dev Update the badge.
    function setBadge(Badge calldata badge) external;

    ////////////////////////////////////////////////////////
    ///                     GETTER                       ///
    ////////////////////////////////////////////////////////

    /// @dev Get the contract deployed given an IOU Id.
    function getIOU(uint256 iouId) external view returns (IOU);

    /// @dev Get the name of the IOU.
    function name() external view returns (string memory);

    /// @dev Get the symbol of the IOU.
    function symbol() external view returns (string memory);
}
